#!/usr/bin/env bash
# /flywheel Phase 2a entrypoint.
#
# Subcommands (all return via exit code + stdout JSON, never prose):
#   new-cycle [--budget $X] [--unattended]
#   pick <cycle_id>
#   emit <cycle_id> <kind> <phase> <agent> <payload_json>
#   close <cycle_id> <status> [<reason>]
#   update-bucket <cycle_id> <ship_status>
#   update-harness <cycle_id>
#   budget <cycle_id>
#   status [<cycle_id>]
#   run [--dry-run] [--max-cycles N] [--budget $X] [--unattended]
#
# Phase 2b stubs (exit 2 "Phase 2b"):
#   run --resume <ulid>, run --abandon <ulid>, run --until <pred>
set -euo pipefail

# Resolve this script's real location through symlinks — libs live beside it.
if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
else
    # macOS without coreutils: walk the symlink chain manually.
    SCRIPT_PATH="${BASH_SOURCE[0]}"
    while [ -L "$SCRIPT_PATH" ]; do
        SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
        case "$SCRIPT_PATH" in /*) ;; *) SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$SCRIPT_PATH")" && pwd)/$(basename "$SCRIPT_PATH")" ;; esac
    done
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# State root: the project the user is running /flywheel against, not the skill's install dir.
if STATE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    :
else
    STATE_ROOT="$PWD"
fi

cd "$STATE_ROOT"

# shellcheck source=lib/events.sh
source "$SCRIPT_DIR/lib/events.sh"
# shellcheck source=lib/flywheel_lock.sh
source "$SCRIPT_DIR/lib/flywheel_lock.sh"

# ULID generation. Prefer python-ulid if present; otherwise emit a real
# Crockford-base32 ULID (10 chars timestamp + 16 chars randomness = 26 chars),
# lexicographically sortable and interchangeable with the library output.
new_ulid() {
  python3 - <<'PYEOF'
try:
    import ulid
    print(str(ulid.new()))
except Exception:
    import secrets, time
    CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    def _enc(v, n):
        out = []
        for _ in range(n):
            out.append(CROCKFORD[v & 0x1F]); v >>= 5
        return "".join(reversed(out))
    ts = int(time.time() * 1000) & ((1 << 48) - 1)
    rnd = secrets.randbits(80)
    print(_enc(ts, 10) + _enc(rnd, 16))
PYEOF
}

# Atomic manifest write: write to temp then rename (fsync before rename).
# Args: <manifest_path> <json_content>
write_manifest() {
  local path="$1" content="$2"
  local tmp="${path}.tmp.$$"
  python3 -c "
import os, sys
path = sys.argv[1]
content = sys.argv[2]
tmp = path + '.tmp.' + str(os.getpid())
with open(tmp, 'w') as f:
    f.write(content)
    f.flush()
    os.fsync(f.fileno())
os.rename(tmp, path)
" "$path" "$content"
}

# Read manifest field. Args: <manifest_path> <field>
read_manifest_field() {
  python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
# support nested: budget.cap_usd
parts = sys.argv[2].split('.')
v = d
for p in parts:
    v = v[p]
print(json.dumps(v) if not isinstance(v, str) else v)
" "$1" "$2" 2>/dev/null || true
}

# Emit wrapper: validates kind, sums cost_usd, triggers budget.exhausted.
# Returns manifest path so callers can reread budget state.
# Args: <cycle_id> <kind> <phase> <agent> <payload_json>
cmd_emit() {
  local cycle_id="$1" kind="$2" phase="$3" agent="$4" payload="${5:-{\}}"
  local cycle_dir="backlog.d/_cycles/$cycle_id"
  local log="$cycle_dir/cycle.jsonl"
  local manifest="$cycle_dir/manifest.json"

  if [ ! -f "$manifest" ]; then
    echo "flywheel emit: no manifest for cycle $cycle_id" >&2
    return 1
  fi

  # Delegate to events.sh (validates kind against closed enum).
  emit_event "$log" "$kind" "$phase" "$agent" "$payload"

  # If payload contains cost_usd, update manifest budget.
  local cost
  cost="$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('cost_usd',0))" "$payload" 2>/dev/null || echo 0)"
  if python3 -c "import sys; sys.exit(0 if float(sys.argv[1])>0 else 1)" "$cost" 2>/dev/null; then
    # Atomically update manifest spent_usd and spent_by_phase.
    local updated_manifest
    updated_manifest="$(python3 -c "
import json, sys
manifest_path, phase_name, cost_str = sys.argv[1], sys.argv[2], sys.argv[3]
cost = float(cost_str)
d = json.load(open(manifest_path))
d['budget']['spent_usd'] = round(d['budget']['spent_usd'] + cost, 6)
d['budget']['spent_by_phase'][phase_name] = round(
    d['budget']['spent_by_phase'].get(phase_name, 0.0) + cost, 6)
print(json.dumps(d, indent=2))
" "$manifest" "$phase" "$cost")"
    write_manifest "$manifest" "$updated_manifest"

    # Check 95% budget threshold.
    local spent cap
    spent="$(read_manifest_field "$manifest" "budget.spent_usd")"
    cap="$(read_manifest_field "$manifest" "budget.cap_usd")"
    local exhausted
    exhausted="$(python3 -c "
import sys
spent, cap = float(sys.argv[1]), float(sys.argv[2])
print('yes' if cap > 0 and spent >= cap * 0.95 else 'no')
" "$spent" "$cap")"
    if [ "$exhausted" = "yes" ]; then
      local tally
      tally="$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(json.dumps({'spent_usd': d['budget']['spent_usd'], 'cap_usd': d['budget']['cap_usd'], 'spent_by_phase': d['budget']['spent_by_phase']}))
" "$manifest")"
      emit_event "$log" budget.exhausted "$phase" orchestrator "$tally"
    fi
  fi

  # After any *.done or *.alert event, rewrite manifest with last_phase.
  if [[ "$kind" == *.done || "$kind" == *.alert || "$kind" == "cycle.closed" || "$kind" == "cycle.opened" || "$kind" == "phase.failed" || "$kind" == "budget.exhausted" ]]; then
    local updated_manifest
    updated_manifest="$(python3 -c "
import json, sys
manifest_path, kind_val = sys.argv[1], sys.argv[2]
d = json.load(open(manifest_path))
d['last_phase'] = kind_val
if kind_val == 'cycle.closed':
    import time
    d['closed_at'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
print(json.dumps(d, indent=2))
" "$manifest" "$kind")"
    write_manifest "$manifest" "$updated_manifest"
  fi
}

# ---------------------------------------------------------------------------
# Subcommand: new-cycle [--budget $X] [--unattended]
# Acquires lock, mints ULID, creates cycle dir + manifest, emits cycle.opened.
# stdout: <ulid>
# ---------------------------------------------------------------------------
cmd_new_cycle() {
  local budget="" unattended=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --budget)    budget="${2:?--budget needs \$X}"; shift 2 ;;
      --unattended) unattended=1; shift ;;
      *) echo "flywheel new-cycle: unknown flag '$1'" >&2; return 2 ;;
    esac
  done

  # 028: unattended mode requires --budget (exits 2 with clear message).
  if [ "$unattended" -eq 1 ] && [ -z "$budget" ]; then
    echo "flywheel: unattended mode requires --budget <usd>" >&2
    return 2
  fi

  local cap_usd
  cap_usd="${budget:-5}"

  local cycle_id
  cycle_id="$(new_ulid)"
  local cycle_dir="backlog.d/_cycles/$cycle_id"

  # D1: cycle dir is created BEFORE lock acquire so we can record it on lock.
  # But spec says acquire BEFORE materializing dir. Spec wins (D1 says dir
  # created before phase runs, not before lock). Acquire first.
  if ! flywheel_acquire "$cycle_id"; then
    echo "flywheel: could not acquire lock" >&2
    return 1
  fi

  mkdir -p "$cycle_dir/evidence"

  local started_at
  started_at="$(python3 -c "import time; print(time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()))")"

  local manifest
  manifest="$(python3 -c "
import json, sys
cap = float(sys.argv[1])
started = sys.argv[2]
cycle_id = sys.argv[3]
d = {
  'schema_version': 1,
  'cycle_id': cycle_id,
  'item_id': None,
  'branch': None,
  'started_at': started,
  'closed_at': None,
  'status': 'open',
  'last_phase': 'cycle.opened',
  'budget': {
    'cap_usd': cap,
    'spent_usd': 0.0,
    'spent_by_phase': {},
    'wall_seconds': 0,
    'wall_cap_seconds': None
  },
  'phases': []
}
print(json.dumps(d, indent=2))
" "$cap_usd" "$started_at" "$cycle_id")"
  write_manifest "$cycle_dir/manifest.json" "$manifest"

  # Emit cycle.opened (directly, not via cmd_emit, to avoid chicken-and-egg).
  emit_event "$cycle_dir/cycle.jsonl" cycle.opened pick orchestrator \
    "{\"note\":\"cycle started\",\"budget_cap_usd\":$cap_usd}"

  echo "$cycle_id"
}

# ---------------------------------------------------------------------------
# Subcommand: pick <cycle_id>
# Implements 028 eligibility filter + scoring. Updates manifest item_id.
# stdout: <item_id> or literal EMPTY
# ---------------------------------------------------------------------------
cmd_pick() {
  local cycle_id="${1:?pick requires cycle_id}"
  local manifest="backlog.d/_cycles/$cycle_id/manifest.json"

  if [ ! -f "$manifest" ]; then
    echo "flywheel pick: no manifest for cycle $cycle_id" >&2
    return 1
  fi

  # Collect item_ids locked in OTHER open manifests (not ours).
  local locked_items
  locked_items="$(python3 -c "
import glob, json, sys, os
cycle_id = sys.argv[1]
locked = set()
for mf in glob.glob('backlog.d/_cycles/*/manifest.json'):
    parts = mf.split('/')
    cid = parts[2]
    if cid == cycle_id:
        continue
    try:
        d = json.load(open(mf))
    except Exception:
        continue
    if d.get('status') not in ('closed', 'aborted', 'abandoned', 'noop'):
        iid = d.get('item_id')
        if iid:
            locked.add(iid)
for item in sorted(locked):
    print(item)
" "$cycle_id")"

  local item_id
  item_id="$(python3 - "$cycle_id" <<'PYEOF'
import glob, json, os, re, sys
from datetime import datetime, timezone

cycle_id = sys.argv[1]

# Build set of locked item_ids from other open manifests.
locked = set()
for mf in glob.glob('backlog.d/_cycles/*/manifest.json'):
    cid = mf.split('/')[2]
    if cid == cycle_id:
        continue
    try:
        d = json.load(open(mf))
    except Exception:
        continue
    if d.get('status') not in ('closed', 'aborted', 'abandoned', 'noop'):
        iid = d.get('item_id')
        if iid:
            locked.add(iid)

SKIP_STATUSES = {'done', 'shipped', 'abandoned', 'blocked'}
PRIORITY_RANK = {
    'P0': 4,
    'P1': 3,
    'P2': 2,
    'P3': 1,
    'high': 3,
    'medium': 2,
    'low': 1,
}

now = datetime.now(timezone.utc)

def frontmatter(content: str) -> str:
    match = re.match(r'^---\n(.*?)\n---\n?', content, re.DOTALL)
    return match.group(1) if match else ''

def frontmatter_value(frontmatter_blob: str, key: str):
    match = re.search(rf'^{re.escape(key)}:\s*(.+)$', frontmatter_blob, re.MULTILINE)
    return match.group(1).strip() if match else None

def header_value(content: str, label: str):
    match = re.search(rf'^{re.escape(label)}:\s*(.+)$', content, re.MULTILINE)
    return match.group(1).strip() if match else None

def parse_dep_list(raw_value: str):
    raw_value = raw_value.strip()
    if not raw_value or raw_value == '[]':
        return []
    if raw_value.startswith('[') and raw_value.endswith(']'):
        inner = raw_value[1:-1].strip()
        if not inner:
            return []
        return [part.strip().strip('"').strip("'") for part in inner.split(',') if part.strip()]
    return [raw_value.strip().strip('"').strip("'")]

candidates = []
for path in glob.glob('backlog.d/[0-9][0-9]*-*.md'):
    fname = os.path.basename(path)
    stem = fname[:-3]  # strip .md
    content = open(path).read()
    meta = frontmatter(content)

    # Eligibility 1: pattern match (already covered by glob above).
    # Eligibility 2: Status not in skip set.
    status_val = frontmatter_value(meta, 'status') or header_value(content, 'Status')
    if status_val:
        status_val = status_val.strip().lower()
        if any(s in status_val for s in SKIP_STATUSES):
            continue

    # Eligibility 3: not locked by another open cycle.
    if stem in locked:
        continue

    # Eligibility 4: unresolved dependencies block pickup. Support both
    # frontmatter `depends_on:` and legacy `Blocked-by:` headers.
    dep_raw = frontmatter_value(meta, 'depends_on')
    blockers = parse_dep_list(dep_raw) if dep_raw is not None else []
    if not blockers:
        blocked_header = header_value(content, 'Blocked-by')
        blockers = parse_dep_list(blocked_header) if blocked_header else []
    blocked = False
    for blocker in blockers:
        blocker_id = blocker[:-3] if blocker.endswith('.md') else blocker
        blocker_path = f"backlog.d/{blocker_id}.md"
        if not os.path.exists(blocker_path):
            continue
        blocker_content = open(blocker_path).read()
        blocker_meta = frontmatter(blocker_content)
        blocker_status = (
            frontmatter_value(blocker_meta, 'status')
            or header_value(blocker_content, 'Status')
            or ''
        ).strip().lower()
        if not any(s in blocker_status for s in ('done', 'shipped')):
            blocked = True
            break
    if blocked:
        continue

    # Scoring.
    pri_str = frontmatter_value(meta, 'priority') or header_value(content, 'Priority')
    if pri_str:
        priority_rank = PRIORITY_RANK.get(pri_str, 0)
    else:
        priority_rank = 0

    readiness = 0
    if re.search(r'^## Oracle', content, re.MULTILINE):
        readiness = 2
    elif re.search(r'^Estimate:', content, re.MULTILINE):
        readiness = 1

    # Age: days since file mtime (proxy for age since no Created-at header).
    try:
        mtime = os.path.getmtime(path)
        age_days = (now.timestamp() - mtime) / 86400
    except Exception:
        age_days = 0

    score = 1000 * priority_rank + 100 * readiness + age_days
    candidates.append((score, fname, stem))

if not candidates:
    print('EMPTY')
    sys.exit(0)

# Highest score wins; ties break by lowest filename (NNN prefix).
candidates.sort(key=lambda x: (-x[0], x[1]))
print(candidates[0][2])
PYEOF
)"

  if [ "$item_id" = "EMPTY" ]; then
    # 028: emit cycle.opened amendment then close noop.
    # Design choice: we emit a second cycle.opened event with the empty-backlog
    # payload. This is the cleanest option per spec ("emit cycle.opened with
    # payload {item_id: null, reason: backlog_empty}"). The --until predicate
    # checks for cycle.closed status: noop, so this is load-bearing.
    local log="backlog.d/_cycles/$cycle_id/cycle.jsonl"
    emit_event "$log" cycle.opened pick orchestrator \
      '{"item_id":null,"reason":"backlog_empty"}'
    echo "EMPTY"
    return 0
  fi

  # Update manifest with item_id.
  local updated_manifest
  updated_manifest="$(python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
d['item_id'] = sys.argv[2]
print(json.dumps(d, indent=2))
" "$manifest" "$item_id")"
  write_manifest "$manifest" "$updated_manifest"

  echo "$item_id"
}

# ---------------------------------------------------------------------------
# Subcommand: emit <cycle_id> <kind> <phase> <agent> <payload_json>
# ---------------------------------------------------------------------------
cmd_emit_subcmd() {
  local cycle_id="${1:?emit requires cycle_id}"
  local kind="${2:?emit requires kind}"
  local phase="${3:?emit requires phase}"
  local agent="${4:?emit requires agent}"
  local payload="${5:-{\}}"

  cmd_emit "$cycle_id" "$kind" "$phase" "$agent" "$payload"
}

# ---------------------------------------------------------------------------
# Subcommand: close <cycle_id> <status> [<reason>]
# status ∈ {closed, aborted, abandoned, noop}
# ---------------------------------------------------------------------------
cmd_close() {
  local cycle_id="${1:?close requires cycle_id}"
  local status="${2:?close requires status}"
  local reason="${3:-}"
  local manifest="backlog.d/_cycles/$cycle_id/manifest.json"
  local log="backlog.d/_cycles/$cycle_id/cycle.jsonl"

  case "$status" in
    closed|aborted|abandoned|noop) ;;
    *) echo "flywheel close: status must be closed|aborted|abandoned|noop" >&2; return 2 ;;
  esac

  if [ ! -f "$manifest" ]; then
    echo "flywheel close: no manifest for cycle $cycle_id" >&2
    return 1
  fi

  local payload="{\"status\":\"$status\""
  [ -n "$reason" ] && payload="${payload},\"reason\":\"$reason\""
  payload="${payload}}"

  emit_event "$log" cycle.closed close orchestrator "$payload"

  # Update manifest status + closed_at.
  local updated
  updated="$(python3 -c "
import json, sys, time
d = json.load(open(sys.argv[1]))
d['status'] = sys.argv[2]
d['closed_at'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
d['last_phase'] = 'cycle.closed'
print(json.dumps(d, indent=2))
" "$manifest" "$status")"
  write_manifest "$manifest" "$updated"

  flywheel_release "$cycle_id"
}

# ---------------------------------------------------------------------------
# Subcommand: update-bucket <cycle_id> <ship_status>
# ship_status ∈ {shipped, failed, abandoned}
# Idempotent: guards every mutation with grep for cycle marker.
# ---------------------------------------------------------------------------
cmd_update_bucket() {
  local cycle_id="${1:?update-bucket requires cycle_id}"
  local ship_status="${2:?update-bucket requires ship_status}"
  local manifest="backlog.d/_cycles/$cycle_id/manifest.json"

  case "$ship_status" in
    shipped|failed|abandoned) ;;
    *) echo "flywheel update-bucket: ship_status must be shipped|failed|abandoned" >&2; return 2 ;;
  esac

  if [ ! -f "$manifest" ]; then
    echo "flywheel update-bucket: no manifest for cycle $cycle_id" >&2
    return 1
  fi

  local item_id branch
  item_id="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('item_id','') or '')" "$manifest")"
  branch="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('branch','') or '')" "$manifest")"

  if [ -z "$item_id" ]; then
    # noop cycle — nothing to update
    cmd_emit "$cycle_id" bucket.updated update-bucket orchestrator \
      '{"touched":[],"reason":"no_item"}'
    return 0
  fi

  # Find backlog source file.
  local src_path
  src_path="$(ls backlog.d/${item_id}.md 2>/dev/null || true)"
  if [ -z "$src_path" ]; then
    cmd_emit "$cycle_id" bucket.updated update-bucket orchestrator \
      "{\"touched\":[],\"reason\":\"item_not_found\",\"item_id\":\"$item_id\"}"
    return 0
  fi

  # Idempotence marker: the exact cycle ID string written into backlog files.
  # Both shipped ("## What Was Built (cycle <id>)") and failed
  # ("## Cycle <id> Attempt") contain the bare cycle_id — grep is case-insensitive.
  local marker="$cycle_id"
  local touched=()

  if [ "$ship_status" = "shipped" ]; then
    # Idempotence guard.
    if grep -q "$marker" "$src_path" 2>/dev/null; then
      cmd_emit "$cycle_id" bucket.updated update-bucket orchestrator \
        "{\"touched\":[],\"idempotent\":true,\"item_id\":\"$item_id\"}"
      return 0
    fi

    mkdir -p backlog.d/_done
    local dst_path="backlog.d/_done/$(basename "$src_path")"

    # Append shipping block to src before moving.
    cat >> "$src_path" <<EOF

## What Was Built (cycle $cycle_id)
- Branch: ${branch:-unknown}
- Evidence: backlog.d/_cycles/$cycle_id/evidence/
EOF

    mv "$src_path" "$dst_path"
    touched+=("$dst_path")

    # Update status to shipped in the moved file. Support both frontmatter
    # `status:` and legacy `Status:` headings.
    python3 -c "
import re, sys
path = sys.argv[1]
content = open(path).read()

lines = content.splitlines()
if lines and lines[0].strip() == '---':
    end = None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == '---':
            end = idx
            break
    if end is not None:
        replaced = False
        for idx in range(1, end):
            if lines[idx].lower().startswith('status:'):
                lines[idx] = 'status: shipped'
                replaced = True
                break
        if not replaced:
            lines.insert(end, 'status: shipped')
        content = '\n'.join(lines)
        if content and not content.endswith('\n'):
            content += '\n'
    else:
        content = re.sub(r'^Status:.*', 'Status: shipped', content, flags=re.MULTILINE)
elif re.search(r'^Status:', content, re.MULTILINE):
    content = re.sub(r'^Status:.*', 'Status: shipped', content, flags=re.MULTILINE)
else:
    content = content.rstrip('\n') + '\nStatus: shipped\n'

open(path, 'w').write(content)
" "$dst_path"

  else
    # failed or abandoned: stamp source file in place.
    if grep -q "$marker" "$src_path" 2>/dev/null; then
      # Already stamped — idempotent no-op.
      cmd_emit "$cycle_id" bucket.updated update-bucket orchestrator \
        "{\"touched\":[],\"idempotent\":true,\"item_id\":\"$item_id\"}"
      return 0
    fi

    local last_phase
    last_phase="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('last_phase','unknown'))" "$manifest")"

    cat >> "$src_path" <<EOF

## Cycle $cycle_id Attempt ($ship_status)
- Last phase: $last_phase
- Evidence: backlog.d/_cycles/$cycle_id/evidence/
EOF
    touched+=("$src_path")

    # Retry-count / auto-demote logic for P0/P1 items.
    local priority
    priority="$(python3 -c "
import re, sys
m = re.search(r'^Priority:\s*(P[0-3])', open(sys.argv[1]).read(), re.MULTILINE)
print(m.group(1) if m else '')
" "$src_path")"

    if [ "$priority" = "P0" ] || [ "$priority" = "P1" ]; then
      python3 -c "
import re, sys
path = sys.argv[1]
cap = 3
content = open(path).read()

# Parse current Retry-count.
m = re.search(r'^Retry-count:\s*(\d+)', content, re.MULTILINE)
count = int(m.group(1)) if m else 0
count += 1

if m:
    content = re.sub(r'^Retry-count:.*', f'Retry-count: {count}', content, flags=re.MULTILINE)
else:
    # Insert after Priority line.
    content = re.sub(r'(^Priority:.*)', r'\1\nRetry-count: ' + str(count), content, flags=re.MULTILINE, count=1)

if count >= cap:
    # Auto-demote priority one step.
    pri_map = {'P0': 'P1', 'P1': 'P2'}
    pri_m = re.search(r'^Priority:\s*(P[0-1])', content, re.MULTILINE)
    if pri_m:
        old_pri = pri_m.group(1)
        new_pri = pri_map.get(old_pri, old_pri)
        content = re.sub(r'^Priority:.*', f'Priority: {new_pri}', content, flags=re.MULTILINE)
        # Mark auto-demoted.
        if 'Auto-demoted:' not in content:
            content = re.sub(r'(^Priority:.*)', r'\1\nAuto-demoted: true', content, flags=re.MULTILINE, count=1)

open(path, 'w').write(content)
" "$src_path"
    fi
  fi

  local touched_json
  touched_json="$(python3 -c "
import json, sys
paths = sys.argv[1:]
print(json.dumps(paths))
" "${touched[@]+"${touched[@]}"}")"

  cmd_emit "$cycle_id" bucket.updated update-bucket orchestrator \
    "{\"touched\":$touched_json,\"ship_status\":\"$ship_status\",\"item_id\":\"$item_id\"}"
}

# ---------------------------------------------------------------------------
# Subcommand: update-harness <cycle_id>
# Phase 2a: emit harness.suggested with placeholder. Phase 2b wires branch.
# ---------------------------------------------------------------------------
cmd_update_harness() {
  local cycle_id="${1:?update-harness requires cycle_id}"

  # TODO(Phase-2b): implement branch mechanics per 028 §update-harness:
  # 1. If harness/auto-tune doesn't exist, create from default branch HEAD.
  # 2. If it exists, rebase onto default branch before appending.
  # 3. Each suggestion is one commit: harness: <kind> — <target> (cycle <ulid>).
  # 4. Push to origin only if FLYWHEEL_PUSH_HARNESS=1; default off.
  # 5. On conflict: emit phase.failed with {"reason":"harness_branch_conflict"}.
  # See 028 §update-harness for full branch mechanics.

  local suggestion_id
  suggestion_id="$(new_ulid)"

  cmd_emit "$cycle_id" harness.suggested update-harness orchestrator \
    "{\"suggestion_id\":\"$suggestion_id\",\"kind\":\"todo\",\"rationale\":\"Phase 2b wires branch mechanics\"}"
}

# ---------------------------------------------------------------------------
# Subcommand: budget <cycle_id>
# stdout: manifest's budget block as JSON
# ---------------------------------------------------------------------------
cmd_budget() {
  local cycle_id="${1:?budget requires cycle_id}"
  local manifest="backlog.d/_cycles/$cycle_id/manifest.json"

  if [ ! -f "$manifest" ]; then
    echo "flywheel budget: no manifest for cycle $cycle_id" >&2
    return 1
  fi

  python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(json.dumps(d['budget'], indent=2))" "$manifest"
}

# ---------------------------------------------------------------------------
# Subcommand: status [<cycle_id>]
# Human-readable cycle state summary.
# ---------------------------------------------------------------------------
cmd_status() {
  local cycle_id="${1:-}"

  if [ -n "$cycle_id" ]; then
    local manifest="backlog.d/_cycles/$cycle_id/manifest.json"
    if [ ! -f "$manifest" ]; then
      echo "flywheel status: no manifest for cycle $cycle_id" >&2
      return 1
    fi
    python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(f\"cycle: {d['cycle_id']}\")
print(f\"  item:      {d['item_id'] or '(none)'}\")
print(f\"  status:    {d['status']}\")
print(f\"  last_phase:{d['last_phase']}\")
b = d['budget']
print(f\"  budget:    \${b['spent_usd']:.2f} / \${b['cap_usd']:.2f}\")
print(f\"  started:   {d['started_at']}\")
print(f\"  closed:    {d['closed_at'] or '(open)'}\")
" "$manifest"
    return 0
  fi

  # List all manifests.
  local found=0
  for manifest in backlog.d/_cycles/*/manifest.json; do
    [ -f "$manifest" ] || continue
    found=1
    python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
b = d['budget']
print(f\"{d['cycle_id']}  {d['status']:10s}  {d['item_id'] or '(none)':40s}  \${b['spent_usd']:.2f}/\${b['cap_usd']:.2f}\")
" "$manifest"
  done
  if [ "$found" -eq 0 ]; then
    echo "(no cycles found)"
  fi
}

# ---------------------------------------------------------------------------
# run subcommand: drives the full outer loop (--dry-run or real).
# Accepts --max-cycles N, --budget $X, --unattended, --dry-run.
# Phase 2b flags --resume, --abandon, --until exit 2.
# ---------------------------------------------------------------------------
cmd_run() {
  local dry_run=0 max_cycles=1 budget="" unattended=0
  local until="" resume="" abandon=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)    dry_run=1; shift ;;
      --max-cycles) max_cycles="${2:?--max-cycles needs N}"; shift 2 ;;
      --budget)     budget="${2:?--budget needs \$N}"; shift 2 ;;
      --unattended) unattended=1; shift ;;
      --until)      until="${2:?}"; shift 2 ;;
      --resume)     resume="${2:?}"; shift 2 ;;
      --abandon)    abandon="${2:?}"; shift 2 ;;
      -h|--help)    usage_run; return 0 ;;
      *)            echo "flywheel run: unknown flag '$1'" >&2; usage_run; return 2 ;;
    esac
  done

  # Phase 2b stubs (028 §Resume & Abandon Semantics).
  if [ -n "$until" ]; then
    echo "flywheel: --until is Phase 2b; not implemented (028 §Stopping Predicates)" >&2
    return 2
  fi
  if [ -n "$resume" ]; then
    echo "flywheel: --resume is Phase 2b; not implemented (028 §Resume & Abandon Semantics)" >&2
    return 2
  fi
  if [ -n "$abandon" ]; then
    echo "flywheel: --abandon is Phase 2b; not implemented (028 §Resume & Abandon Semantics)" >&2
    return 2
  fi

  # Unattended requires --budget (028 §Budget Accounting).
  if [ "$unattended" -eq 1 ] && [ -z "$budget" ]; then
    echo "flywheel: unattended mode requires --budget <usd>" >&2
    return 2
  fi

  local cycles_completed=0

  while true; do
    if [ "$cycles_completed" -ge "$max_cycles" ]; then
      break
    fi

    # Mint cycle.
    local new_cycle_args=()
    [ -n "$budget" ] && new_cycle_args+=(--budget "$budget")
    [ "$unattended" -eq 1 ] && new_cycle_args+=(--unattended)

    local cycle_id
    cycle_id="$(cmd_new_cycle "${new_cycle_args[@]+"${new_cycle_args[@]}"}")"
    local cycle_dir="backlog.d/_cycles/$cycle_id"
    local log="$cycle_dir/cycle.jsonl"

    # Install traps scoped to this cycle.
    # shellcheck disable=SC2064
    trap "flywheel_release '$cycle_id'; exit 130" INT
    # shellcheck disable=SC2064
    trap "flywheel_release '$cycle_id'; exit 143" TERM
    # shellcheck disable=SC2064
    trap "flywheel_release '$cycle_id'" EXIT

    # Test hook: pause AFTER traps are installed so integration tests can
    # reliably fire SIGINT against the cycle. Write a sentinel file that tests
    # wait on (instead of just the lock file) to guarantee trap is in place.
    if [ -n "${FLYWHEEL_SIGINT_TEST_SLEEP:-}" ]; then
      [ -n "${FLYWHEEL_LOCK_PATH:-}" ] && touch "${FLYWHEEL_LOCK_PATH}.ready" || true
      sleep "$FLYWHEEL_SIGINT_TEST_SLEEP"
    fi

    if [ "$dry_run" -eq 1 ]; then
      # 028 Note: collapse inner-pipeline events into one deliver.done.
      # Walk all 8 outer phases: cycle.opened (already emitted by new-cycle)
      # → deliver.done → deploy.done → monitor.done → reflect.done
      # → bucket.updated → harness.suggested → cycle.closed
      emit_event "$log" deliver.done     deliver     builder       '{"note":"dry-run"}'
      emit_event "$log" deploy.done      deploy      deployer      '{"note":"dry-run"}'
      emit_event "$log" monitor.done     monitor     monitor       '{"note":"dry-run"}'
      emit_event "$log" reflect.done     reflect     reflector     '{"note":"dry-run"}'
      emit_event "$log" bucket.updated   update-bucket orchestrator '{"note":"dry-run","touched":[]}'
      emit_event "$log" harness.suggested update-harness orchestrator '{"note":"dry-run","kind":"todo"}'
      emit_event "$log" cycle.closed     close       orchestrator  '{"status":"closed"}'

      # Update manifest to reflect closed state.
      local updated
      updated="$(python3 -c "
import json, sys, time
d = json.load(open(sys.argv[1]))
d['status'] = 'closed'
d['closed_at'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
d['last_phase'] = 'cycle.closed'
print(json.dumps(d, indent=2))
" "$cycle_dir/manifest.json")"
      write_manifest "$cycle_dir/manifest.json" "$updated"

    else
      # Real mode: each phase shells out to the corresponding slash command.
      # The MODEL orchestrates by invoking subcommands; this block is the
      # machine-executable path only. See SKILL.md "Real Mode — Cycle
      # Orchestration" for the step-by-step operator guide.
      emit_event "$log" phase.failed pick orchestrator \
        '{"note":"real mode: use SKILL.md orchestration guide","reason":"model-must-orchestrate"}'
      emit_event "$log" cycle.closed close orchestrator '{"status":"aborted"}'
      local updated
      updated="$(python3 -c "
import json, sys, time
d = json.load(open(sys.argv[1]))
d['status'] = 'aborted'
d['closed_at'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
d['last_phase'] = 'cycle.closed'
print(json.dumps(d, indent=2))
" "$cycle_dir/manifest.json")"
      write_manifest "$cycle_dir/manifest.json" "$updated"
      flywheel_release "$cycle_id"
      trap - EXIT INT TERM
      return 1
    fi

    flywheel_release "$cycle_id"
    trap - EXIT INT TERM
    cycles_completed=$((cycles_completed + 1))

    # Output cycle_id for callers.
    echo "$cycle_id"
  done
}

usage_run() {
  cat >&2 <<EOF
/flywheel run — outer-loop driver

Usage: flywheel.sh run [--dry-run] [--max-cycles N] [--budget \$N] [--unattended]

Phase 2b (not implemented):
  --until <pred>   Stop predicate (028 §Stopping Predicates)
  --resume <ulid>  Resume paused cycle (028 §Resume & Abandon Semantics)
  --abandon <ulid> Abandon cycle (028 §Resume & Abandon Semantics)
EOF
}

usage() {
  cat >&2 <<EOF
/flywheel — outer-loop workflow orchestrator (Phase 2a)

Subcommands:
  run [--dry-run] [--max-cycles N] [--budget \$N] [--unattended]
  new-cycle [--budget \$X] [--unattended]
  pick <cycle_id>
  emit <cycle_id> <kind> <phase> <agent> <payload_json>
  close <cycle_id> <status> [<reason>]
  update-bucket <cycle_id> <ship_status>
  update-harness <cycle_id>
  budget <cycle_id>
  status [<cycle_id>]
EOF
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
SUBCMD="${1:-}"
shift || true

case "$SUBCMD" in
  new-cycle)      cmd_new_cycle "$@" ;;
  pick)           cmd_pick "$@" ;;
  emit)           cmd_emit_subcmd "$@" ;;
  close)          cmd_close "$@" ;;
  update-bucket)  cmd_update_bucket "$@" ;;
  update-harness) cmd_update_harness "$@" ;;
  budget)         cmd_budget "$@" ;;
  status)         cmd_status "$@" ;;
  run|"")         cmd_run "$@" ;;
  -h|--help)      usage; exit 0 ;;
  *)              echo "flywheel: unknown subcommand '$SUBCMD'" >&2; usage; exit 2 ;;
esac
