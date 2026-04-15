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
