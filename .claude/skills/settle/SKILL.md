---
name: settle
description: |
  Unblock, polish, and simplify a PR until it's genuinely merge-ready.
  Three phases: fix (CI/conflicts/reviews), polish (architecture/tests/docs),
  simplify (complexity reduction). Runs all three in sequence — stop only
  when everything is green, settled, and clean.
  Use when: PR is blocked, CI red, review comments open, "settle this PR",
  "get this mergeable", "fix and polish", "unblock PR", "clean up this PR",
  "make this merge-ready", "address reviews", "fix CI".
  Trigger: /settle, /pr-fix, /pr-polish, /simplify.
disable-model-invocation: true
argument-hint: "[PR-number]"
---

# /settle

Take a PR from blocked to merge-ready. Fix everything, polish everything, simplify everything.

## Role

Senior engineer who owns the lane end-to-end. Not done until the PR is genuinely
clean — not just "CI green" but architecturally sound, well-tested, and simple.

## Objective

Take PR `$ARGUMENTS` (or the current branch's PR) through three phases until it reaches:
- No merge conflicts
- CI green
- Every review comment addressed (fixed, deferred with issue, or rejected with reasoning)
- No open review threads
- Architecture reviewed with hindsight lens
- Tests audited for coverage and quality
- Complexity reduced where possible
- Docs current

## Process

### Phase 1: Fix — Unblock the PR

Read `../autopilot/references/pr-fix.md` and follow it completely.

**Goal:** Get from blocked to green.

1. **Conflicts** — rebase or merge, resolve all conflicts
2. **CI** — investigate failures, fix root causes, push, re-verify
3. **Self-review** — read the entire diff as a reviewer would
4. **Review comments** — read every single comment on the PR. For each:
   - **In scope:** fix it, commit, reply confirming the fix
   - **Valid but out of scope:** create a GitHub issue, reply linking it
   - **Invalid:** reply with clear reasoning
5. **Async settlement** — after pushing fixes, wait for reviewer bots to re-run.
   Do not declare success while automation can still add findings.

**Exit gate:** CI green, no open review threads, no unresolved comments.

If already green and settled, skip to Phase 2.

### Phase 2: Polish — Elevate quality

Read `../autopilot/references/pr-polish.md` and follow it completely.

**Goal:** Get from "works" to "exemplary."

1. **Hindsight review** — "Would we build it the same way starting over?"
   Read the full diff. Look for:
   - Shallow modules, pass-through layers
   - Hidden coupling, temporal decomposition
   - Missing abstractions or premature abstractions
   - Tests that test implementation, not behavior
2. **Architecture edits** — fix what the hindsight review finds. Commit.
3. **Test audit** — coverage gaps, brittle tests, missing edge cases. Fix.
4. **Docs** — update any docs/comments that are stale after the changes.
5. **Confidence assessment** — how confident are we this won't break anything?
   Treat confidence as an explicit deliverable with evidence.

**Exit gate:** Architecture clean, tests solid, docs current, confidence stated.

If polish generates changes, return to Phase 1 (CI must stay green).

### Phase 3: Simplify — Reduce complexity

Read `../autopilot/references/simplify.md` and follow it completely.

**Goal:** Remove complexity that doesn't earn its keep.

1. **Survey** — what does this code actually do? Why is it shaped this way?
2. **Imagine the clean rebuild** — if starting today, what's the simplest design?
3. **Find the highest-leverage simplification** — deletion > consolidation > abstraction
4. **Implement** — one refactor, verify behavior preserved, commit

**Mandatory when diff >200 LOC net.** For smaller diffs, manual module-depth
review using Ousterhout checks: shallow modules, information leakage,
pass-throughs, compatibility shims with no active contract.

**Exit gate:** No obvious complexity to remove, or explicit justification for keeping it.

If simplification generates changes, return to Phase 1 (CI must stay green).

## Loop Until Done

```
Phase 1 (fix) → Phase 2 (polish) → Phase 3 (simplify)
       ↑                                      │
       └──────── if changes pushed ───────────┘
```

Each phase that generates commits sends you back to Phase 1 to re-verify
CI and reviews. The loop terminates when a full pass produces no changes.

## Flags

- `$ARGUMENTS` as PR number — target specific PR
- If no argument, uses the current branch's PR

## Anti-Patterns

- Declaring "done" while CI is still running
- Ignoring review comments instead of addressing them
- Polish without re-running CI afterward
- Simplifying without verifying behavior is preserved
- Skipping simplify because "it works"
- Posting "PR Unblocked" while async reviewers can still add findings

## Output

Report per phase:
- **Fix:** conflicts resolved, CI failures fixed, review comments addressed (count + dispositions)
- **Polish:** architecture changes made, test gaps filled, confidence level + evidence
- **Simplify:** complexity removed (LOC delta, modules consolidated, abstractions deleted)
- **Final:** PR URL, merge readiness assessment, any remaining risks
