#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

declare -a failures=()

fail() {
  failures+=("$1")
}

matches() {
  local pattern="$1"
  shift
  grep -nE "$pattern" "$@" >/dev/null
}

if matches 'into \.claude/ with no filtering or tailoring' \
  skills/seed/SKILL.md index.yaml; then
  fail "seed must not describe repo installs as Claude-only"
fi

if matches 'per-repo set of skills and agents in \.claude/' \
  skills/tailor/SKILL.md index.yaml; then
  fail "tailor must not describe repo installs as Claude-only"
fi

if matches 'Copy every skill in .+ into `?\.claude/skills/' \
  skills/seed/SKILL.md; then
  fail "seed must install into a shared skill root, not copy skills directly into .claude/skills/"
fi

if ! matches 'shared skill root|shared repo-local skill layer|shared skill layer' \
  skills/seed/SKILL.md; then
  fail "seed must name the shared skill root as the canonical install target"
fi

if ! matches 'shared skill root|shared repo-local skill layer|shared skill layer' \
  skills/tailor/SKILL.md; then
  fail "tailor must name the shared skill root as the canonical install target"
fi

if ! matches '\.claude/skills/.+symlink|\.claude/skills/.+bridge|bridge layer' \
  skills/seed/SKILL.md skills/tailor/SKILL.md; then
  fail "seed/tailor must describe .claude/skills as a bridge, not the source of truth"
fi

if [ "${#failures[@]}" -gt 0 ]; then
  echo "harness install path check failed:" >&2
  for failure in "${failures[@]}"; do
    echo "  - $failure" >&2
  done
  exit 1
fi

echo "harness install paths are shared-root first."
