#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"

resolve_target_branch() {
  local remote_head

  remote_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$remote_head" ]; then
    printf '%s\n' "${remote_head#origin/}"
    return 0
  fi

  local candidate
  for candidate in main master trunk; do
    if git show-ref --verify --quiet "refs/heads/$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "land: cannot determine target branch" >&2
  return 1
}

run_dagger_check() {
  # Dagger CI gate (optional — only when dagger.json exists and dagger is on PATH)
  if [ -f "$repo_root/dagger.json" ] && command -v dagger &>/dev/null; then
    echo "land: running dagger call check..." >&2
    if ! (cd "$repo_root" && dagger call check); then
      echo "land: Dagger CI failed. Fix before landing." >&2
      return 1
    fi
  fi
}

# shellcheck source=scripts/lib/verdicts.sh
source "$repo_root/scripts/lib/verdicts.sh"

target_branch="$(resolve_target_branch)" || exit 5

if [ "${SPELLBOOK_NO_REVIEW:-}" = "1" ]; then
  echo "land: SPELLBOOK_NO_REVIEW=1 — bypassing verdict gate" >&2
else
  rc=0
  verdict_check_landable "$branch" || rc=$?
  if [ "$rc" -eq 1 ]; then
    echo "land: no valid verdict for '$branch'. Run /code-review first." >&2
    echo "  To bypass: SPELLBOOK_NO_REVIEW=1 scripts/land.sh \"$branch\"" >&2
    exit 2
  elif [ "$rc" -eq 2 ]; then
    echo "land: verdict is 'dont-ship' — cannot land '$branch'." >&2
    echo "  Address review findings, re-run /code-review, then retry." >&2
    exit 3
  fi
fi

run_dagger_check || exit 4

git checkout "$target_branch" -q && git merge --no-ff "$branch" -q
