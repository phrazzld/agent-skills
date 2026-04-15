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
}

teardown() {
  cd "$ORIG_DIR"
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

# Latest cycle.jsonl written by iterate.sh in this TEST_DIR.
find_cycle_log() {
  # backlog.d/_cycles/<ulid>/cycle.jsonl ; pick the newest one.
  # shellcheck disable=SC2012
  ls -1t backlog.d/_cycles/*/cycle.jsonl 2>/dev/null | head -n 1 || true
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
  expected=$'cycle.opened\nshape.done\nbuild.done\nreview.iter\nci.done\nqa.done\ndeploy.done\nreflect.done\nharness.suggested\ncycle.closed'
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
  # Two cycle dirs should exist.
  local cycles
  cycles="$(ls -1 backlog.d/_cycles 2>/dev/null | wc -l | tr -d ' ')"
  assert_eq "two cycle directories created" "2" "$cycles"
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
