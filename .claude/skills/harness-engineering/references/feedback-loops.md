# Feedback Loops for Agents

Design CI, tests, and linters as agent feedback -- not just human guardrails.

## Principle

Every automated check is an opportunity for the agent to self-correct.
The quality of the feedback determines whether the agent fixes the issue
or spins on it.

## Error Messages Agents Can Act On

**Bad feedback** (agent can't fix without guessing):
```
FAIL: test_auth
AssertionError
```

**Good feedback** (agent knows exactly what to do):
```
FAIL: test_auth (tests/test_auth.py:45)
  Expected: {"status": "authenticated", "user_id": "u_123"}
  Actual:   {"status": "error", "message": "token expired"}

  Hint: The test fixture creates a token with 1s expiry.
  Check if the handler validates expiry before processing.
```

**Design checklist for agent-consumable feedback:**
- [ ] File path and line number included
- [ ] Expected vs actual values shown
- [ ] Root cause or hint provided (not just symptom)
- [ ] Fix suggestion when deterministically known
- [ ] No cascading failures (first real error, not 50 downstream ones)

## Pre-Commit Hooks as Immediate Feedback

Pre-commit hooks are the fastest automated feedback loop.
Agent commits -> hook runs -> agent sees error -> agent fixes -> agent re-commits.

**Effective hooks for agents:**
- Type checking (`tsc --noEmit`) -- catches type errors before CI
- Lint with auto-fix (`eslint --fix`) -- agent learns patterns from fixes
- Format check (`prettier --check`) -- deterministic, always fixable
- Schema validation -- catches config errors locally
- Import boundary checks -- enforces architectural constraints

**Hook design for agents:**
- Exit with non-zero status AND a clear error message
- Show the specific violation, not "check failed"
- Auto-fix what's deterministic; report what requires judgment
- Run fast (<10s) -- slow hooks break agent flow

## Test Output for Agent Consumption

Structure test output so agents can parse failures:

```
# Good: structured, parseable
TEST FAIL: src/payments/charge.test.ts:78
  Test: "should reject expired cards"
  Error: Expected status 402, got 200
  Relevant code: src/payments/charge.ts:45-52 (validate_card)

# Bad: human-oriented narrative
Some tests failed. The charge handler seems to not be
validating card expiry correctly. You might want to check
the validation logic.
```

**For test frameworks:**
- Use structured reporters (JSON, JUnit XML) alongside human-readable
- Include source locations in failure output
- Show the minimal diff between expected and actual
- Group related failures to avoid cascade noise

## Build Failures as Learning Signals

When CI fails, the agent should be able to read the failure and fix it
without human interpretation.

**CI design for agents:**
- Surface the first meaningful error, not the full log
- Include the command that failed and its exit code
- Link to the specific file/line when possible
- Distinguish between "your code broke" and "infra flake"

**Flake handling:**
- Mark known flaky tests so agents don't chase them
- Auto-retry infra failures before surfacing to agent
- If a test flakes >5% of the time, fix or quarantine it

## Feedback Loop Metrics

Measure the quality of your feedback loops:

- **Self-correction rate**: % of feedback-triggered errors the agent fixes
  without human help. Target: >90%.
- **Feedback latency**: Time from agent action to feedback. <10s for hooks,
  <120s for tests, <15min for CI.
- **Feedback clarity**: Can the agent fix the issue from the error message
  alone? Test by checking if agent's fix attempts succeed on first try.
- **False positive rate**: % of feedback that flags non-issues. Target: <5%.
  False positives erode agent trust in feedback.
