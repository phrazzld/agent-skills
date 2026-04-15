#!/usr/bin/env bash
# Single-instance lock for /iterate.
# Lock file: .spellbook/iterate.lock
# Content:   {"pid": <int>, "cycle_id": "<ulid>", "started_at": "<iso8601 UTC>"}
#
# Two /iterate processes in the same repo would race on event log + bucket
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
# Atomicity: O_CREAT|O_EXCL creates the lock or fails; the kernel guarantees
# exactly one creator across concurrent callers, eliminating the TOCTOU race
# where two stealers both pass "kill -0" and both rename on top of each other.
# Args: <cycle_id>
iterate_acquire() {
  local cycle_id="$1"
  if [ -z "$cycle_id" ]; then
    echo "iterate_acquire: cycle_id required" >&2
    return 1
  fi

  mkdir -p "$(dirname "$ITERATE_LOCK_PATH")"

  ITERATE_LOCK_CYCLE_ID="$cycle_id" \
  ITERATE_LOCK_PID="$$" \
  ITERATE_LOCK_FILE="$ITERATE_LOCK_PATH" \
  python3 <<'PYEOF'
import errno, json, os, sys, time

path = os.environ["ITERATE_LOCK_FILE"]
payload = {
    "pid": int(os.environ["ITERATE_LOCK_PID"]),
    "cycle_id": os.environ["ITERATE_LOCK_CYCLE_ID"],
    "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
}


def write_fresh():
    """Atomic create-or-fail. Returns True on success, False if file exists."""
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    except FileExistsError:
        return False
    try:
        os.write(fd, json.dumps(payload).encode("utf-8"))
        os.fsync(fd)
    finally:
        os.close(fd)
    return True


def owner_alive():
    """Inspect current lock contents. Returns (alive, pid_or_none).
    Corrupt/unreadable lock → (False, None) so caller steals it."""
    try:
        with open(path) as f:
            data = json.load(f)
        pid = int(data.get("pid", 0))
    except Exception:
        return False, None
    if pid <= 0:
        return False, pid
    try:
        os.kill(pid, 0)
        return True, pid
    except (ProcessLookupError, PermissionError, OSError):
        return False, pid


# First attempt: O_EXCL create. Exactly one concurrent creator wins.
if write_fresh():
    sys.exit(0)

# Lock exists. If owner is alive, refuse.
alive, pid = owner_alive()
if alive:
    print(f"iterate_acquire: lock held by live pid {pid}", file=sys.stderr)
    sys.exit(1)

# Stale or corrupt. Attempt ONE steal: unlink then O_EXCL retry. If another
# stealer unlinked-and-recreated between our unlink and our create, their
# create wins and ours raises FileExistsError → we re-check liveness and
# either refuse (they're our live rival) or fail; either is correct behavior.
try:
    os.unlink(path)
except FileNotFoundError:
    pass  # another stealer already unlinked; that's fine

if write_fresh():
    sys.exit(0)

# Someone else won the race to recreate. If they're alive, they hold it.
alive, pid = owner_alive()
if alive:
    print(f"iterate_acquire: lost steal race to live pid {pid}", file=sys.stderr)
    sys.exit(1)
# They created it then died before we could check — conservative: refuse
# rather than loop. Caller can retry.
print("iterate_acquire: lost steal race", file=sys.stderr)
sys.exit(1)
PYEOF
}

# Release the iterate lock. Fully idempotent: any of (a) missing lock,
# (b) cycle_id mismatch, (c) successful removal returns 0. The mismatch case
# is a no-op — a late trap from a finished cycle must not wipe a successor's
# lock. Callers never need `|| true`.
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
  recorded="$(ITERATE_LOCK_FILE="$ITERATE_LOCK_PATH" python3 -c '
import json, os
try:
    print(json.load(open(os.environ["ITERATE_LOCK_FILE"])).get("cycle_id", ""))
except Exception:
    print("")
' 2>/dev/null)"
  if [ "$recorded" != "$cycle_id" ]; then
    # Observability: log the skip but do not fail. Lock belongs to another
    # cycle (or is corrupt) — not ours to delete.
    echo "iterate_release: no-op (lock cycle=$recorded, asked=$cycle_id)" >&2
    return 0
  fi
  rm -f "$ITERATE_LOCK_PATH"
}
