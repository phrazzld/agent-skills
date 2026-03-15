---
name: next-patterns
description: |
  Next.js patterns, best practices, cache components, and upgrade guides.
  Auto-invoke when: writing Next.js code, configuring next.config, using App Router,
  implementing caching, upgrading Next.js versions.
  Keywords: Next.js, App Router, RSC, use cache, PPR, cacheLife, cacheTag, metadata,
  route handlers, middleware, Suspense, hydration
user-invocable: false
---

# Next.js Patterns

Comprehensive Next.js reference. Auto-loaded when working with Next.js code.

## Best Practices

See [references/best-practices.md](./references/best-practices.md) for:
- File conventions and route segments
- RSC boundaries and async patterns
- Runtime selection and directives
- Error handling, data patterns, route handlers
- Metadata, image/font optimization, bundling
- Hydration errors, Suspense boundaries
- Parallel and intercepting routes
- Self-hosting and debug tricks

Detailed sub-references in `references/`:
- `file-conventions.md`, `rsc-boundaries.md`, `async-patterns.md`
- `runtime-selection.md`, `directives.md`, `functions.md`
- `error-handling.md`, `data-patterns.md`, `route-handlers.md`
- `metadata.md`, `image.md`, `font.md`, `bundling.md`, `scripts.md`
- `hydration-error.md`, `suspense-boundaries.md`
- `parallel-routes.md`, `self-hosting.md`, `debug-tricks.md`

## Cache Components (Next.js 16+)

See [references/cache-components.md](./references/cache-components.md) for:
- PPR (Partial Prerendering) setup
- `use cache` directive (file/component/function level)
- Cache profiles: `cacheLife()` with built-in and custom lifetimes
- Cache invalidation: `cacheTag()`, `updateTag()`, `revalidateTag()`
- Runtime data constraints and `use cache: private`
- Cache key generation
- Migration from previous versions

## Upgrading

See [references/upgrade.md](./references/upgrade.md) for:
- Version detection and upgrade path planning
- Running codemods (`npx @next/codemod@latest`)
- Dependency updates and breaking changes
- TypeScript type updates
