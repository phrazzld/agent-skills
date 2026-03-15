# TDD Protocol

Absorbed from the `test-driven-development` skill.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over. Don't keep as "reference".

## Red-Green-Refactor

### RED: Write Failing Test

Write one minimal test showing what should happen.

Requirements:
- One behavior
- Clear name
- Test exported/public behavior
- Real code (no mocks unless unavoidable)

### Verify RED (MANDATORY, NEVER SKIP)

```bash
npm test path/to/test.test.ts
```

Confirm: test fails (not errors), failure is expected, fails because feature
missing (not typos). Test passes? You're testing existing behavior -- fix test.

### GREEN: Minimal Code

Write simplest code to pass. Don't add features, refactor, or "improve" beyond the test.

### Verify GREEN (MANDATORY)

All tests pass. Output pristine. No warnings.

### REFACTOR

After green only. Remove duplication, improve names, extract helpers. Stay green.

## Canon TDD Pattern (Kent Beck 2024)

1. Write test list -- enumerate all scenarios (happy, edge, error)
2. Turn one into failing test -- focus on interface design
3. Make it pass -- minimal implementation
4. Refactor -- improve design while green
5. Repeat until list empty

## AI-Assisted TDD

- AI generates test list from requirements
- AI implements code to pass tests (human reviews)
- Tests are specifications in executable form
- Commit tests separately before implementation
- Prefer developer tests over mock-heavy unit tests
- Avoid asserting internal call order unless that order is user-visible behavior

## Bug Fix Pattern

1. Write failing test that reproduces the bug
2. Verify it fails for the right reason
3. Fix the code
4. Verify test passes
5. No more bug. Test prevents regression.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = skip" | Hard to test = hard to use. Listen to the test. |
| "TDD will slow me down" | TDD faster than debugging. |
| "Existing code has no tests" | You're improving it. Add tests. |

## Red Flags

- Code before test
- Test passes immediately
- Can't explain why test failed
- "Just this once"
- "Keep as reference"
- "Already spent X hours, deleting is wasteful"

All mean: Delete code. Start over with TDD.
