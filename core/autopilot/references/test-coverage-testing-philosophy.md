# Testing Philosophy

Absorbed from the `testing-philosophy` skill. Universal principles for effective tests.

## Test Thinking

Before writing tests:
- What is the ONE behavior this test suite must verify?
- Behavior or implementation? Tests should survive refactoring.
- What failure would make you distrust this code? Test that first.

## Core Principle

**Test behavior, not implementation.** Tests verify what code does, not how.

## What and When to Test

### Testing Boundaries

**Unit Tests:** Pure functions, isolated modules, business logic
**Integration Tests:** Module interactions, API contracts, workflows
**E2E Tests:** Critical user journeys, happy path + critical errors only

### Decision Trees

**Should I write a test?**
1. Public API? -> Yes
2. Critical business logic? -> Yes
3. Error handling? -> Yes
4. Private implementation? -> No, test through public API
5. Framework feature? -> No, trust framework

**Should I mock this?**
1. External system? -> Mock it
2. Non-deterministic? -> Mock it
3. My domain logic? -> Don't mock
4. >3 mocks already? -> Refactor

### Internal vs External Mock Boundary

NEVER mock internal collaborators (`@/lib/*`, `./utils/*`). Mocking internal
code hides integration bugs, couples tests to implementation, creates false
confidence. Mock only at system boundaries.

## Test Structure: AAA

Clear three-phase structure with visual separation between phases.
One logical assertion per test. Keep Arrange simple.

## Test Quality Priorities

**Readable > DRY.** Tests are documentation. Some duplication is OK for clarity.

### Test Smells

- >3 mocks (coupling to implementation)
- Brittle assertions (exact strings when substring works)
- Testing private methods directly
- Flaky tests (timing deps, shared state)
- One giant test (multiple behaviors)
- Magic values without explanation

## Coverage Philosophy

Don't chase coverage percentages.
- Critical paths tested (happy + error cases)
- Edge cases covered (boundary values, null, empty)
- Confidence in refactoring

Untested code is legacy code. But 100% coverage doesn't guarantee quality.

## Integration Test Patterns

### API Routes
```typescript
describe('POST /api/users', () => {
  it('creates user and persists', async () => {
    const res = await request(app).post('/api/users').send({ email: 'test@example.com' })
    expect(res.status).toBe(201)
    const user = await db.users.findByEmail('test@example.com')
    expect(user).toBeDefined()
  })
})
```

### Database Integration
Use real test database. Transaction rollback for isolation:
```typescript
beforeEach(() => db.beginTransaction())
afterEach(() => db.rollback())
```

### Edge Cases: Required for Critical Paths
Always test: boundary values (0, 1, -1, max, min), empty inputs, error conditions.
