# Monorepo Migration Checklist

Use this to prevent silent breakage. Check boxes in order.

## Pre-Migration Audit

- Identify deploy entrypoints and their expected working directories
- List all root scripts and which environments run them
- Capture current build outputs and artifact paths
- Note Node, pnpm, and framework versions
- Audit path aliases (`tsconfig`, bundler config, Jest/Vitest, ESLint)
- Find implicit relative imports that will break after moving folders
- Confirm test, lint, and typecheck run clean before moving anything

## Migration Steps + Verification

1. Create `apps/` and `packages/`.
Verification: repo still installs and root scripts still run.
2. Move the single app into `apps/<name>/`.
Verification: run its dev/build commands from its new directory.
3. Add `pnpm-workspace.yaml`.
Verification: `pnpm -w install` completes and links workspaces.
4. Add `turbo.json` and root scripts.
Verification: `pnpm build` works from repo root.
5. Convert internal imports to workspace packages.
Verification: no cross-app relative imports remain.
6. Extract shared code to `packages/shared`.
Verification: app compiles using only public package entrypoints.
7. Extract shared config to `packages/config`.
Verification: all apps/packages reference config via dependencies.
8. Tighten `turbo.json` inputs/outputs.
Verification: repeated runs show cache hits.

## Post-Migration Validation

- From a clean checkout, run:

```bash
pnpm install --frozen-lockfile
pnpm turbo run lint typecheck test build
```

- Verify each deployable target independently:

```bash
pnpm turbo run build --filter=@apps/web
pnpm turbo run build --filter=@apps/api
```

- Confirm editor tooling works
- TypeScript project references or path aliases resolve
- ESLint and test runners find the new roots
- CI uses root commands, not stale per-app paths

## Common Pitfalls

- Hidden root-relative imports like `src/...` that break after moving
- Missing or wrong `outputs` in `turbo.json`, leading to zero cache value
- Packages importing other packages’ internals instead of public exports
- CI running inside `apps/<name>` while expecting root workspace behavior
- Duplicate tool configs drifting between apps instead of centralizing
- Workspace deps declared with semver ranges instead of `workspace:*`
