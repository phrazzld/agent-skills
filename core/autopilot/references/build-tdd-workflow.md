# TDD Workflow Reference

## Core Principle

Write the test first. Watch it fail. Write minimal code to pass.
If you didn't watch the test fail, you don't know if it tests the right thing.

## Red-Green-Refactor

### RED — Write Failing Test

Write one minimal test showing what should happen:
- One behavior per test
- Clear name describing behavior
- Real code (no mocks unless unavoidable)

### Verify RED — Watch It Fail (MANDATORY)

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

### GREEN — Minimal Code

Write simplest code to pass the test. Don't add features, refactor other code,
or "improve" beyond the test.

### Verify GREEN — Watch It Pass (MANDATORY)

```bash
npm test path/to/test.test.ts
```

Confirm: test passes, other tests still pass, output pristine.

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers.
Keep tests green. Don't add behavior.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| Minimal | One thing | "and" in name? Split it |
| Clear | Name describes behavior | `test('test1')` |
| Shows intent | Demonstrates desired API | Obscures what code should do |

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first |
| Test too complicated | Design too complicated. Simplify interface |
| Must mock everything | Code too coupled. Use dependency injection |
| Test setup huge | Extract helpers. Still complex? Simplify design |

## Bug Fix Pattern

Bug found? Write failing test reproducing it. Follow TDD cycle.
Test proves fix and prevents regression. Never fix bugs without a test.
