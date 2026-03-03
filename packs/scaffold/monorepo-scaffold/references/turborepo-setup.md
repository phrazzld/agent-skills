# Turborepo + pnpm Setup (2026)

This is the minimal, production-safe baseline. Start here. Add complexity only when forced.

## 1) pnpm Workspace Configuration

Create `pnpm-workspace.yaml` at repo root:

```yaml
packages:
  - apps/*
  - packages/*
```

Root `package.json` should be private and script-driven:

```json
{
  "name": "repo",
  "private": true,
  "packageManager": "pnpm@10",
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev --parallel",
    "lint": "turbo run lint",
    "test": "turbo run test --continue",
    "typecheck": "turbo run typecheck"
  },
  "devDependencies": {
    "turbo": "^2.0.0"
  }
}
```

## 2) turbo.json Pipeline Configuration

Keep the pipeline small and explicit. Cache only what is stable.

Create `turbo.json`:

```json
{
  "$schema": "https://turborepo.com/schema.json",
  "globalDependencies": [
    "pnpm-lock.yaml",
    "turbo.json",
    "package.json"
  ],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", ".env*", "tsconfig*.json"],
      "outputs": [
        "dist/**",
        "build/**",
        ".next/**",
        "storybook-static/**",
        "coverage/**"
      ]
    },
    "typecheck": {
      "dependsOn": ["^typecheck"],
      "inputs": ["$TURBO_DEFAULT$", "tsconfig*.json"],
      "outputs": []
    },
    "lint": {
      "dependsOn": ["^lint"],
      "outputs": []
    },
    "test": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", ".env.test*", "vitest.config.*", "jest.config.*"],
      "outputs": ["coverage/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

Notes:
- Add or remove outputs per framework. Wrong outputs silently kill cache value.
- Include env files only when they change behavior.

## 3) Package References and Dependencies

Use workspace ranges. Avoid implicit cross-package imports.

Example `apps/web/package.json`:

```json
{
  "name": "@apps/web",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "lint": "next lint",
    "typecheck": "tsc -p tsconfig.json --noEmit"
  },
  "dependencies": {
    "@packages/shared": "workspace:*",
    "@packages/ui-web": "workspace:*"
  }
}
```

Example `packages/shared/package.json`:

```json
{
  "name": "@packages/shared",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "lint": "eslint .",
    "test": "vitest run",
    "typecheck": "tsc -p tsconfig.json --noEmit"
  },
  "devDependencies": {
    "@packages/config": "workspace:*"
  }
}
```

Rules that prevent pain:
- Prefer `@apps/*` and `@packages/*` naming for clarity.
- Use `workspace:*` for internal deps, not semver.
- Ensure shared packages export from a single public entrypoint.

## 4) Build Caching Strategy

Cache build outputs. Do not cache dev servers. Be strict with inputs.

Baseline strategy:
- Cache `build`, `lint`, `test`, `typecheck`
- Disable cache for `dev`
- Declare real outputs for each tool
- Keep task inputs stable and explicit
- Use `dependsOn: ["^build"]` for tests that require compiled artifacts

Remote cache:
- Enable Turborepo remote cache in CI for large repos.
- Fail open if remote cache unavailable. Do not block merges on cache health.

## 5) CI/CD Integration

CI should run from repo root and use the same commands as local dev.

Typical CI steps:

```bash
pnpm install --frozen-lockfile
pnpm turbo run lint typecheck test build
```

Recommended guardrails:
- Run with `--filter` on deploy jobs to avoid building unrelated apps
- Pin Node and pnpm versions in CI
- Store `pnpm` cache between runs
- Use Turbo remote cache token in CI secrets if available

Example deploy filter:

```bash
pnpm turbo run build --filter=@apps/web
```

## Suggested Migration Order

When converting a single app:

1. Move app to `apps/<name>/`.
2. Make it build from root using Turbo filters.
3. Extract shared code into `packages/shared/`.
4. Extract shared config into `packages/config/`.
5. Tighten pipeline inputs/outputs for cache quality.

