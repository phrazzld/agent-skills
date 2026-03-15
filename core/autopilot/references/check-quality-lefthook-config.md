# Lefthook Configuration

## Installation

```bash
# Install via package manager
pnpm add -D lefthook
# or npm install -D lefthook
# or brew install lefthook (global)

# Initialize
pnpm lefthook install
```

## Basic Setup (Next.js/TypeScript)

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{js,ts,jsx,tsx}"
      run: pnpm eslint --fix {staged_files}
      stage_fixed: true

    format:
      glob: "*.{js,ts,jsx,tsx,json,md,css}"
      run: pnpm prettier --write {staged_files}
      stage_fixed: true

    typecheck:
      glob: "*.{ts,tsx}"
      run: pnpm tsc --noEmit

pre-push:
  commands:
    test:
      run: pnpm test:ci

    build:
      run: pnpm build

commit-msg:
  commands:
    commitlint:
      run: pnpm commitlint --edit {1}
```

## Monorepo Configuration

```yaml
pre-commit:
  parallel: true
  commands:
    lint-web:
      glob: "apps/web/**/*.{ts,tsx}"
      run: pnpm --filter web lint --fix {staged_files}
      root: apps/web/
      stage_fixed: true

    lint-api:
      glob: "apps/api/**/*.ts"
      run: pnpm --filter api lint --fix {staged_files}
      root: apps/api/
      stage_fixed: true

    lint-shared:
      glob: "packages/**/*.{ts,tsx}"
      run: pnpm --filter @repo/* lint --fix {staged_files}
      stage_fixed: true

    format:
      glob: "**/*.{js,ts,jsx,tsx,json,md}"
      run: pnpm prettier --write {staged_files}
      stage_fixed: true

pre-push:
  commands:
    test-changed:
      run: pnpm turbo run test --filter=[HEAD^1]

    typecheck:
      run: pnpm turbo run typecheck

    build:
      run: pnpm turbo run build
```

## Convex-Specific Hooks

```yaml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{js,ts,jsx,tsx}"
      run: pnpm eslint --fix {staged_files}
      stage_fixed: true

    convex-typecheck:
      glob: "convex/**/*.ts"
      run: pnpm tsc --noEmit --project convex/tsconfig.json

    convex-schema:
      glob: "convex/schema.ts"
      run: pnpm convex dev --once --run convex/validateSchema.ts

pre-push:
  commands:
    test:
      run: pnpm test:ci

    convex-preview:
      run: |
        pnpm convex deploy --preview-name ci-$(git rev-parse --short HEAD)
```

## Skip Hooks (Emergency Only)

```bash
# Skip pre-commit
git commit --no-verify -m "emergency fix"

# Skip pre-push
git push --no-verify

# Skip specific command
LEFTHOOK_EXCLUDE=test git push
```
