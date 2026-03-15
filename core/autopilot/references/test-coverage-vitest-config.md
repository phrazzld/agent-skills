# Vitest Configuration

Absorbed from the `vitest` skill.

## Critical Rules

1. **Node 22+**: Use `pool: 'forks'` -- threads have known issues
2. **CI optimization**: Single worker, disable watch, `isolate: false` if safe
3. **Coverage**: Always define `coverage.include` -- defaults exclude too much
4. **Mocking**: Prefer `vi.spyOn` over `vi.mock` -- avoids hoisting footguns
5. **RTL cleanup**: Requires `globals: true` in config

## Memory Safety (MANDATORY)

| Rule | Why |
|------|-----|
| `"test"` script MUST be `vitest run` | Bare `vitest` = watch mode = persistent process |
| CI subprocesses: `env={..., "CI": "true"}` | Belt-and-suspenders against watch mode |
| Pool: `forks`, `maxForks: 4` on <=36 GB | Caps memory at ~2 GB total |
| Never `vitest --watch` from automated contexts | Zombies accumulate |
| Never delegate >3 parallel agents | Each spawns Node processes |

## Full CI Config

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,  // CI: predictable, less overhead
      },
    },
    isolate: false,        // Faster if tests don't leak state
    reporters: ['verbose'],
    coverage: {
      provider: 'v8',
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['**/*.d.ts', '**/*.test.{ts,tsx}', '**/test/**'],
      reporter: ['text', 'lcov'],
      reportOnFailure: true,
    },
  },
})
```

## Pool Selection (Node 22+)

| Pool | Use When | Avoid When |
|------|----------|------------|
| `forks` | Node 22+, default choice | - |
| `threads` | Node <22, CPU-bound tests | Node 22+ (native fetch issues) |
| `vmThreads` | Need isolation + speed | Memory-constrained CI |

## Mocking Quick Reference

```typescript
// PREFER: vi.spyOn - explicit, no hoisting issues
const spy = vi.spyOn(service, 'method').mockReturnValue('mocked')

// AVOID unless necessary: vi.mock - hoisted, can't use imports
vi.mock('./module', () => ({ fn: vi.fn() }))
```

## Coverage: Always Define include

Without `include`, Vitest only covers files imported by tests. Untested files
show 0% instead of being flagged as uncovered.

```typescript
coverage: {
  include: ['src/**'],     // ALWAYS define
  reporter: ['text', 'lcov'],
  reportOnFailure: true,   // Get coverage even on test failure
}
```
