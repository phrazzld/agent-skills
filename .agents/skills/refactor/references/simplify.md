# Simplify — deep methodology

The SKILL.md body is the decision layer. This file is the craft layer —
the operations a single bounded refactor applies, in order.

## Survey → imagine → simplify

**Survey.** What does this code *actually* do? Not what the frontmatter
says, not what the spec claims — trace execution end-to-end. List every
real responsibility. Mark every branch that never fires in production.

**Imagine.** If you were building this today, same requirements, what's
the simplest shape? Sketch it — even three lines is enough. You need it
concrete to measure the gap.

Spellbook reference points:
- `skills/flywheel/SKILL.md` (43 lines) — the asymptote.
- `skills/shape/SKILL.md` (~117 lines) — the ceiling for orchestrators.
- Any SKILL.md >500 lines fails `check-frontmatter`. Extract to
  `references/` before it grows past the cap.

**Simplify.** The gap is the target. Largest gap first. One cut at a
time. Verify after each.

## Deletion-first hierarchy

Always try the higher-leverage operation before falling back.

1. **Deletion.** Dead code, unused exports, shims with no active
   consumer, config nobody reads, a whole skill no one invokes. A line
   deleted is a line that never breaks, never drifts, never needs a
   test. Highest leverage. `f91f1c4`'s removal of `skills/tailor-skills/`
   and four scripts is the canonical form.
2. **Consolidation.** Two things doing almost the same thing become one
   parameterized thing. `d049cad` unified the search scripts into a
   shared embedding module. Two similar SKILL.md files becoming one
   with a router section is this pattern.
3. **State reduction.** Mode flags collapse; two-branch conditional
   becomes one code path. A skill with "phase 1 / phase 2 / phase 3"
   sections often has one phase pretending to be three.
4. **Abstraction.** Extract a repeated pattern *only when* it appears
   3+ times and the shape is stable. Premature abstraction is worse
   than duplication — it freezes the wrong joints.
5. **Refactor-in-place.** Rename for clarity, reorder, extract for
   testability. Lowest leverage. Often a prerequisite for a subsequent
   deletion or consolidation.

## Complexity metrics

Measurable signals. Not vibes.

- **LOC delta** — Net lines per file. Negative is usually good. Moving
  200 lines between files is not simplification (see "complexity moved
  not removed" below).
- **Nesting depth** — Max indent level. >3 is a smell. Flatten with
  early returns, guard clauses, extraction. For SKILL.md bodies, nested
  sub-sub-sub-bullets are the analogue.
- **Fan-in / fan-out** — How many modules depend on this? How many does
  it depend on? Both extremes are simplification targets. For skills:
  how many other SKILL.md files reference this one via trigger syntax?
- **Cyclomatic complexity** — Each `if`, `for`, `while`, `catch`, `case`,
  `&&`, `||` adds one. >10 per function is a smell. >20 is a defect.
  `ci/src/spellbook_ci/main.py` gate functions should stay <10.

## Chesterton's fence — complete the sentence or don't remove

Before removing anything:

1. Read the commit that introduced it (`git log --all -S'<snippet>' --
   <path>`).
2. Read the PR discussion if one exists (`gh pr list --search "..."`).
3. Check `git blame` for context.
4. Search `backlog.d/` and `backlog.d/_done/` for related tickets.
5. Search `git-bug bug` for open issues referencing the area.

The removal sentence:

> "I want to remove X. X was added in `<sha>` because Y. Y is no
> longer true because Z. Therefore X can be removed."

If you cannot complete that sentence with concrete shas and
invariants, do not remove it. File a git-bug or a `backlog.d/`
ticket:

```
git-bug bug new -t "Investigate: why does X exist?" -m "<context>"
```

### Load-bearing signs

Code that looks dead but isn't:

- Error handlers for conditions you've never seen fire (they fire
  under production load).
- Compatibility paths for API consumers you don't control (the
  cross-harness analogue: a bootstrap branch for a harness you don't
  use).
- Race-condition guards that matter only under parallelism (the
  spellbook version: `check-no-claims` exists because coordination
  primitives *looked* unused).
- Fallback behavior that activates on infrastructure failure.

Cross-harness first is itself load-bearing. A skill branch that "looks
unused" because your local harness is Claude, but fires on Codex or
Pi, is not unused.

## Diminishing returns — when to stop

Stop when any holds:

- Each cut saves fewer lines than the previous one.
- You're rearranging rather than removing.
- The "simpler" version is harder to explain to a new reader.
- You've touched files outside the scope.
- Risk of breaking a gate exceeds clarity gained.
- Two passes through the loop with only cosmetic deltas.

The goal is minimal complexity for the behavior delivered — not
minimal code.

## Verification

After every cut:

1. **Full gate.** `dagger call check --source=.`. Every one of the 12
   sub-gates green. No exceptions.
2. **Affected pre-commit hooks.** If `skills/` or `agents/` changed,
   pre-commit regenerates `index.yaml`. Don't hand-edit it; let the
   hook run.
3. **Harness-install check.** If `bootstrap.sh` or per-harness settings
   changed, `scripts/check-harness-agnostic-installs.sh` must pass.
4. **Coverage preservation.** If you deleted tests because you deleted
   the code they tested, verify no coverage gap opened in code that
   still exists.
5. **Cross-harness parity.** Still works on Claude, Codex, Pi. The
   Red Line.

### Complexity audit

Required on any cut:

- **Complexity moved, not removed** must be **false**. Redistributing
  complexity across modules doesn't count. Splitting a 200-line file
  into two 100-line files that together still do what the 200-line file
  did is not simplification.
- **Net LOC delta** — zero or negative across the diff.
- **No new modules** introduced unless one was split strictly for
  information hiding (Ousterhout's deep-module test: does the split
  produce a simpler interface?).
- **No new gate** added. The catalog has 12; adding a 13th because a
  cut needs a guard is a signal the cut is too aggressive.

## One-at-a-time

One simplification per commit. Verify after each. If a cut breaks
something, revert — don't fix forward. This keeps the loop clean:
simplify → verify → commit → repeat.

Mandatory trigger: diffs >200 LOC net require the full survey-imagine-
simplify protocol. Smaller diffs can run the Ousterhout checks
directly (shallow modules, information leakage, pass-throughs, shims
with no active contract).
