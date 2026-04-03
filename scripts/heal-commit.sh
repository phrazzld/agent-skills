#!/usr/bin/env bash
set -euo pipefail

touch .env
before_snapshot="$(mktemp -d)"
stage_plan="$(mktemp)"
cleanup() {
  rm -rf "$before_snapshot" "$stage_plan"
}
trap cleanup EXIT

rsync -a --delete --exclude '.git' --exclude '.env' ./ "$before_snapshot"/

check_output="$(DAGGER_NO_NAG="${DAGGER_NO_NAG:-1}" dagger call check 2>&1 || true)"
gate="$(python3 - <<'PY' "$check_output"
import re
import sys

text = sys.argv[1]
match = re.search(r"^\s*FAIL\s+([a-z0-9-]+)$", text, re.MULTILINE)
print(match.group(1) if match else "")
PY
)"

if [[ -z "$gate" ]]; then
  printf '%s\n' "$check_output"
  exit 0
fi

branch="$(python3 - <<'PY' "$gate"
import re
import sys
from datetime import UTC, datetime

gate = sys.argv[1]
slug = re.sub(r"[^a-z0-9]+", "-", gate.lower()).strip("-")
print(f"heal/{slug}-{datetime.now(UTC).strftime('%Y%m%d%H%M%S')}")
PY
)"

DAGGER_NO_NAG="${DAGGER_NO_NAG:-1}" dagger call --allow-llm all -o . heal "$@"
DAGGER_NO_NAG="${DAGGER_NO_NAG:-1}" dagger call check >/dev/null
git switch -c "$branch"

PYTHONPATH="ci/src${PYTHONPATH:+:${PYTHONPATH}}" python3 - <<'PY' "$before_snapshot" > "$stage_plan"
from pathlib import Path
import sys

from spellbook_ci.heal_support import snapshot_delta

before = Path(sys.argv[1])
after = Path(".")
stage, remove = snapshot_delta(before, after)

for path in remove:
    print(f"D\t{path}")
for path in stage:
    print(f"S\t{path}")
PY

while IFS=$'\t' read -r action path; do
  [[ -n "${action:-}" ]] || continue
  case "$action" in
    D) git rm --quiet --ignore-unmatch -- "$path" ;;
    S) git add -- "$path" ;;
    *) printf 'unknown stage action: %s\n' "$action" >&2; exit 1 ;;
  esac
done < "$stage_plan"

if git diff --cached --quiet; then
  printf 'heal produced no commit-ready diff\n' >&2
  exit 1
fi

git commit -m "ci: heal $gate"
printf 'Healed %s on %s\n' "$gate" "$branch"
