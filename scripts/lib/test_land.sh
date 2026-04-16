#!/usr/bin/env bash
# Tests for scripts/land.sh — verdict-gated branch landing.
# Runs in a temporary git repo to avoid polluting the real one.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PASS=0
FAIL=0

setup() {
  ORIG_DIR="$(pwd)"
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -q
  git commit --allow-empty -m "initial" -q
  # Symlink verdicts.sh so land.sh can source it
  mkdir -p scripts/lib
  ln -s "$REPO_ROOT/scripts/lib/verdicts.sh" scripts/lib/verdicts.sh
  # Copy land.sh into the temp repo
  cp "$REPO_ROOT/scripts/land.sh" scripts/land.sh
  chmod +x scripts/land.sh
  # Create a feature branch with a commit
  git checkout -b feat-test -q
  git commit --allow-empty -m "feature work" -q
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

assert_exit() {
  local desc="$1" expected="$2"
  shift 2
  local actual
  if "$@" >/dev/null 2>&1; then actual=0; else actual=$?; fi
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo "  PASS  $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL  $desc (expected exit $expected, got $actual)"
  fi
}

write_verdict() {
  local branch="$1" verdict_value="$2"
  local sha
  sha="$(git rev-parse HEAD)"
  source scripts/lib/verdicts.sh
  local json='{"branch":"'"$branch"'","base":"master","verdict":"'"$verdict_value"'","reviewers":["critic"],"scores":{"correctness":8},"sha":"'"$sha"'","date":"2026-04-06T15:00:00Z"}'
  verdict_write "$branch" "$json"
}

# --- Tests ---

test_land_rejects_missing_verdict() {
  assert_exit "land rejects missing verdict" 2 bash scripts/land.sh feat-test
}

test_land_rejects_dont_ship() {
  write_verdict feat-test dont-ship
  assert_exit "land rejects dont-ship verdict" 3 bash scripts/land.sh feat-test
}

test_land_accepts_ship() {
  write_verdict feat-test ship
  assert_exit "land accepts ship verdict" 0 bash scripts/land.sh feat-test
}

test_land_accepts_conditional() {
  write_verdict feat-test conditional
  assert_exit "land accepts conditional verdict" 0 bash scripts/land.sh feat-test
}

test_land_bypass_env_var() {
  assert_exit "land bypasses with SPELLBOOK_NO_REVIEW=1" 0 \
    env SPELLBOOK_NO_REVIEW=1 bash scripts/land.sh feat-test
}

test_land_rejects_stale_verdict() {
  write_verdict feat-test ship
  git commit --allow-empty -m "post-review commit" -q
  assert_exit "land rejects stale verdict" 2 bash scripts/land.sh feat-test
}

# --- Runner ---

run_tests() {
  local funcs
  funcs="$(declare -F | awk '/test_land_/{print $3}')"
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
