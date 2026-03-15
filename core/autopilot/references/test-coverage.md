# /test-coverage

Audit test quality. Enforce TDD. Target coverage thresholds.

## What This Does

1. Audit test infrastructure (runner, coverage, config)
2. Run coverage analysis and identify gaps
3. Enforce TDD workflow (red-green-refactor)
4. Apply testing philosophy (behavior > implementation)
5. Configure Vitest if needed

## TDD Workflow (Default for All Production Code)

```
RED: Write failing test -> verify it fails correctly
GREEN: Write minimal code to pass -> verify all green
REFACTOR: Clean up -> stay green
REPEAT
```

**The iron law:** No production code without a failing test first.

**Skip TDD only for:** exploration (will delete), UI layout, generated code.

**The critical step most skip:** After writing a failing test, verify it fails
for the right reason -- not syntax errors, wrong imports, or incorrect assertions.

## Developer Test Rule

Prefer developer tests over mock-heavy unit tests.

- Test module exports and public behavior
- Test what callers observe, not internal message sends
- Refactor-hostile tests are bad tests even when green
- If a refactor breaks tests without changing behavior, fix the tests or the design

## Testing Philosophy

**Test behavior, not implementation.** Tests should verify WHAT code does,
not HOW it does it. Implementation changes; behavior remains stable.

### What to Test

- Public API (what callers depend on)
- Module exports / boundary behavior
- Business logic (critical rules, calculations)
- Error handling (failure modes)
- Edge cases (boundaries, null, empty)

### What NOT to Test

- Private implementation details
- Call order between internal collaborators
- Which internal method called which dependency
- Third-party libraries
- Simple getters/setters (unless they have logic)
- Framework code

### Mocking Rules

- **ALWAYS mock:** External APIs, network calls, non-deterministic behavior
- **NEVER mock:** Your own domain logic, internal collaborators (`@/lib/*`)
- **Red flag:** >3 mocks = coupling to implementation. Refactor.
- **Pattern:** If mock path starts with `@/` or `../`, reconsider.
- **Reject:** internal call-count/order assertions unless that order is behavior

### Test Structure: AAA

```
Arrange: Set up test data, mocks, preconditions
Act:     Execute the behavior being tested
Assert:  Verify expected outcome
```

One behavior per test. Name: "should [behavior] when [condition]".

## Test Properties

Good programmer tests should be:

- Fast enough to preserve flow
- Deterministic and isolated
- Behavioral and structure-insensitive
- Specific when they fail
- Cheap to write, read, and change
- Predictive enough for the level they claim to cover

## Coverage Philosophy

Coverage is diagnostic, not a goal.

- 60% meaningful > 95% testing implementation details
- Patch coverage: 80%+ for new code
- Critical paths (payment, auth): 90%+
- NEVER lower a coverage threshold to pass CI

## Vitest Configuration

### Critical Rules

1. **Node 22+**: Use `pool: 'forks'` (threads have issues)
2. **CI**: Single worker, disable watch, `isolate: false` if safe
3. **Coverage**: Always define `coverage.include` (defaults exclude too much)
4. **Mocking**: Prefer `vi.spyOn` over `vi.mock` (avoids hoisting)
5. **RTL cleanup**: Requires `globals: true`

### Memory Safety (MANDATORY)

| Rule | Why |
|------|-----|
| `"test"` script MUST be `vitest run` | Bare `vitest` = watch mode = persistent process |
| CI subprocesses: `env={..., "CI": "true"}` | Prevents watch mode |
| Pool: `forks`, `maxForks: 4` on <=36 GB | Caps memory |
| Never `vitest --watch` from agents | Zombies accumulate |

### Quick Config

```typescript
export default defineConfig({
  test: {
    pool: 'forks',
    poolOptions: { forks: { singleFork: true } },
    coverage: {
      provider: 'v8',
      include: ['src/**'],
      reporter: ['text', 'lcov'],
      reportOnFailure: true,
    },
  },
})
```

## Coverage Audit Process

```bash
# 1. Check test runner exists
[ -f "vitest.config.ts" ] && echo "Vitest" || echo "No Vitest"

# 2. Run coverage
pnpm coverage 2>/dev/null | tail -30

# 3. Identify uncovered critical paths
# Focus on: payment, auth, data mutation, error handling

# 4. Report gaps with priority
```

## Test Quality Checklist

- [ ] Each test has descriptive name ("should X when Y")
- [ ] AAA structure with visual separation
- [ ] Tests behavior, not implementation
- [ ] Mocks only at system boundaries
- [ ] No shared mutable state between tests
- [ ] Fast (<100ms unit, <1s integration)
- [ ] No flaky tests

## Exclusions Are Last Resort

Before excluding from coverage:
1. Can the function be exported and tested with mocked deps?
2. Can code be refactored to separate testable logic from runtime?
3. Is there a pattern in the codebase for testing similar code?

When exclusion IS appropriate: truly untestable runtime code, auto-generated
code, third-party code. Always add a comment explaining WHY.

## References

- `references/testing-philosophy.md` -- Full testing philosophy
- `references/developer-tests.md` -- Behavioral developer-test doctrine
- `references/tdd-protocol.md` -- Complete TDD workflow and rationalizations
- `references/vitest-config.md` -- Vitest configuration details
- `references/vitest-pool-config.md` -- Pool selection guide
- `references/vitest-performance.md` -- CI optimization, sharding
- `references/vitest-coverage.md` -- v8 vs Istanbul, thresholds
- `references/vitest-mocking.md` -- vi.mock hoisting, cleanup

## Related

- `/check-quality` -- Full quality infrastructure audit
- `/debug` -- Systematic debugging with test-first bug fixes
