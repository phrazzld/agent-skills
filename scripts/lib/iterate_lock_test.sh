#!/usr/bin/env bash
# Tests for iterate_lock.sh — single-instance lock with stale-pid detection.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

setup() {
  ORIG_DIR="$(pwd)"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  mkdir -p .spellbook
  LOCK=".spellbook/iterate.lock"
  # Reset before sourcing; source sets ITERATE_LOCK_PATH=default only if unset.
  unset ITERATE_LOCK_PATH
  # shellcheck source=scripts/lib/iterate_lock.sh
  source "$SCRIPT_DIR/iterate_lock.sh"
}

teardown() {
  cd "$ORIG_DIR"
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

assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local actual
  if "$@" >/dev/null 2>&1; then actual=0; else actual=$?; fi
  assert_eq "$desc" "$expected" "$actual"
}

# --- Tests ---

test_iterate_acquire_creates_lock_file() {
  iterate_acquire 01HABC
  assert_eq "lock file exists" "yes" "$([ -f "$LOCK" ] && echo yes || echo no)"
}

test_iterate_acquire_writes_pid_and_cycle_id() {
  iterate_acquire 01HABC
  local pid cycle_id started
  pid="$(python3 -c "import json,sys; print(json.load(sys.stdin)['pid'])" < "$LOCK")"
  cycle_id="$(python3 -c "import json,sys; print(json.load(sys.stdin)['cycle_id'])" < "$LOCK")"
  started="$(python3 -c "import json,sys; print(json.load(sys.stdin)['started_at'])" < "$LOCK")"
  assert_eq "pid is current shell pid" "$$" "$pid"
  assert_eq "cycle_id recorded" "01HABC" "$cycle_id"
  case "$started" in
    *T*Z) assert_eq "started_at is ISO-8601 UTC" "ok" "ok" ;;
    *)    assert_eq "started_at is ISO-8601 UTC" "ok" "bad:$started" ;;
  esac
}

test_iterate_acquire_second_call_fails_when_pid_alive() {
  iterate_acquire 01HABC
  # Rewrite lock so pid is truly alive (this shell) but cycle differs.
  assert_exit "second acquire fails" 1 iterate_acquire 01HDEF
}

test_iterate_acquire_steals_stale_lock() {
  # Write a stale lock pointing at a pid that cannot exist (pid 0 is never
  # a user process on unix).
  python3 -c "
import json
open('.spellbook/iterate.lock','w').write(json.dumps({'pid':0,'cycle_id':'01HOLD','started_at':'2000-01-01T00:00:00Z'}))
"
  assert_exit "acquire steals stale lock" 0 iterate_acquire 01HNEW
  local cycle_id
  cycle_id="$(python3 -c "import json,sys; print(json.load(sys.stdin)['cycle_id'])" < "$LOCK")"
  assert_eq "new cycle_id written after steal" "01HNEW" "$cycle_id"
}

test_iterate_release_removes_lock() {
  iterate_acquire 01HABC
  iterate_release 01HABC
  assert_eq "lock file removed" "no" "$([ -f "$LOCK" ] && echo yes || echo no)"
}

test_iterate_release_refuses_wrong_cycle_id() {
  iterate_acquire 01HABC
  assert_exit "release with wrong cycle_id fails" 1 iterate_release 01HOTHER
  assert_eq "lock still present" "yes" "$([ -f "$LOCK" ] && echo yes || echo no)"
}

test_iterate_release_no_lock_is_ok() {
  # Idempotent: releasing a non-existent lock shouldn't explode (cleanup traps
  # may fire on paths that never acquired).
  assert_exit "release of missing lock returns 0" 0 iterate_release 01HABC
}

test_iterate_acquire_after_release_succeeds() {
  iterate_acquire 01HABC
  iterate_release 01HABC
  assert_exit "re-acquire after release succeeds" 0 iterate_acquire 01HDEF
}

test_iterate_acquire_path_with_single_quotes_is_safe() {
  # Regression: path containing a single quote must not break the heredoc
  # that reads the existing lock. Previous impl interpolated the path into a
  # Python single-quoted string — a quote or backslash in the path caused a
  # SyntaxError, swallowed by 2>/dev/null, producing empty existing_pid,
  # treated as stale, silently stealing a live lock.
  local quoted_dir="$TEST_DIR/has'quote"
  mkdir -p "$quoted_dir"
  local prev_path="$ITERATE_LOCK_PATH"
  ITERATE_LOCK_PATH="$quoted_dir/iterate.lock"
  # First acquire should succeed.
  assert_exit "acquire with quoted path succeeds" 0 iterate_acquire 01HABC
  # Lock file should actually exist at that path.
  assert_eq "lock exists at quoted path" "yes" \
    "$([ -f "$ITERATE_LOCK_PATH" ] && echo yes || echo no)"
  # Second acquire (same live shell pid) must refuse, proving the reader
  # successfully parsed the pid out of the quoted-path lock.
  assert_exit "second acquire refused with quoted path" 1 iterate_acquire 01HDEF
  # Release must succeed and actually remove the file.
  assert_exit "release with quoted path succeeds" 0 iterate_release 01HABC
  assert_eq "lock removed at quoted path" "no" \
    "$([ -f "$ITERATE_LOCK_PATH" ] && echo yes || echo no)"
  ITERATE_LOCK_PATH="$prev_path"
}

test_iterate_acquire_corrupt_lock_is_treated_as_stale() {
  # Prior process crashed mid-write or disk ate the JSON. Don't hang forever.
  echo "not json" > "$LOCK"
  assert_exit "corrupt lock treated as stale, acquire succeeds" 0 iterate_acquire 01HABC
}

# --- Runner ---

run_tests() {
  local funcs
  funcs="$(declare -F | awk '/test_iterate_/{print $3}')"
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
