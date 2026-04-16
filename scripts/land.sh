#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"

# Escape hatch: skip verdict gate entirely
if [ "${SPELLBOOK_NO_REVIEW:-}" = "1" ]; then
  echo "land: SPELLBOOK_NO_REVIEW=1 — bypassing verdict gate" >&2
  git checkout master -q && git merge --no-ff "$branch" -q
  exit 0
fi

# shellcheck source=scripts/lib/verdicts.sh
source "$repo_root/scripts/lib/verdicts.sh"

if ! verdict_validate "$branch"; then
  echo "land: no valid verdict for '$branch'. Run /code-review first." >&2
  echo "  To bypass: SPELLBOOK_NO_REVIEW=1 scripts/land.sh $branch" >&2
  exit 2
fi

verdict_json="$(verdict_read "$branch")"
verdict_value="$(echo "$verdict_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['verdict'])")"

if [ "$verdict_value" = "dont-ship" ]; then
  echo "land: verdict is 'dont-ship' — cannot land '$branch'." >&2
  echo "  Address review findings, re-run /code-review, then retry." >&2
  exit 3
fi

# Dagger CI gate (optional — only when dagger.json exists and dagger is on PATH)
if [ -f "$repo_root/dagger.json" ] && command -v dagger &>/dev/null; then
  echo "land: running dagger call check..." >&2
  if ! (cd "$repo_root" && dagger call check); then
    echo "land: Dagger CI failed. Fix before landing." >&2
    exit 4
  fi
fi

git checkout master -q && git merge --no-ff "$branch" -q
