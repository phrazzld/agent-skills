# Changelog Audit

Deep analysis of existing release infrastructure.

## Configuration Audit
- semantic-release config valid? Required plugins present?
- commitlint config exists? Extends conventional?
- Lefthook commit-msg hook runs commitlint?

## GitHub Actions Audit
- Workflow file exists with `contents: write` permission?
- Has `fetch-depth: 0`?
- Synthesis job exists with API key reference?

## Secrets Audit
```bash
gh secret list | grep -q "GEMINI_API_KEY" || echo "MISSING"
```

## Public Page Audit
- Page exists at app/changelog? RSS feed exists? No auth wrapper?

## Release Health
```bash
gh release list --limit 5
```
Releases have bodies (LLM notes)? CHANGELOG.md in sync? Failed workflow runs?

## Commit History
```bash
git log --oneline -20 | while read line; do
  echo "$line" | grep -qE "^[a-f0-9]+ (feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: " || echo "NON-CONVENTIONAL: $line"
done
```

## Output
Structured report: CONFIGURATION, GITHUB ACTIONS, SECRETS, PUBLIC PAGE, RELEASE HEALTH, COMMIT HEALTH sections with pass/warn/fail counts.
