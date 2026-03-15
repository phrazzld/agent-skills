# GitHub Actions Workflows

## Permissions Gotcha

**When you set explicit `permissions:`, GitHub disables all implicit defaults.**

```yaml
# BROKEN - checkout will fail (no contents:read)
permissions:
  id-token: write

# CORRECT - explicitly include what you need
permissions:
  contents: read    # Required for actions/checkout
  id-token: write   # Required for OIDC (PyPI trusted publishing, etc.)
```

Common permissions needed:
- `contents: read` - clone repo (`actions/checkout`)
- `contents: write` - push commits, create releases
- `pull-requests: write` - comment on PRs, update status
- `id-token: write` - OIDC authentication (PyPI, cloud providers)
- `packages: write` - publish to GitHub Packages

**Rule:** If you add any `permissions:` block, you must explicitly list everything you need.

## Basic CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  quality-checks:
    name: Quality Checks
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test:ci

      - uses: codecov/codecov-action@v4
        with:
          files: ./coverage/coverage-final.json
          fail_ci_if_error: false

      - run: pnpm build

      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: .next/
          retention-days: 7
```

## Matrix Testing + E2E

```yaml
# .github/workflows/comprehensive-ci.yml
name: Comprehensive CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test-matrix:
    name: Test (Node ${{ matrix.node-version }})
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [20, 22]

    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm test:ci
      - run: pnpm build

  e2e:
    name: E2E Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm playwright install --with-deps chromium
      - run: pnpm build
      - run: pnpm test:e2e
        env:
          PLAYWRIGHT_BROWSERS_PATH: 0
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm audit --audit-level=moderate
      - run: pnpm dlx @socketsecurity/cli audit
```

## Convex CI

```yaml
# .github/workflows/convex-ci.yml
name: Convex CI

on:
  pull_request:
    branches: [main]
    paths:
      - 'convex/**'
      - 'src/**'

jobs:
  convex-validate:
    name: Validate Convex Functions
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm tsc --noEmit --project convex/tsconfig.json
      - run: pnpm convex deploy --preview-name pr-${{ github.event.pull_request.number }}
        env:
          CONVEX_DEPLOY_KEY: ${{ secrets.CONVEX_DEPLOY_KEY }}
      - run: pnpm test:convex
      - uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Convex preview: https://dashboard.convex.dev/t/pr-${{ github.event.pull_request.number }}`
            })
```

## Coverage Report Action

```yaml
- uses: davelosert/vitest-coverage-report-action@v2
  permissions:
    contents: write
    pull-requests: write
  with:
    file-coverage-mode: changes
```

## PR Size Labeler

```yaml
- uses: CodelyTV/pr-size-labeler@v1
  with:
    xs_max_size: '50'
    s_max_size: '150'
    m_max_size: '300'
    l_max_size: '500'
    fail_if_xl: 'true'
    message_if_xl: 'PR exceeds 500 lines. Please split into smaller PRs.'
```
