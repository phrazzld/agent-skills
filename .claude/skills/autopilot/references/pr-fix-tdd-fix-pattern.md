# TDD Fix Pattern

For each in-scope review finding, follow this test-driven workflow.

## The Pattern

### 1. Write Failing Test

Create a test that exposes the issue. The test should:
- Target the specific behavior being fixed
- Fail before the fix
- Pass after the fix
- Not break on unrelated refactors

```typescript
// Example: Review finding about missing input validation
describe('createUser', () => {
  it('should reject invalid email format', () => {
    // Arrange
    const invalidInput = { email: 'not-an-email', name: 'Test' }

    // Act & Assert
    expect(() => createUser(invalidInput)).toThrow('Invalid email format')
  })
})
```

### 2. Verify Test Fails Correctly

Run the test and confirm it fails for the right reason:

```bash
pnpm test -- --watch auth.test.ts
```

**Check:**
- ❌ Test fails (expected)
- ❌ Fails because the validation doesn't exist (correct reason)
- ❌ NOT because of syntax error, wrong import, or unrelated issue

### 3. Fix the Code Minimally

Implement the smallest fix that makes the test pass:

```typescript
// Before
function createUser(input: UserInput): User {
  return { id: generateId(), ...input }
}

// After (minimal fix)
function createUser(input: UserInput): User {
  if (!input.email.includes('@')) {
    throw new Error('Invalid email format')
  }
  return { id: generateId(), ...input }
}
```

**Rules:**
- Fix only what the test requires
- Don't refactor beyond the fix
- Don't add "nice to have" improvements

### 4. Verify Test Passes

```bash
pnpm test -- auth.test.ts
```

**Check:**
- ✅ New test passes
- ✅ All existing tests still pass
- ✅ No regressions introduced

### 5. Commit the Fix

Use conventional commit format:

```bash
git add -A
git commit -m "fix(auth): validate email format in createUser

Review finding: Missing input validation allows invalid emails
Test: should reject invalid email format

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

**Commit message pattern:**
```
fix(scope): brief description

Review finding: [quote the original finding]
Test: [name of the test that proves the fix]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Test Types by Finding Category

### Security Findings

Test the attack vector directly:

```typescript
it('should prevent SQL injection in username', () => {
  const maliciousInput = "admin'; DROP TABLE users;--"
  // Should not throw SQL error or execute injection
  expect(() => findUser(maliciousInput)).not.toThrow()
  // Should return no results (user doesn't exist)
  expect(findUser(maliciousInput)).toBeNull()
})
```

### Validation Findings

Test boundary conditions:

```typescript
describe('password validation', () => {
  it('should reject password under 8 characters', () => {
    expect(() => validatePassword('short')).toThrow()
  })

  it('should accept password with 8+ characters', () => {
    expect(() => validatePassword('longenough')).not.toThrow()
  })
})
```

### Error Handling Findings

Test failure modes:

```typescript
it('should handle network timeout gracefully', async () => {
  // Arrange: Mock timeout
  jest.spyOn(fetch, 'fetch').mockRejectedValue(new Error('timeout'))

  // Act
  const result = await fetchUserData('user123')

  // Assert: Returns fallback, doesn't crash
  expect(result).toEqual({ error: 'Failed to fetch user data' })
})
```

### Performance Findings

Test with measurable assertions (where possible):

```typescript
it('should fetch users in single query (no N+1)', async () => {
  const queryCounter = jest.fn()
  db.on('query', queryCounter)

  await fetchUsersWithOrders(10)

  // Should be 2 queries max: users + orders (joined or batched)
  expect(queryCounter).toHaveBeenCalledTimes(2)
})
```

## When Test Is Hard to Write

Sometimes a finding is hard to test directly. Options:

### Option 1: Test at a Higher Level

Can't unit test? Integration test instead:

```typescript
it('should complete checkout flow end-to-end', async () => {
  const response = await request(app)
    .post('/api/checkout')
    .send(validCheckoutData)

  expect(response.status).toBe(200)
  expect(response.body.orderId).toBeDefined()
})
```

### Option 2: Manual Verification + Commit Note

If truly untestable (rare), document in commit:

```bash
git commit -m "fix(config): set secure cookie flags

Review finding: Session cookies missing secure flag
Verification: Manual - inspected Set-Cookie header in browser devtools
Note: Cookie flag verification requires browser; mocking deemed too brittle

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Option 3: Reconsider the Fix

If you can't test it, maybe the fix approach is wrong. Consider:
- Is there a more testable implementation?
- Should this be refactored first?
- Create issue for architectural fix instead

## Anti-Patterns

❌ **Test after fix** — Write test first. Always.

❌ **Test implementation** — Test behavior. If test breaks on refactor, it's testing implementation.

❌ **Over-mocking** — >3 mocks = design smell. Refactor instead.

❌ **Skipping test** — No test = no proof the fix works. No exceptions.

❌ **Multiple fixes per commit** — One fix = one test = one commit.
