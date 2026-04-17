#!/usr/bin/env bash
# Tests for scripts/tailor-lint.sh.
#
# Covers:
#   - No .claude/skills/ → pass (no-op, exit 0)
#   - Empty .claude/skills/ → pass
#   - 1 or 2 benign skills → pass
#   - 3 benign skills → fail (cap exceeded)
#   - Shadow of global primitive name → fail
#   - Directory without SKILL.md inside skills/ → ignored
#   - Both failures at once → fail with both messages

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$REPO_ROOT/scripts/tailor-lint.sh"

fail=0
fails=()

make_skill() {
  local skills_dir="$1" name="$2"
  mkdir -p "$skills_dir/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$skills_dir/$name/SKILL.md"
}

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n    expected exit: %s\n    actual exit:   %s\n' "$label" "$expected" "$actual"
    fail=1
    fails+=("$label")
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if printf '%s' "$haystack" | grep -q -F -- "$needle"; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n    needle: %s\n    in:\n%s\n' "$label" "$needle" "$haystack"
    fail=1
    fails+=("$label")
  fi
}

run_lint() {
  local target="$1"
  local rc=0
  local out
  out=$("$LINT" "$target" 2>&1) || rc=$?
  printf '%s\n%s' "$rc" "$out"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "test: no .claude/skills/ → exit 0"
mkdir -p "$tmp/r1"
out=$(run_lint "$tmp/r1")
rc=$(printf '%s' "$out" | head -1)
assert_exit "no skills dir exit 0" "0" "$rc"

echo "test: empty .claude/skills/ → exit 0"
mkdir -p "$tmp/r2/.claude/skills"
out=$(run_lint "$tmp/r2")
rc=$(printf '%s' "$out" | head -1)
assert_exit "empty skills dir exit 0" "0" "$rc"

echo "test: one benign skill → exit 0"
mkdir -p "$tmp/r3/.claude/skills"
make_skill "$tmp/r3/.claude/skills" "rust-migrations"
out=$(run_lint "$tmp/r3")
rc=$(printf '%s' "$out" | head -1)
assert_exit "one benign skill exit 0" "0" "$rc"

echo "test: two benign skills (at cap) → exit 0"
mkdir -p "$tmp/r4/.claude/skills"
make_skill "$tmp/r4/.claude/skills" "rust-migrations"
make_skill "$tmp/r4/.claude/skills" "axum-handlers"
out=$(run_lint "$tmp/r4")
rc=$(printf '%s' "$out" | head -1)
assert_exit "two benign at cap exit 0" "0" "$rc"

echo "test: three benign skills → exit 1, cap error"
mkdir -p "$tmp/r5/.claude/skills"
make_skill "$tmp/r5/.claude/skills" "a"
make_skill "$tmp/r5/.claude/skills" "b"
make_skill "$tmp/r5/.claude/skills" "c"
out=$(run_lint "$tmp/r5")
rc=$(printf '%s' "$out" | head -1)
body=$(printf '%s' "$out" | tail -n +2)
assert_exit "three skills exit 1" "1" "$rc"
assert_contains "three skills cap message" "MVP cap is 2" "$body"

echo "test: shadow of global primitive (code-review) → exit 1"
mkdir -p "$tmp/r6/.claude/skills"
make_skill "$tmp/r6/.claude/skills" "code-review"
out=$(run_lint "$tmp/r6")
rc=$(printf '%s' "$out" | head -1)
body=$(printf '%s' "$out" | tail -n +2)
assert_exit "shadow exit 1" "1" "$rc"
assert_contains "shadow message names code-review" "code-review" "$body"
assert_contains "shadow message mentions primitives" "load-bearing spellbook primitives" "$body"

echo "test: shadow + cap (benign + shadow + extra) → exit 1 with both errors"
mkdir -p "$tmp/r7/.claude/skills"
make_skill "$tmp/r7/.claude/skills" "rust-migrations"
make_skill "$tmp/r7/.claude/skills" "shape"
make_skill "$tmp/r7/.claude/skills" "extra"
out=$(run_lint "$tmp/r7")
rc=$(printf '%s' "$out" | head -1)
body=$(printf '%s' "$out" | tail -n +2)
assert_exit "shadow+cap exit 1" "1" "$rc"
assert_contains "shadow+cap shadow msg" "shape" "$body"
assert_contains "shadow+cap cap msg" "MVP cap is 2" "$body"

echo "test: directory in skills/ without SKILL.md → ignored"
mkdir -p "$tmp/r8/.claude/skills/not-a-skill"
out=$(run_lint "$tmp/r8")
rc=$(printf '%s' "$out" | head -1)
assert_exit "non-skill dir ignored exit 0" "0" "$rc"

echo "test: all 9 shadow names rejected"
for bad in groom shape deliver flywheel code-review settle reflect tailor harness; do
  rmdir "$tmp/probe/.claude/skills/"* 2>/dev/null || true
  rm -rf "$tmp/probe"
  mkdir -p "$tmp/probe/.claude/skills"
  make_skill "$tmp/probe/.claude/skills" "$bad"
  out=$(run_lint "$tmp/probe")
  rc=$(printf '%s' "$out" | head -1)
  assert_exit "shadow $bad rejected" "1" "$rc"
done

echo "test: nonexistent target root → exit 2 (usage error)"
out=$(run_lint "$tmp/does-not-exist")
rc=$(printf '%s' "$out" | head -1)
assert_exit "bad target exit 2" "2" "$rc"

echo
if [ "$fail" -eq 0 ]; then
  echo "all tests passed"
  exit 0
else
  printf '%d test(s) failed: %s\n' "${#fails[@]}" "${fails[*]}"
  exit 1
fi
