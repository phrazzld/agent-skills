# Performance Patterns

## CI-Specific Configuration

```typescript
export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,    // Predictable, lower memory
      },
    },
    isolate: false,          // Skip VM recreation between tests
    watch: false,            // Explicit for CI clarity
    reporters: ['verbose'],  // Full output for debugging
    coverage: {
      reportOnFailure: true, // Get coverage even on failure
    },
  },
})
```

## Test Isolation Trade-offs

| Setting | Speed | Safety | Use When |
|---------|-------|--------|----------|
| `isolate: true` | Slower | High | Tests modify globals, env vars |
| `isolate: false` | Faster | Lower | Pure functions, no side effects |
| `singleFork: true` | Slower | Highest | CI, debugging, flaky tests |
| `singleFork: false` | Faster | Lower | Local dev, parallel execution |

## Environment Selection

| Environment | Speed | Features | Use For |
|-------------|-------|----------|---------|
| `node` | Fastest | No DOM | API routes, utils, services |
| `happy-dom` | Fast | Basic DOM | Components without full browser |
| `jsdom` | Slow | Full DOM | Complex DOM interactions |

```typescript
// Per-file environment override
// @vitest-environment happy-dom
```

## Sharding for Parallel CI

```yaml
# GitHub Actions matrix
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - run: pnpm test --shard=${{ matrix.shard }}/4
```

```typescript
// vitest.config.ts (optional shard config)
export default defineConfig({
  test: {
    sequence: {
      shuffle: true, // Distribute tests evenly across shards
    },
  },
})
```

## Cache Optimization

```typescript
export default defineConfig({
  test: {
    cache: {
      dir: 'node_modules/.vitest', // Default, customize if needed
    },
    deps: {
      optimizer: {
        web: {
          include: ['@testing-library/*'], // Pre-bundle heavy deps
        },
      },
    },
  },
})
```

## Startup Optimization

```typescript
export default defineConfig({
  test: {
    // Inline large deps that slow down worker startup
    deps: {
      inline: ['@some/large-package'],
    },
    // Skip type checking in tests (use separate typecheck)
    typecheck: {
      enabled: false,
    },
  },
})
```

## Profiling Slow Tests

```bash
# Find slowest tests
vitest --reporter=verbose --reporter=json --outputFile=results.json

# Profile test execution
vitest --inspect-brk --single-thread
```
