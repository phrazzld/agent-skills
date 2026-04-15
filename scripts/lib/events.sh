#!/usr/bin/env bash
# Typed event log for /iterate cycles.
# Each cycle owns a cycle.jsonl file; every phase boundary writes one event.
# JSONL corruption breaks /reflect, so writes are locked and fsync'd.
#
# Usage:
#   source scripts/lib/events.sh
#   emit_event <log_path> <kind> <phase> <agent> <payload_json>
#
# cycle_id is derived from the parent directory name of <log_path>
# (convention: backlog.d/_cycles/<ulid>/cycle.jsonl).

# Closed enum of known event kinds. Writes with unknown kinds MUST fail —
# consumers (reflect, bucket-scorer, harness-tuner) key on `kind`, and
# silent drift produces ghost analytics.
EVENT_KINDS=(
  cycle.opened
  shape.done
  build.done
  review.iter
  ci.done
  qa.done
  deploy.done
  reflect.done
  harness.suggested
  phase.failed
  budget.exhausted
  cycle.closed
)

# Append one typed event to <log_path>. Atomic (fcntl.flock) and fsync'd.
# Args: <log_path> <kind> <phase> <agent> <payload_json>
# Returns: 0 on success, 1 on validation failure or write failure.
emit_event() {
  local log_path="$1" kind="$2" phase="$3" agent="$4" payload="${5:-{\}}"

  if [ -z "$log_path" ]; then
    echo "emit_event: log_path required" >&2
    return 1
  fi
  if [ -z "$kind" ]; then
    echo "emit_event: kind required" >&2
    return 1
  fi
  if [ -z "$phase" ]; then
    echo "emit_event: phase required" >&2
    return 1
  fi

  # Validate kind against closed enum before spawning python.
  local known=0 k
  for k in "${EVENT_KINDS[@]}"; do
    [ "$k" = "$kind" ] && known=1 && break
  done
  if [ "$known" -ne 1 ]; then
    echo "emit_event: unknown kind '$kind'" >&2
    return 1
  fi

  # cycle_id comes from parent directory name by convention — keeps the
  # event log self-describing even when paths move.
  local cycle_dir cycle_id
  cycle_dir="$(dirname "$log_path")"
  cycle_id="$(basename "$cycle_dir")"

  EVENT_LOG="$log_path" \
  EVENT_KIND="$kind" \
  EVENT_PHASE="$phase" \
  EVENT_AGENT="$agent" \
  EVENT_CYCLE_ID="$cycle_id" \
  EVENT_PAYLOAD="$payload" \
  python3 <<'PYEOF'
import fcntl, json, os, sys, time

log_path = os.environ["EVENT_LOG"]
payload_raw = os.environ.get("EVENT_PAYLOAD", "{}") or "{}"

try:
    payload = json.loads(payload_raw)
except Exception as e:
    print(f"emit_event: invalid payload JSON: {e}", file=sys.stderr)
    sys.exit(1)
if not isinstance(payload, dict):
    print("emit_event: payload must be a JSON object", file=sys.stderr)
    sys.exit(1)

event = {
    "schema_version": 1,
    "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "cycle_id": os.environ["EVENT_CYCLE_ID"],
    "kind":  os.environ["EVENT_KIND"],
    "phase": os.environ["EVENT_PHASE"],
    "agent": os.environ["EVENT_AGENT"],
}
# Merge payload fields but do not let payload override core envelope.
for k, v in payload.items():
    if k in event:
        continue
    event[k] = v

line = json.dumps(event, separators=(",", ":"), sort_keys=False) + "\n"

# Ensure parent dir exists — caller owns the cycle dir, but be defensive.
os.makedirs(os.path.dirname(log_path) or ".", exist_ok=True)

# Open O_APPEND so writes are atomic at the kernel level for small lines;
# still take an exclusive flock to serialize with sibling writers across
# processes (multiple /iterate instances would be a bug, but tests simulate
# concurrent shells).
fd = os.open(log_path, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
try:
    fcntl.flock(fd, fcntl.LOCK_EX)
    os.write(fd, line.encode("utf-8"))
    os.fsync(fd)
finally:
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
    finally:
        os.close(fd)
PYEOF
}
