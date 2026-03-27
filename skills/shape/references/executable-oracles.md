# Executable Oracles

An oracle is a check that decides success. Checkbox oracles drift.
Executable oracles enforce.

## The Problem

Prose oracles require interpretation:
- "Auth should work" — what does "work" mean?
- "Response time should be fast" — how fast?
- "Tests should pass" — which tests?

These decay into opinion. The builder declares victory, the critic
disagrees, and nobody has a ground truth to point at.

## The Fix: Oracles as Commands

Every oracle should be a command that returns pass/fail:

```bash
# Bad: "The login endpoint should return 200 with valid credentials"
# Good:
curl -sf -X POST localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","pass":"test123"}' \
  | jq -e '.token != null'

# Bad: "All auth tests should pass"
# Good:
pytest tests/auth/ -x -q

# Bad: "Response time should be reasonable"
# Good:
ab -n 100 -c 10 http://localhost:3000/api/health | grep -q 'Time per request.*[0-9]\.' \
  && echo "p99 < 1s" || exit 1

# Bad: "No regressions"
# Good:
npm test -- --bail 2>&1 | tail -1 | grep -q 'passed'
```

## Template

When writing the Oracle section of a context packet:

```markdown
## Oracle (Definition of Done)

Commands that must all exit 0:
- `pytest tests/auth/ -x -q` — existing auth tests pass
- `curl -sf localhost:3000/api/users/me -H "Authorization: Bearer $TOKEN" | jq -e '.id'` — new endpoint works
- `npm run typecheck` — no type errors introduced
- `git diff --stat | wc -l | awk '$1 < 20'` — diff stays reviewable

Observable outcomes (verified by human or /qa):
- Login page renders the new OAuth button
- Clicking it redirects to provider, then back with session
```

Split into two categories:
1. **Automated** — commands that can run in CI or a Stop check
2. **Observable** — outcomes that require visual/interactive verification

Automated oracles are the primary gate. Observable outcomes catch
what scripts can't (layout, UX flow, visual correctness).

## When You Can't Write an Oracle

If you can't write an executable oracle, the goal isn't clear enough.
Go back to the spec. Common causes:
- Goal is too vague ("improve performance")
- Success depends on subjective judgment with no proxy metric
- The feature can't be tested without infrastructure that doesn't exist yet

For the third case, building the test infrastructure IS the first task.
