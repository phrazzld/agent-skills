#!/usr/bin/env bash
# tailor-lint.sh — pre-commit enforcement for /tailor MVP.
#
# Two checks on .claude/skills/ in the target repo:
#   1. Shadow check — no skill directory may use a name that is a
#      load-bearing spellbook workflow primitive (groom, shape, deliver,
#      flywheel, code-review, settle, reflect, tailor, harness). These
#      names are what orchestrators dispatch to; shadowing breaks the
#      cross-harness contract.
#   2. Cap check — .claude/skills/ must hold ≤ 2 entries with SKILL.md.
#      Enforces the MVP "bounded specialization" ceiling; v2 relaxes
#      the cap once the overlay mechanism lands.
#
# Install as pre-commit in a target repo:
#   ln -sf "$(spellbook_root)/scripts/tailor-lint.sh" .git/hooks/pre-commit
#
# Invoke manually:
#   scripts/tailor-lint.sh [target_repo_root]   # default: $PWD
#
# Exit codes:
#   0 — lint passes (or .claude/skills/ absent / empty)
#   1 — lint fails (shadow name or cap exceeded)
#   2 — usage error

set -euo pipefail

TARGET_ROOT="${1:-$PWD}"
SKILLS_DIR="$TARGET_ROOT/.claude/skills"

# Load-bearing spellbook workflow primitives. Shadowing any of these
# breaks the cross-harness contract because these names are what
# /deliver, /flywheel, /settle, etc. dispatch to. Keep in lockstep
# with the canonical list in backlog.d/029-tailor-per-repo-harness-generator.md.
SHADOW_NAMES=(
  groom shape deliver flywheel code-review
  settle reflect tailor harness
)

SKILL_CAP=2

if [ ! -d "$TARGET_ROOT" ]; then
  printf 'tailor-lint: target root does not exist: %s\n' "$TARGET_ROOT" >&2
  exit 2
fi

# No skills dir → nothing to lint. The common case: repos that haven't
# run /tailor yet, or whose tailoring only touched AGENTS.md / settings.
[ -d "$SKILLS_DIR" ] || exit 0

fail=0
count=0
shadows=()
skill_names=()

for entry in "$SKILLS_DIR"/*/; do
  [ -d "$entry" ] || continue
  [ -f "$entry/SKILL.md" ] || continue

  name=$(basename "$entry")
  count=$((count + 1))
  skill_names+=("$name")

  for forbidden in "${SHADOW_NAMES[@]}"; do
    if [ "$name" = "$forbidden" ]; then
      shadows+=("$name")
      break
    fi
  done
done

if [ "${#shadows[@]}" -gt 0 ]; then
  printf 'tailor-lint: forbidden shadow of global workflow skill(s): %s\n' "${shadows[*]}" >&2
  printf 'tailor-lint: these names are load-bearing spellbook primitives.\n' >&2
  printf 'tailor-lint: v2 introduces overlays as the sanctioned specialization mechanism.\n' >&2
  fail=1
fi

if [ "$count" -gt "$SKILL_CAP" ]; then
  printf 'tailor-lint: .claude/skills/ has %d skills (%s); MVP cap is %d.\n' \
    "$count" "${skill_names[*]}" "$SKILL_CAP" >&2
  fail=1
fi

exit "$fail"
