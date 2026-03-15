# Mocking Pitfalls

## vi.mock vs vi.spyOn

| Aspect | `vi.mock` | `vi.spyOn` |
|--------|-----------|------------|
| Scope | Entire module | Single property |
| Hoisting | Yes (moves to top) | No |
| Access imports | No (runs before imports) | Yes |
| Type safety | Manual | Automatic |
| Cleanup | `vi.unmock()` | `.mockRestore()` |

**Default to `vi.spyOn`** - it's explicit and avoids hoisting surprises.

## vi.mock Hoisting Behavior

```typescript
// THIS IS HOISTED TO TOP - runs BEFORE imports
vi.mock('./service', () => ({
  fetchData: vi.fn(() => 'mocked'),
}))

// These imports happen AFTER vi.mock executes
import { fetchData } from './service'
import { MY_CONST } from './constants'  // Can't use in vi.mock!

// WRONG - MY_CONST is undefined in vi.mock
vi.mock('./service', () => ({
  value: MY_CONST,  // undefined!
}))

// RIGHT - use vi.hoisted for values needed in mock
const { MY_CONST } = vi.hoisted(() => import('./constants'))
vi.mock('./service', () => ({
  value: MY_CONST,
}))
```

## Internal References Can't Be Mocked

```typescript
// service.ts
export const helper = () => 'real'
export const main = () => helper()  // Internal reference

// test.ts
vi.mock('./service', async (importOriginal) => ({
  ...(await importOriginal()),
  helper: vi.fn(() => 'mocked'),
}))

// main() still calls real helper() - internal reference not affected!
```

**Solutions**:
1. Inject dependencies
2. Export object instead of individual functions
3. Mock at a higher level

## Cleanup Strategies

```typescript
// Per-test cleanup
afterEach(() => {
  vi.restoreAllMocks()  // Restores original implementations
})

// Or in setup file
// vitest.config.ts
export default defineConfig({
  test: {
    restoreMocks: true,   // Auto-restore after each test
    clearMocks: true,     // Clear call history
    mockReset: true,      // Reset to empty implementation
  },
})
```

| Method | Effect |
|--------|--------|
| `mockClear()` | Clear call history |
| `mockReset()` | Clear + reset implementation |
| `mockRestore()` | Reset + restore original |

## RTL Cleanup Requires globals: true

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    globals: true,  // Required for RTL automatic cleanup
    environment: 'jsdom',
  },
})
```

Without `globals: true`, RTL's `cleanup()` doesn't run automatically.

```typescript
// Manual cleanup if globals: false
import { cleanup } from '@testing-library/react'
afterEach(cleanup)
```

## Mock Timer Gotchas

```typescript
beforeEach(() => {
  vi.useFakeTimers()
})

afterEach(() => {
  vi.useRealTimers()  // ALWAYS restore!
})

test('debounce', async () => {
  // Advance time
  vi.advanceTimersByTime(1000)

  // Or run all pending timers
  vi.runAllTimers()

  // For promises with timers
  await vi.runAllTimersAsync()
})
```
