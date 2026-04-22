# Simplify: Reduce Complexity

## Survey-Imagine-Simplify Protocol

### Survey

What does this code actually do? Not what it's supposed to do, not what
the comments say — what does it actually do?

- Trace the execution path end-to-end
- List every actual responsibility (not the claimed ones)
- Note where control flow surprises you
- Mark code that exists but never executes in production paths

### Imagine

If you were building this today with the same requirements, what's the
simplest design? Don't constrain yourself to the current structure.

Ask: "What would a senior engineer who's never seen this code design
from scratch, given only the requirements and the test suite?"

Write the imagined design down — even a 3-line sketch. You need it
concrete to measure the gap.

### Simplify

The gap between survey and imagine is your simplification target.
Prioritize the largest gaps. Implement one simplification at a time,
verify behavior after each.

## Deletion-First Hierarchy

Prefer operations higher in this list. Always attempt the higher-leverage
operation before falling back.

1. **Deletion** — Remove code that isn't needed. Dead code, unused
   exports, compatibility shims with no consumers, config nobody reads.
   Highest leverage. A line deleted is a line that never breaks.

2. **Consolidation** — Merge two things that do almost the same thing.
   Two similar functions become one parameterized function. Two config
   files become one. Two error handlers become one with a discriminant.

3. **Abstraction** — Extract a repeated pattern into a named concept.
   Only when the pattern is stable and appears 3+ times. Premature
   abstraction is worse than duplication.

4. **Refactoring** — Restructure without changing behavior. Rename for
   clarity, reorder for readability, extract for testability. Lowest
   leverage but sometimes necessary to enable a deletion or consolidation
   in a subsequent pass.

## Complexity Metrics

Measurable signals, not vibes.

- **LOC delta** — Net lines added/removed. Negative is usually good.
  Track per-file, not just total — moving 200 lines between files is
  not simplification.

- **Nesting depth** — Max indent level in changed functions. >3 levels
  is a smell. Flatten with early returns, guard clauses, extraction.

- **Import fan-in/fan-out** — How many modules depend on this (fan-in)?
  How many does it depend on (fan-out)? High fan-out means this module
  knows too much. High fan-in means changes here break many things.
  Both are simplification targets.

- **Cyclomatic complexity** — Number of independent paths through a
  function. Each `if`, `for`, `while`, `catch`, `case`, `&&`, `||`
  adds one. >10 per function is a smell. >20 is a defect.

## Chesterton's Fence

Before removing anything: understand why it was added.

1. Read the commit message that introduced it
2. Read the PR discussion if one exists
3. Check git blame for context on surrounding code
4. Search issues/bugs for the symptom it addresses

The removal sentence — complete it or don't remove:

> "I want to remove X. X was added because Y. Y is no longer true
> because Z. Therefore X can be removed."

If you cannot complete that sentence, do not remove it. File a
`backlog.d/` ticket to investigate: "Investigate: why does X exist?"

### Load-Bearing Signs

Watch for code that looks dead but isn't:

- Error handlers for conditions you've never seen fire
- Compatibility paths for API consumers you don't control
- Race condition guards that only matter under load
- Fallback behavior that activates on infrastructure failure

## Diminishing Returns

Stop simplifying when any of these hold:

- Each change saves fewer lines than the previous one
- You're rearranging rather than removing
- The "simpler" version is harder to explain to a new reader
- You're touching files outside the PR's scope
- Risk of breaking behavior exceeds clarity gained
- You've been through the loop twice with only cosmetic changes

The goal is not minimal code. The goal is minimal complexity for the
behavior delivered.

## Verification

### Behavioral Preservation

After each simplification:

1. Run the full test suite — no regressions
2. If tests were deleted (testing removed code), verify no coverage gap
3. If behavior is preserved but structure changed, verify callers still work
4. Smoke-test any path you couldn't trace statically

### Complexity Audit

Run `assess-simplify` when available (strong tier).

Required checks:
- `complexity_moved_not_removed` must be `false` — redistributing
  complexity across modules is not simplification
- Net LOC delta should be zero or negative
- No new modules introduced unless one was split for information hiding

If `assess-simplify` is unavailable, manually verify:
- Diff stat shows net deletion or neutral
- No function grew in cyclomatic complexity
- No new imports were added to existing modules

## Mandatory Trigger

**Diffs >200 LOC net:** Full Survey-Imagine-Simplify protocol required.

**Diffs ≤200 LOC net:** Manual module-depth review using Ousterhout
checks — shallow modules, information leakage, pass-throughs,
compatibility shims with no active contract.

## One-at-a-Time Rule

Implement one simplification per commit. Verify behavior after each.
If a simplification breaks something, revert it — don't fix forward.
This keeps the loop clean: simplify → verify → commit → repeat.
