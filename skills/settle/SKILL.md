---
name: settle
description: |
  Unblock, polish, and simplify a PR until it's genuinely merge-ready.
  Three phases: fix (CI/conflicts/reviews), polish (architecture/tests/docs),
  simplify (complexity reduction). Runs all three in sequence — stop only
  when everything is green, landed, and clean.
  Use when: PR is blocked, CI red, review comments open, "land this PR",
  "get this mergeable", "fix and polish", "unblock PR", "clean up this PR",
  "make this merge-ready", "address reviews", "fix CI".
  Trigger: /settle, /land (alias), /pr-fix, /pr-polish, /simplify.
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

## Executive / Worker Split

Keep the strongest available model on review-heavy executive work:
- deciding which review comments are valid, in scope, or rejected
- hindsight architecture review and simplification choices
- confidence assessment and final merge-readiness judgment

Delegate bounded remediation work to smaller worker subagents:
- fixing one comment thread or one failing check at a time
- gathering review evidence, reproducing CI failures, and drafting narrow patches
- mechanical cleanups, focused test additions, and doc refreshes with clear ownership

If the harness supports model choice, use small worker-class models for these
bounded tasks and reserve frontier models for review disposition, architecture,
and final settlement calls.

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
5. **Async settlement** — after pushing fixes, invoke `/review-settle` to mechanically
   verify all automated reviews (CI checks, bot reviewers) have completed.
   Do not declare success while automation can still add findings.

Dispatch the fixes themselves to smaller worker subagents when the scope is
clear and bounded. Keep comment disposition, reviewer communication, and the
final "is this settled?" judgment on the lead model.

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
2. **Agent-first assessment** — run `assess-review` (triad, strong tier) for
   structured code review. Run `assess-tests` for test quality scoring. Run
   `assess-docs` if docs were touched. Address all `fail` findings before proceeding.
3. **Architecture edits** — fix what the hindsight review and assess-* checks find. Commit.
4. **Test audit** — coverage gaps, brittle tests, missing edge cases. Fix.
5. **Docs** — update any docs/comments that are stale after the changes.
5. **Confidence assessment** — how confident are we this won't break anything?
   Treat confidence as an explicit deliverable with evidence.

Use the strongest available model for hindsight review and confidence judgment.
Use smaller workers for narrow polish follow-through once the direction is clear.

**Exit gate:** Architecture clean, tests solid, docs current, confidence stated.

If polish generates changes, return to Phase 1 (CI must stay green).

### Phase 3: Simplify — Reduce complexity

Read `../autopilot/references/simplify.md` and follow it completely.

**Goal:** Remove complexity that doesn't earn its keep.

1. **Survey** — what does this code actually do? Why is it shaped this way?
2. **Imagine the clean rebuild** — if starting today, what's the simplest design?
3. **Find the highest-leverage simplification** — deletion > consolidation > abstraction
4. **Implement** — one refactor, verify behavior preserved, commit
5. **Verify simplification** — run `assess-simplify` (strong tier) to produce
   measurable proof that complexity was genuinely reduced, not just redistributed.
   The `complexity_moved_not_removed` flag must be false to exit this phase.

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

## Reviewer Artifact Policy

When settlement needs screenshots, videos, logs, or walkthrough proof:

- Upload screenshots/GIFs to draft GitHub release assets, embed download URLs
  in PR comments. See `autopilot/references/pr-evidence-upload.md` for the recipe.
- Convert `.webm` → `.gif` before upload (GitHub renders GIFs inline, not video).
- Prefer CI artifacts or step summaries for generated verification output.
- Never commit binary PR evidence into the repo.
- Never use `raw.githubusercontent.com` URLs (breaks for private repos).
- Link the full release at the bottom of every evidence comment.

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
