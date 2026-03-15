# Fix Quality

Fix the highest priority quality infrastructure gap.

## What This Does

1. Invoke `/check-quality` to audit quality gates
2. Identify highest priority gap
3. Fix that one issue
4. Verify the fix
5. Report what was done

**This is a fixer.** It fixes one issue at a time. Run again for next issue. Use `/quality-gates` for full setup.

## Fix Priority Order

1. **P0**: Missing test runner, missing CI workflow
2. **P1**: Coverage, git hooks, linting, strict TypeScript
3. **P2**: Commitlint, coverage in PRs
4. **P3**: Tool upgrades

## Fix Templates

**No test runner (P0):**
```bash
pnpm add -D vitest @vitest/coverage-v8
```

Create `vitest.config.ts`:
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
});
```

Add scripts to package.json:
```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "coverage": "vitest run --coverage"
  }
}
```

**No CI workflow (P0):**
Create `.github/workflows/ci.yml`:
```yaml
name: CI
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test:run
```

**No git hooks (P1):**
```bash
pnpm add -D lefthook
pnpm lefthook install
```

Create `lefthook.yml`:
```yaml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{ts,tsx}"
      run: pnpm eslint {staged_files}
    typecheck:
      run: pnpm tsc --noEmit

pre-push:
  commands:
    test:
      run: pnpm test:run
```

**TypeScript not strict (P1):**
Update `tsconfig.json`:
```json
{
  "compilerOptions": {
    "strict": true
  }
}
```

## Verification

After fix:
```bash
# Test runner works
pnpm test --run

# Hooks installed
[ -f ".git/hooks/pre-commit" ] && echo "pre-commit hook installed"

# CI file exists
[ -f ".github/workflows/ci.yml" ] && echo "CI workflow exists"
```

## Report Format

```
Fixed: [P0] No test runner configured

Installed:
- vitest
- @vitest/coverage-v8

Created:
- vitest.config.ts
- Added test scripts to package.json

Verified: pnpm test runs successfully

Next highest priority: [P0] No CI workflow
Run /fix-quality again to continue.
```

## Branching

Before making changes:
```bash
git checkout -b infra/quality-$(date +%Y%m%d)
```

## Single-Issue Focus

This fixes **one issue at a time**. Benefits:
- Small, reviewable changes
- Easy to verify each fix
- Clear commit history

Run `/fix-quality` repeatedly to work through the backlog.
