# Pool Configuration

## Pool Types

| Pool | Mechanism | Isolation | Speed | Memory |
|------|-----------|-----------|-------|--------|
| `threads` | Worker threads | Shared memory | Fast | Low |
| `forks` | Child processes | Full process | Medium | Higher |
| `vmThreads` | VM contexts in threads | VM-level | Fast | Configurable |

## Node 22+ Recommendation

**Use `pool: 'forks'`** on Node 22+. Worker threads have known issues with native `fetch` and other Node 22 APIs.

```typescript
export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: {
      forks: {
        maxForks: 4,       // Limit parallel processes
        singleFork: false, // true for CI single-worker mode
      },
    },
  },
})
```

## Pool Options Clarification

- `maxForks` - for `pool: 'forks'`
- `maxWorkers` - for `pool: 'threads'` (legacy, still works)
- `vmMemoryLimit` - for `pool: 'vmThreads'` only

```typescript
// vmThreads with memory limit
poolOptions: {
  vmThreads: {
    memoryLimit: '512MB',
  },
}
```

## Debugging Pool Issues

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| `fetch is not defined` on Node 22 | threads pool | Switch to `forks` |
| Tests pass alone, fail together | State leaking | Enable `isolate: true` |
| OOM in CI | Too many workers | Use `singleFork: true` |
| Slow test startup | Process overhead | Try `threads` (if Node <22) |
| Inconsistent failures | Race conditions | Add `--sequence` flag |

## CI-Specific Configuration

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: process.env.CI === 'true',
      },
    },
  },
})
```

Single fork in CI:
- Predictable execution order
- Lower memory overhead
- Easier to debug failures
- No parallel flakiness
