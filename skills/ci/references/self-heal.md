# Self-Heal Scope

When `/ci` hits a red gate, classify the failure and decide: fix it, or
escalate to the human. Bounded self-heal — the skill is not allowed to
"make it pass" by any means necessary.

## Decision Protocol

For each failing gate, ask three questions in order:

1. **Is this a mechanical drift failure?** (format, lint, lockfile,
   import order) → fix.
2. **Is this a genuine correctness signal?** (failing test that encodes
   a behavior contract, type error in hand-written code, logic bug) →
   escalate.
3. **Is this a flake?** (intermittent, timing-sensitive, network blip) →
   retry once, then classify as escalate if it persists.

If ambiguous, escalate. The cost of a false-escalate is a human looking
at a diagnosis. The cost of a false-fix is a silent incorrect commit.

## Self-Healable Categories

Fix these inline. Dispatch a focused builder subagent per fix; do not
inline mechanical edits on the lead.

### Lint + format drift

- Ruff, ESLint, Prettier, gofmt, clang-format complaints.
- Fix: run the auto-fixer (`ruff --fix`, `prettier --write`, `gofmt -w`).
- Commit as `style: auto-format` or similar.
- Re-run the lint gate to confirm green.

### Import order, unused imports

- Usually auto-fixable by the same linter.
- If not auto-fixable, still mechanical — safe to edit.

### Lockfile drift

- `package-lock.json`, `uv.lock`, `Cargo.lock`, `go.sum` out of sync
  with manifest.
- Fix: run the package manager's resolve/install command, commit the
  updated lockfile.
- If the resolve *fails* (real dependency conflict), escalate.

### Flaky test, one-off

- Same test passes on retry. Retry **once**. If green, note in report.
  If still red, escalate — treat as a real failure, not a flake. Don't
  mask real failures as flakes.

### Trivially fixable typo or import

- Missing import, obvious typo in a symbol name, clearly visible in
  the error. The "clearly visible" bar is strict — if you need to read
  more than the error and the one referenced line to see the fix, it's
  not trivial. Escalate.

### Generated-file drift

- If the repo has generators (protobuf, openapi, graphql codegen) and
  the CI checks `git diff --exit-code` after regen, just re-run the
  generator and commit.

## Escalate Categories

Stop. Emit structured diagnosis. Exit non-zero. The human decides.

### Failing test that encodes behavior

- The test is asserting a behavior contract and the code no longer
  satisfies it. Either the test is wrong (contract changed) or the
  code is wrong (regression). This is a human-judgment call.
- **Never** fix by modifying the test assertion. **Never** fix by
  `@skip` / `xfail` / `it.skip`.

### Type error in hand-written code

- Type errors are usually contract signals. Fixing by casting to `Any`
  / `any` / `unknown` is suppression, not a fix.
- Exception: obvious narrowing issues (e.g. null check the linter
  didn't infer) — safe to fix with an explicit guard. Use judgment.

### Logic / algorithm failure

- Test reveals a bug in the algorithm. Not your call to patch.

### Coverage drop below floor

- New code has insufficient test coverage. The fix is writing tests,
  which is an authoring task, not a mechanical fix. Escalate with a
  pointer to the under-covered file(s).
- Do **not** fix by lowering the coverage floor.

### Secret leaked

- gitleaks / trufflehog found a secret. Escalate immediately. Do not
  rewrite history silently — the secret is already pushed.

### Build failure in dependency

- Transitive dep broke. Fixing usually means pinning, upgrading, or
  patching. Escalate — this often has implications the skill can't
  evaluate.

## Bounded Retries

Cap self-heal at **3 attempts per gate**. Each attempt:

1. Classify the failure.
2. If self-healable, dispatch fix, commit, re-run the gate.
3. If still red after 3 passes — even if each pass was classified
   self-healable — stop. The auto-fixer isn't converging. Escalate.

This prevents loops where e.g. auto-format fights a pre-commit hook.

## Diagnosis Format

When escalating, produce:

```markdown
## /ci Escalation
Gate: <gate-name>
Command: dagger call <function>
Status: failed after <n> attempts
Failure:
  file:line
  error excerpt (exact, not paraphrased)
Classification: <category from above>
Candidate cause: <one sentence hypothesis, if clear>
Suggested next step: <what the human should look at first>
```

Structured output lets the human move fast. Prose dumps don't.

## Red Lines

- Never lower a threshold to make a gate pass.
- Never `@skip` / `xfail` / comment-out a failing test.
- Never suppress a type error by casting to `Any`.
- Never rewrite git history to hide a secret leak.
- Never exceed 3 self-heal attempts on a single gate.
- Never mark flake without a second run that passes.

These are hard stops, not guidelines. Any proposal to cross one is
itself an escalation signal — tell the human, don't do it.
