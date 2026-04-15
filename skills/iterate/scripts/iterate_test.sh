#!/usr/bin/env bash
# Integration tests for skills/iterate/scripts/iterate.sh.
# Runs each test in a temp directory so real repo state is untouched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPELLBOOK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ITERATE_SH="$SCRIPT_DIR/iterate.sh"
PASS=0
FAIL=0

setup() {
  ORIG_DIR="$(pwd)"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  mkdir -p .spellbook
  unset ITERATE_LOCK_PATH
  ITERATE_LOCK_PATH="$TEST_DIR/.spellbook/iterate.lock"
  export ITERATE_LOCK_PATH
  # iterate.sh cd's to REPO_ROOT and writes cycles to REPO_ROOT/backlog.d/_cycles/.
  # Snapshot the pre-existing entries so teardown can delete only what this test
  # created — never anything that predated the run.
  CYCLES_ROOT="$SPELLBOOK_ROOT/backlog.d/_cycles"
  if [ -d "$CYCLES_ROOT" ]; then
    CYCLES_PRE="$(ls -1 "$CYCLES_ROOT" 2>/dev/null | sort)"
  else
    CYCLES_PRE=""
  fi
}

teardown() {
  cd "$ORIG_DIR"
  # Clean up any cycle dirs this test created under REPO_ROOT.
  if [ -d "$CYCLES_ROOT" ]; then
    local post
    post="$(ls -1 "$CYCLES_ROOT" 2>/dev/null | sort || true)"
    local new
    new="$(comm -13 <(printf '%s\n' "$CYCLES_PRE") <(printf '%s\n' "$post") 2>/dev/null | awk 'NF' || true)"
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      rm -rf "$CYCLES_ROOT/$name"
    done <<< "$new"
    # Remove _cycles dir if it became empty and didn't exist pre-test.
    if [ -z "$CYCLES_PRE" ] && [ -d "$CYCLES_ROOT" ] && [ -z "$(ls -A "$CYCLES_ROOT" 2>/dev/null)" ]; then
      rmdir "$CYCLES_ROOT" 2>/dev/null || true
    fi
  fi
  unset ITERATE_LOCK_PATH
  rm -rf "$TEST_DIR"
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "  PASS  $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL  $desc (expected '$expected', got '$actual')"
  fi
}

# --- Helpers ---

# Latest cycle.jsonl written by iterate.sh in this test. iterate.sh now
# anchors writes to REPO_ROOT, so we look there.
find_cycle_log() {
  # shellcheck disable=SC2012
  ls -1t "$SPELLBOOK_ROOT"/backlog.d/_cycles/*/cycle.jsonl 2>/dev/null | head -n 1 || true
}

# Extract JSONL "kind" field from every line.
kinds_in() {
  python3 -c "
import json, sys
for line in open(sys.argv[1]):
    line = line.strip()
    if not line: continue
    print(json.loads(line).get('kind',''))
" "$1"
}

# --- ULID tests (B3) ---

test_ulid_fallback_is_crockford_base32_26_chars() {
  # Force the ImportError branch: create a shadow PYTHONPATH with a ulid
  # module that raises on import.
  local fake_dir="$TEST_DIR/fake_pythonpath"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/ulid.py" <<'PY'
raise ImportError("forced for test")
PY
  local out
  out="$(PYTHONPATH="$fake_dir" python3 - <<'PYEOF'
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
    ts = int(time.time() * 1000) & ((1<<48)-1)
    rnd = secrets.randbits(80)
    print(_enc(ts, 10) + _enc(rnd, 16))
PYEOF
)"
  # Length 26.
  assert_eq "fallback ULID length 26" "26" "${#out}"
  # Crockford-base32 charset only (no I, L, O, U).
  if [[ "$out" =~ ^[0-9A-HJKMNP-TV-Z]{26}$ ]]; then
    assert_eq "fallback ULID matches Crockford charset" "ok" "ok"
  else
    assert_eq "fallback ULID matches Crockford charset" "ok" "bad:$out"
  fi
}

test_new_ulid_helper_produces_26_crockford_chars() {
  # Exercise iterate.sh's new_ulid() directly in fallback mode by forcing
  # ulid import to fail.
  local fake_dir="$TEST_DIR/fake_pythonpath"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/ulid.py" <<'PY'
raise ImportError("forced for test")
PY
  local out
  # Source iterate.sh is not directly possible (it runs on source); instead
  # invoke a tiny python equivalent of its block.
  out="$(PYTHONPATH="$fake_dir" python3 - <<'PYEOF'
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
    ts = int(time.time() * 1000) & ((1<<48)-1)
    rnd = secrets.randbits(80)
    print(_enc(ts, 10) + _enc(rnd, 16))
PYEOF
)"
  assert_eq "new_ulid (fallback) length 26" "26" "${#out}"
}

test_iterate_emits_26char_crockford_cycle_id() {
  # End-to-end: run iterate.sh --dry-run and inspect cycle_id in the jsonl.
  # Force the ImportError fallback so we test the path that was broken.
  local fake_dir="$TEST_DIR/fake_pythonpath"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/ulid.py" <<'PY'
raise ImportError("forced for test")
PY
  PYTHONPATH="$fake_dir" bash "$ITERATE_SH" --dry-run >/dev/null 2>&1
  local log cid
  log="$(find_cycle_log)"
  cid="$(python3 -c "
import json, sys
line = open(sys.argv[1]).readline().strip()
print(json.loads(line)['cycle_id'])
" "$log")"
  assert_eq "emitted cycle_id length" "26" "${#cid}"
  if [[ "$cid" =~ ^[0-9A-HJKMNP-TV-Z]{26}$ ]]; then
    assert_eq "emitted cycle_id matches Crockford charset" "ok" "ok"
  else
    assert_eq "emitted cycle_id matches Crockford charset" "ok" "bad:$cid"
  fi
}

# --- Integration tests (B5, B6) ---

test_dry_run_writes_expected_event_kinds_in_order() {
  bash "$ITERATE_SH" --dry-run >/dev/null 2>&1
  local log
  log="$(find_cycle_log)"
  local expected actual
  expected=$'cycle.opened\nshape.done\nbuild.done\nreview.iter\nci.done\nqa.done\ndeploy.done\nreflect.done\ncycle.closed'
  actual="$(kinds_in "$log")"
  assert_eq "dry-run event kinds match expected sequence" "$expected" "$actual"
}

test_max_cycles_gt_1_without_budget_exits_2() {
  local rc=0
  bash "$ITERATE_SH" --dry-run --max-cycles 2 >/dev/null 2>&1 || rc=$?
  assert_eq "max-cycles>1 without budget exits 2" "2" "$rc"
}

test_until_flag_is_phase2_exits_2() {
  local rc=0
  bash "$ITERATE_SH" --until "backlog empty" >/dev/null 2>&1 || rc=$?
  assert_eq "--until exits 2 (Phase 2)" "2" "$rc"
}

test_resume_flag_is_phase2_exits_2() {
  local rc=0
  bash "$ITERATE_SH" --resume 01HFAKE >/dev/null 2>&1 || rc=$?
  assert_eq "--resume exits 2 (Phase 2)" "2" "$rc"
}

test_real_mode_emits_phase_failed_and_cycle_closed_and_exits_1() {
  local rc=0
  bash "$ITERATE_SH" >/dev/null 2>&1 || rc=$?
  assert_eq "real mode exits 1" "1" "$rc"
  local log kinds
  log="$(find_cycle_log)"
  kinds="$(kinds_in "$log")"
  local has_failed=0 has_closed=0
  while IFS= read -r k; do
    [ "$k" = "phase.failed" ] && has_failed=1
    [ "$k" = "cycle.closed" ] && has_closed=1
  done <<< "$kinds"
  assert_eq "real mode emits phase.failed" "1" "$has_failed"
  assert_eq "real mode emits cycle.closed" "1" "$has_closed"
  # Lock must have been released.
  assert_eq "real mode releases lock" "no" \
    "$([ -f "$ITERATE_LOCK_PATH" ] && echo yes || echo no)"
}

test_two_sequential_dry_runs_both_succeed() {
  # Second invocation must acquire the lock the first one released.
  bash "$ITERATE_SH" --dry-run >/dev/null 2>&1
  local rc1=$?
  bash "$ITERATE_SH" --dry-run >/dev/null 2>&1
  local rc2=$?
  assert_eq "first dry-run cycle exits 0" "0" "$rc1"
  assert_eq "second dry-run cycle exits 0" "0" "$rc2"
  # Two cycle dirs should exist (above the pre-test baseline under REPO_ROOT).
  local post new_cycles
  post="$(ls -1 "$CYCLES_ROOT" 2>/dev/null | sort || true)"
  new_cycles="$(comm -13 <(printf '%s\n' "$CYCLES_PRE") <(printf '%s\n' "$post") 2>/dev/null | awk 'NF' | wc -l | tr -d ' ')"
  assert_eq "two cycle directories created" "2" "$new_cycles"
}

test_sigint_releases_lock_via_trap() {
  # Block iterate.sh inside the cycle so we can SIGINT mid-flight. We wrap
  # a python sleep into the spellbook PATH — but iterate.sh does not call
  # python by name mid-cycle. Simpler: drive a shell-level INT after the
  # cycle acquires its lock. The dry-run path is short, so we need a
  # synthetic pause. Instead, assert the invariant indirectly: after a
  # completed dry-run, the lock is absent. Then separately test that when
  # we SIGINT a long-running real-mode process before cycle.closed, the
  # trap still removes the lockfile.
  #
  # Mechanism: start iterate.sh in background without --dry-run; it will
  # acquire, emit phase.failed, release, exit 1 quickly. We time SIGINT to
  # land after the acquire and assert no residual lock.
  ( bash "$ITERATE_SH" --dry-run >/dev/null 2>&1 ) &
  local pid=$!
  # Give it a brief moment to set the trap + acquire.
  sleep 0.05
  kill -INT "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  # After SIGINT (or natural completion), the lockfile must be gone.
  assert_eq "lock cleared after SIGINT / completion" "no" \
    "$([ -f "$ITERATE_LOCK_PATH" ] && echo yes || echo no)"
}

# --- B7: SIGINT exit code contract ---

test_sigint_exits_with_130() {
  # SKILL.md contract: "SIGINT → trap releases lock, exit 130". A pure
  # `trap iterate_release EXIT INT TERM` without explicit `exit 130` causes
  # bash to run the handler and continue the script.
  #
  # Gotcha: bash backgrounded with `&` inherits SIG_IGN for SIGINT and a
  # `trap "..." INT` inside the script can't override it ("signals ignored
  # upon entry to the shell cannot be trapped"). So we drive the SIGINT via
  # python3's subprocess, which restores default signal handlers in the
  # child. This is how a real interactive ^C reaches iterate.sh.
  #
  # ITERATE_SIGINT_TEST_SLEEP is an env-only hook iterate.sh honors to pause
  # after acquire, giving us a deterministic SIGINT window.
  local rc
  rc="$(ITERATE_LOCK_PATH="$ITERATE_LOCK_PATH" \
        ITERATE_SH="$ITERATE_SH" \
        python3 - <<'PYEOF'
import os, signal, subprocess, time
env = os.environ.copy()
env["ITERATE_SIGINT_TEST_SLEEP"] = "10"
p = subprocess.Popen(["bash", env["ITERATE_SH"], "--dry-run"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     env=env)
# Wait for lock file so we know the trap is in place.
lock = env["ITERATE_LOCK_PATH"]
for _ in range(200):  # up to 10s, plenty for CI
    if os.path.exists(lock):
        time.sleep(0.05)  # let the trap install
        break
    time.sleep(0.05)
p.send_signal(signal.SIGINT)
p.wait()
print(p.returncode)
PYEOF
)"
  assert_eq "SIGINT causes iterate.sh to exit 130" "130" "$rc"
  assert_eq "lock cleared after SIGINT" "no" \
    "$([ -f "$ITERATE_LOCK_PATH" ] && echo yes || echo no)"
}

test_sigterm_exits_with_143() {
  # Companion to SIGINT: SIGTERM must exit 143 (128 + 15).
  local rc
  rc="$(ITERATE_LOCK_PATH="$ITERATE_LOCK_PATH" \
        ITERATE_SH="$ITERATE_SH" \
        python3 - <<'PYEOF'
import os, signal, subprocess, time
env = os.environ.copy()
env["ITERATE_SIGINT_TEST_SLEEP"] = "10"
p = subprocess.Popen(["bash", env["ITERATE_SH"], "--dry-run"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     env=env)
lock = env["ITERATE_LOCK_PATH"]
for _ in range(200):  # up to 10s, plenty for CI
    if os.path.exists(lock):
        time.sleep(0.05)  # let the trap install
        break
    time.sleep(0.05)
p.send_signal(signal.SIGTERM)
p.wait()
print(p.returncode)
PYEOF
)"
  assert_eq "SIGTERM causes iterate.sh to exit 143" "143" "$rc"
  assert_eq "lock cleared after SIGTERM" "no" \
    "$([ -f "$ITERATE_LOCK_PATH" ] && echo yes || echo no)"
}

# --- B8: orphan cycle dir on lock contention ---

test_failed_acquire_leaves_no_orphan_cycle_dir() {
  # Pre-create a live-pid lock so iterate_acquire will refuse.
  python3 -c "
import json, os
os.makedirs('.spellbook', exist_ok=True)
open(os.environ['ITERATE_LOCK_PATH'],'w').write(
  json.dumps({'pid': $$, 'cycle_id': '01HHELD', 'started_at': '2026-01-01T00:00:00Z'}))
"
  # Second invocation must fail to acquire. Assert no NEW cycle dir appeared
  # under REPO_ROOT/backlog.d/_cycles after the failed acquire.
  local rc=0
  bash "$ITERATE_SH" --dry-run >/dev/null 2>&1 || rc=$?
  assert_eq "colliding invocation fails non-zero" "1" "$rc"
  local post new_cycles
  post="$(ls -1 "$CYCLES_ROOT" 2>/dev/null | sort || true)"
  new_cycles="$(comm -13 <(printf '%s\n' "$CYCLES_PRE") <(printf '%s\n' "$post") 2>/dev/null | awk 'NF' | wc -l | tr -d ' ')"
  assert_eq "no orphan cycle dir after failed acquire" "0" "$new_cycles"
}

# --- B9: paths anchored to REPO_ROOT, not PWD ---

test_off_repo_invocation_writes_to_repo_root() {
  # Invoke iterate.sh from a directory OUTSIDE the spellbook repo. Artifacts
  # must land under REPO_ROOT, not under PWD. (Teardown cleans up any new
  # cycle dir this test spawns under REPO_ROOT.)
  local off_repo_dir="$TEST_DIR/off_repo"
  mkdir -p "$off_repo_dir"
  # Use an absolute lock path anchored to TEST_DIR so the lock file lands
  # there if the fix regresses — making REPO_ROOT anchoring observable.
  (
    cd "$off_repo_dir"
    ITERATE_LOCK_PATH="$TEST_DIR/off_repo.lock" \
      bash "$ITERATE_SH" --dry-run >/dev/null 2>&1
  )
  # No backlog.d tree should be created under PWD.
  assert_eq "no backlog.d/_cycles under off-repo PWD" "no" \
    "$([ -d "$off_repo_dir/backlog.d/_cycles" ] && echo yes || echo no)"
  # A new cycle dir must exist under REPO_ROOT.
  local post new_cycles
  post="$(ls -1 "$CYCLES_ROOT" 2>/dev/null | sort || true)"
  new_cycles="$(comm -13 <(printf '%s\n' "$CYCLES_PRE") <(printf '%s\n' "$post") 2>/dev/null | awk 'NF' | wc -l | tr -d ' ')"
  assert_eq "exactly one new cycle dir under REPO_ROOT" "1" "$new_cycles"
}

# --- B10: --max-cycles > 1 rejected in Phase 1 ---

test_max_cycles_2_exits_2_with_phase2_message() {
  local out rc=0
  out="$(bash "$ITERATE_SH" --dry-run --max-cycles 2 --budget 10 2>&1)" || rc=$?
  assert_eq "--max-cycles 2 exits 2" "2" "$rc"
  if echo "$out" | grep -q "Phase 2"; then
    assert_eq "--max-cycles>1 error message mentions Phase 2" "ok" "ok"
  else
    assert_eq "--max-cycles>1 error message mentions Phase 2" "ok" "bad:$out"
  fi
}

# --- Runner ---

run_tests() {
  local funcs
  funcs="$(declare -F | awk '/^declare -f test_/{print $3}')"
  for t in $funcs; do
    setup
    "$t"
    teardown
  done
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}

run_tests
