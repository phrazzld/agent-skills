# /check-quality

Audit quality infrastructure. Fix gaps. Verify everything works.

## What This Does

1. Audit testing infrastructure (Vitest, Jest, coverage)
2. Audit git hooks (Lefthook, Husky)
3. Audit CI/CD (GitHub Actions, branch protection)
4. Audit linting/formatting (ESLint, Prettier, Biome)
5. Audit custom guardrails (architecture, design tokens, import boundaries)
6. Security scan via `security-sentinel` agent
7. Audit branch-protection/security baseline (required checks, conversation resolution, secret scanning)
8. Fix identified gaps (install tools, create configs, set up CI)
9. Verify fixes work end-to-end

**This is both audit AND setup.** It checks what exists, fixes what's missing, and proves it works.

## Process

### 1. Audit

Run quick infrastructure assessment:

```bash
# Test runner
[ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] && echo "V Vitest" || echo "X Vitest"
[ -f "jest.config.ts" ] || [ -f "jest.config.js" ] && echo "V Jest (prefer Vitest)" || echo "- Jest"

# Coverage
grep -q "coverage" package.json 2>/dev/null && echo "V Coverage script" || echo "X Coverage script"
grep -q "@vitest/coverage" package.json 2>/dev/null && echo "V Coverage plugin" || echo "X Coverage plugin"

# Git hooks
[ -f "lefthook.yml" ] && echo "V Lefthook" || echo "X Lefthook (recommended)"
[ -f ".git/hooks/pre-commit" ] && echo "V pre-commit hook" || echo "X pre-commit hook"
[ -f ".git/hooks/pre-push" ] && echo "V pre-push hook" || echo "X pre-push hook"

# CI/CD
[ -f ".github/workflows/ci.yml" ] || [ -f ".github/workflows/test.yml" ] && echo "V CI workflow" || echo "X CI workflow"
grep -rq "vitest-coverage-report" .github/workflows/ 2>/dev/null && echo "V Coverage in PRs" || echo "X Coverage in PRs"

# Baseline policy checks (set OWNER/REPO/BRANCH before running)
PROTECTION_JSON="$(gh api "/repos/${OWNER}/${REPO}/branches/${BRANCH}/protection" 2>/dev/null || true)"
if [ -z "$PROTECTION_JSON" ]; then
  echo "X Branch protection unavailable (missing protection or insufficient token permissions)"
else
  echo "$PROTECTION_JSON" | jq -r '
    if (((.required_status_checks.contexts // []) | length) > 0 or ((.required_status_checks.checks // []) | length) > 0) then "V Required checks" else "X Required checks" end,
    if (.required_pull_request_reviews.required_approving_review_count == 0 or .required_pull_request_reviews.required_approving_review_count == null) then "V No required human approvals" else "X Human approvals required" end,
    if .required_conversation_resolution.enabled then "V Conversation resolution required" else "X Conversation resolution not required" end
  '
fi
rg -n "(trufflehog|gitleaks|ggshield|secret[[:space:]_-]?scann(ing|er))" .github/workflows -S >/dev/null 2>&1 && echo "V Secret scan workflow" || echo "X Secret scan workflow"

# Linting
[ -f "eslint.config.js" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] && echo "V ESLint" || echo "X ESLint"
[ -f "biome.json" ] && echo "V Biome" || echo "- Biome"
[ -f "tsconfig.json" ] && echo "V TypeScript" || echo "X TypeScript"
grep -q '"strict": true' tsconfig.json 2>/dev/null && echo "V Strict mode" || echo "X Strict mode"

# Commit standards
[ -f "commitlint.config.js" ] || [ -f "commitlint.config.cjs" ] && echo "V Commitlint" || echo "X Commitlint"

# Custom guardrails
[ -d "guardrails" ] && echo "V guardrails/" || echo "- No custom guardrails"

# Design tokens (heuristic only; confirm by reading the theme files)
rg -n "(@theme|--(color|space|spacing|radius|font|shadow)-|tailwind\\.config|globals\\.css|app\\.css|tokens\\.(ts|js|json)|theme\\.(ts|js)|components/ui|src/components/ui)" . -g '!node_modules' >/dev/null 2>&1 && echo "V Design system detected (heuristic)" || echo "- No obvious design system"
rg -n "(guardrails/.+(token|theme|color|spacing|radius)|no-raw-(color|hex|spacing|radius)|semantic-token|token-(usage|enforce)|design-token)" . -g '!node_modules' >/dev/null 2>&1 && echo "V Token guardrails (heuristic)" || echo "- No token guardrails"

# Module size (Ousterhout deep module awareness)
echo "--- Module Size ---"
for f in $(find . -name '*.ex' -o -name '*.go' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' | grep -v node_modules | grep -v _build | grep -v deps); do
  lines=$(wc -l < "$f")
  [ "$lines" -gt 500 ] && echo "! $f: ${lines} LOC (review candidate)"
done
echo "---"
```

Spawn `security-sentinel` agent for vulnerability analysis.

### 2. Plan

Prioritize findings:

| Gap | Priority |
|-----|----------|
| No test runner | P0 |
| No CI workflow | P0 |
| Security vulnerabilities | P0 |
| Missing required checks on protected branch | P0 |
| Conversation resolution disabled | P0 |
| No coverage | P1 |
| No git hooks | P1 |
| No pre-commit fast feedback | P1 |
| No linting | P1 |
| Not strict TypeScript | P1 |
| No commitlint | P2 |
| No coverage in PRs | P2 |
| No custom guardrails | P2 |
| Design system without token guardrails | P2 |
| Module >500 LOC without deep-module justification | P2 |
| Tool upgrades | P3 |

### 3. Fix

Fix every gap. Delegate to Codex where appropriate.

**Lefthook:** `pnpm add -D lefthook && pnpm lefthook install` + create `lefthook.yml` per `references/lefthook-config.md`

Pre-commit should stay fast: lint, formatting, type/lint on changed files, custom guardrails.
Push/CI should carry slower gates: full test suite, coverage, e2e.

**Vitest:** `pnpm add -D vitest @vitest/coverage-v8` + config per `references/vitest-config.md`

**CI:** Create `.github/workflows/ci.yml` per `references/github-actions.md`

**Commitlint:** `pnpm add -D @commitlint/cli @commitlint/config-conventional` + add commit-msg hook

**Branch protection:** Guide user through GitHub settings or use `gh api`

### 4. Verify

Prove it works -- don't just check files exist:

```bash
pnpm lefthook run pre-commit          # Hooks work
pnpm eslint .                         # Lint + local guardrails work
sg scan --config guardrails/sgconfig.yml  # If ast-grep guardrails exist
pnpm test --run                        # Tests run
echo "bad message" | pnpm commitlint   # Should fail
echo "feat: valid" | pnpm commitlint   # Should pass
```

## Tool Choices

**Lefthook > Husky.** Go binary, faster, parallel, simpler YAML.
**Vitest > Jest.** Faster, native ESM, built-in coverage.
**vitest-coverage-report-action > Codecov.** Zero external service.

Don't churn working alternatives. Improve what exists.

## Coverage Philosophy

Coverage is diagnostic, not a goal. 60% meaningful > 95% testing implementation details. NEVER lower a coverage threshold to pass CI -- write more tests instead.

## Anti-Patterns

- NEVER lower quality gates to pass CI (coverage, lint, type strictness)
- Don't skip hooks routinely -- fix root cause
- Don't test implementation details -- test behavior
- Don't rely on heavy mocking -- prefer integration tests
- Don't put slow, flaky suites in pre-commit
- Don't trust regex heuristics alone for design systems -- read the token files
- Don't ship a design system with unenforced raw color/magic spacing drift
- CI on every PR, not just main

## Output Format

```markdown
## Quality Gates Audit

### P0: Critical (Must Have)
- [findings]

### P1: Essential (Every Project)
- [findings]

### P2: Important (Production Apps)
- [findings]

### P3: Nice to Have
- [findings]

## Current Status
- Test runner: [status]
- Coverage: [status]
- Git hooks: [status]
- CI/CD: [status]
- Linting: [status]
- Security: [status]

## Summary
- P0: N | P1: N | P2: N | P3: N
```

## References

- `references/module-size-guidance.md` -- LOC thresholds and Ousterhout deep module distinction
- `references/lefthook-config.md` -- Hook configurations
- `references/github-actions.md` -- CI workflows
- `references/vitest-config.md` -- Test configuration
- `references/branch-protection.md` -- GitHub settings
- `references/testing-standards.md` -- Testing standards
- `references/quality-gates-philosophy.md` -- Quality gate standards

## Related

- `/log-quality-issues` -- Create GitHub issues from findings
- `/fix-quality` -- Fix quality infrastructure
- `/test-coverage` -- Deep test audit with coverage analysis
- `/ci-spend-optimizer` -- Reduce CI minute burn and AI reviewer overlap
- `/org-quality-governance` -- Enforce organization/repo quality policy
