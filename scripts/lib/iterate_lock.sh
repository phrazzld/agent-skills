#!/usr/bin/env bash
# Single-instance lock for /iterate.
# Lock file: .spellbook/iterate.lock
# Content:   {"pid": <int>, "cycle_id": "<ulid>", "started_at": "<iso8601 UTC>"}
#
# Two /iterate processes in the same repo would race on daybook + bucket
# updates. We keep a filesystem lock (not a git ref) because it's machine-
# local state, and we steal stale locks when the owning pid is dead so a
# SIGKILL'd cycle doesn't wedge the repo forever.
#
# Usage:
#   source scripts/lib/iterate_lock.sh
#   iterate_acquire <cycle_id>   # 0 on success, 1 if another live cycle holds it
#   iterate_release <cycle_id>   # 0 on success (idempotent); 1 if cycle_id mismatch

ITERATE_LOCK_PATH="${ITERATE_LOCK_PATH:-.spellbook/iterate.lock}"

# Acquire the iterate lock. Steals lock when owner pid is dead or content
# is corrupt. Fails when owner pid is alive.
# Args: <cycle_id>
iterate_acquire() {
  local cycle_id="$1"
  if [ -z "$cycle_id" ]; then
    echo "iterate_acquire: cycle_id required" >&2
    return 1
  fi

  mkdir -p "$(dirname "$ITERATE_LOCK_PATH")"

  if [ -e "$ITERATE_LOCK_PATH" ]; then
    # Inspect existing lock. If pid is alive, refuse; otherwise treat as stale.
    local existing_pid
    existing_pid="$(python3 -c "
import json, sys
try:
    data = json.load(open('$ITERATE_LOCK_PATH'))
    print(data.get('pid', ''))
except Exception:
    print('')
" 2>/dev/null)"
    if [ -n "$existing_pid" ] && [ "$existing_pid" != "0" ] && kill -0 "$existing_pid" 2>/dev/null; then
      echo "iterate_acquire: lock held by live pid $existing_pid" >&2
      return 1
    fi
    # Stale or corrupt — fall through and overwrite.
  fi

  ITERATE_LOCK_CYCLE_ID="$cycle_id" \
  ITERATE_LOCK_PID="$$" \
  ITERATE_LOCK_FILE="$ITERATE_LOCK_PATH" \
  python3 <<'PYEOF'
import json, os, tempfile, time

path = os.environ["ITERATE_LOCK_FILE"]
payload = {
    "pid": int(os.environ["ITERATE_LOCK_PID"]),
    "cycle_id": os.environ["ITERATE_LOCK_CYCLE_ID"],
    "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}
# Atomic write via temp + rename so a SIGKILL mid-write can't leave a
# truncated lock that we'd then treat as stale and steal from a live owner.
d = os.path.dirname(path) or "."
fd, tmp = tempfile.mkstemp(dir=d, prefix=".iterate.lock.")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(payload, f)
        f.flush()
        os.fsync(f.fileno())
    os.rename(tmp, path)
except Exception:
    try: os.unlink(tmp)
    except OSError: pass
    raise
PYEOF
}

# Release the iterate lock. Only if the recorded cycle_id matches the caller —
# prevents a late trap from wiping a subsequent cycle's lock.
# Idempotent: missing lock returns 0 (trap-safe cleanup).
# Args: <cycle_id>
iterate_release() {
  local cycle_id="$1"
  if [ -z "$cycle_id" ]; then
    echo "iterate_release: cycle_id required" >&2
    return 1
  fi
  if [ ! -e "$ITERATE_LOCK_PATH" ]; then
    return 0
  fi
  local recorded
  recorded="$(python3 -c "
import json
try:
    print(json.load(open('$ITERATE_LOCK_PATH')).get('cycle_id',''))
except Exception:
    print('')
" 2>/dev/null)"
  if [ "$recorded" != "$cycle_id" ]; then
    echo "iterate_release: cycle_id mismatch (lock=$recorded, asked=$cycle_id)" >&2
    return 1
  fi
  rm -f "$ITERATE_LOCK_PATH"
}
