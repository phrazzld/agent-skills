#!/usr/bin/env bash
# Test bootstrap.sh's .spellbook.yaml allowlist filter.
#
# Verifies:
#   - No .spellbook.yaml → global behavior (all skills discovered)
#   - Valid allowlist → GLOBAL_SKILLS and EXTERNAL_SKILLS intersected with
#     allowlist, preserving allowlist order
#   - Malformed .spellbook.yaml → warning + fall through to global behavior
#   - Unknown name in allowlist → warning + that name silently dropped
#
# Strategy: run bootstrap.sh as a subprocess with SPELLBOOK_TEST_MODE=1
# pointing at a fake spellbook checkout + fake project dir. The bootstrap
# exits cleanly right after the allowlist filter step and prints the
# resulting state so the test can assert on it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOTSTRAP="$REPO_ROOT/bootstrap.sh"

fail=0
fails=()

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    printf '  ok   %s\n' "$label"
  else
    printf '  FAIL %s\n    expected: %s\n    actual:   %s\n' "$label" "$expected" "$actual"
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

# Build a minimal fake spellbook checkout.
make_fake_spellbook() {
  local root="$1"
  mkdir -p "$root/skills/a" "$root/skills/b" "$root/skills/c" \
           "$root/skills/.external/d" "$root/skills/.external/e" \
           "$root/agents" "$root/harnesses"
  printf -- '---\nname: a\n---\n' > "$root/skills/a/SKILL.md"
  printf -- '---\nname: b\n---\n' > "$root/skills/b/SKILL.md"
  printf -- '---\nname: c\n---\n' > "$root/skills/c/SKILL.md"
  printf -- '---\nname: d\n---\n' > "$root/skills/.external/d/SKILL.md"
  printf -- '---\nname: e\n---\n' > "$root/skills/.external/e/SKILL.md"
  printf -- '---\nname: placeholder\n---\n' > "$root/agents/placeholder.md"
}

run_bootstrap_probe() {
  local spellbook="$1" project="$2"
  # SPELLBOOK_TEST_MODE=1 makes bootstrap.sh dump the post-filter state and
  # exit before touching any harness dirs.
  ( cd "$project" && \
      SPELLBOOK_TEST_MODE=1 \
      SPELLBOOK_DIR="$spellbook" \
      bash "$BOOTSTRAP" 2>&1 )
}

echo "test: no .spellbook.yaml → global behavior"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
make_fake_spellbook "$tmp/sb"
mkdir -p "$tmp/proj1"
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj1")
assert_contains "GLOBAL_SKILLS=a b c" "GLOBAL_SKILLS=a b c" "$out"
assert_contains "EXTERNAL_SKILLS=d e" "EXTERNAL_SKILLS=d e" "$out"
assert_contains "ALLOWLIST_ACTIVE=0" "ALLOWLIST_ACTIVE=0" "$out"

echo "test: valid allowlist → intersect with order preserved"
mkdir -p "$tmp/proj2"
cat > "$tmp/proj2/.spellbook.yaml" <<YAML
skills:
  - a
  - c
  - d
YAML
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj2")
assert_contains "GLOBAL_SKILLS=a c" "GLOBAL_SKILLS=a c" "$out"
assert_contains "EXTERNAL_SKILLS=d" "EXTERNAL_SKILLS=d" "$out"
assert_contains "ALLOWLIST_ACTIVE=1" "ALLOWLIST_ACTIVE=1" "$out"

echo "test: malformed .spellbook.yaml → warn + fall through to global"
mkdir -p "$tmp/proj3"
printf 'skills: [a, c\n  not-yaml:::' > "$tmp/proj3/.spellbook.yaml"
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj3")
assert_contains "global behavior GLOBAL_SKILLS=a b c" "GLOBAL_SKILLS=a b c" "$out"
assert_contains "global behavior EXTERNAL_SKILLS=d e" "EXTERNAL_SKILLS=d e" "$out"
assert_contains "global behavior ALLOWLIST_ACTIVE=0" "ALLOWLIST_ACTIVE=0" "$out"

echo "test: unknown skill name → warning + silently dropped"
mkdir -p "$tmp/proj4"
cat > "$tmp/proj4/.spellbook.yaml" <<YAML
skills:
  - a
  - zzz-does-not-exist
  - d
YAML
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj4")
assert_contains "unknown skill warning" "zzz-does-not-exist" "$out"
assert_contains "unknown dropped GLOBAL_SKILLS=a" "GLOBAL_SKILLS=a" "$out"
assert_contains "unknown dropped EXTERNAL_SKILLS=d" "EXTERNAL_SKILLS=d" "$out"
assert_contains "unknown dropped ALLOWLIST_ACTIVE=1" "ALLOWLIST_ACTIVE=1" "$out"

echo "test: empty skills list → allowlist active, both arrays empty"
mkdir -p "$tmp/proj5"
cat > "$tmp/proj5/.spellbook.yaml" <<YAML
skills: []
YAML
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj5")
assert_contains "empty list GLOBAL_SKILLS=" "GLOBAL_SKILLS=" "$out"
assert_contains "empty list EXTERNAL_SKILLS=" "EXTERNAL_SKILLS=" "$out"
assert_contains "empty list ALLOWLIST_ACTIVE=1" "ALLOWLIST_ACTIVE=1" "$out"
# Make sure the a/b/c skills did NOT leak through into GLOBAL_SKILLS.
if printf '%s' "$out" | grep -Eq 'GLOBAL_SKILLS=.*[abc]'; then
  printf '  FAIL empty list should not contain a/b/c\n    actual:\n%s\n' "$out"
  fail=1
  fails+=("empty list leaked skills")
else
  printf '  ok   empty list did not leak skills\n'
fi

echo "test: missing skills key → parse_fail, fall through to global"
mkdir -p "$tmp/proj6"
cat > "$tmp/proj6/.spellbook.yaml" <<YAML
# No skills: key at all, just another field.
some_other_key: hello
YAML
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj6")
assert_contains "missing key GLOBAL_SKILLS=a b c" "GLOBAL_SKILLS=a b c" "$out"
assert_contains "missing key EXTERNAL_SKILLS=d e" "EXTERNAL_SKILLS=d e" "$out"
assert_contains "missing key ALLOWLIST_ACTIVE=0" "ALLOWLIST_ACTIVE=0" "$out"

echo "test: null skills value → parse_fail, fall through to global"
mkdir -p "$tmp/proj7"
cat > "$tmp/proj7/.spellbook.yaml" <<YAML
skills:
YAML
out=$(run_bootstrap_probe "$tmp/sb" "$tmp/proj7")
assert_contains "null value GLOBAL_SKILLS=a b c" "GLOBAL_SKILLS=a b c" "$out"
assert_contains "null value ALLOWLIST_ACTIVE=0" "ALLOWLIST_ACTIVE=0" "$out"

echo
if [ "$fail" -eq 0 ]; then
  echo "all tests passed"
  exit 0
else
  printf '%d test(s) failed: %s\n' "${#fails[@]}" "${fails[*]}"
  exit 1
fi
