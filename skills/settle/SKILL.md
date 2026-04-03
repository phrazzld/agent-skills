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

Keep synthesis, judgment, and user communication on the lead:
- deciding which review comments are valid, in scope, or rejected
- hindsight architecture review and simplification choices
- confidence assessment and final merge-readiness judgment

Delegate bounded remediation to ad-hoc **general-purpose** subagents:
- fixing one comment thread or one failing check at a time
- gathering review evidence, reproducing CI failures, and drafting narrow patches
- mechanical cleanups, focused test additions, and doc refreshes with clear ownership

Use **Explore** subagents for evidence gathering when no file mutations are needed.
Use **builder** agent for fixes that require TDD discipline.

## Process

### Phase 1: Fix — Unblock the PR

Read `references/pr-fix.md` and follow it completely.

**Goal:** Get from blocked to green.

1. **Conflicts** — rebase or merge, resolve all conflicts
2. **CI** — investigate failures, fix root causes, push, re-verify
3. **Self-review** — read the entire diff as a reviewer would
4. **Review comments** — read every single comment on the PR. For each:
   - **In scope:** fix it, commit, reply confirming the fix
   - **Valid but out of scope:** create a git-bug issue (or `backlog.d/` item), reply linking it
   - **Invalid:** reply with clear reasoning
5. **Async settlement** — after pushing fixes, invoke `/review-settle` to mechanically
   verify all automated reviews (CI checks, bot reviewers) have completed.
   Do not declare success while automation can still add findings.

Dispatch the fixes themselves to smaller worker subagents when the scope is
clear and bounded. Keep comment disposition, reviewer communication, and the
final "is this settled?" judgment on the lead model.

6. **Merge-readiness verification** — before declaring Phase 1 complete, run:
   `gh pr view --json reviews,statusCheckRollup` and verify at least one approving
   review and all checks passing. If either is missing, do not proceed — address
   the gap or escalate.

**Exit gate:** CI green, no open review threads, no unresolved comments, merge-readiness verified.

If already green and settled, skip to Phase 2.

### Phase 2: Polish — Elevate quality

Read `references/pr-polish.md` and follow it completely.

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

Read `references/simplify.md` and follow it completely.

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
  in PR comments. See `skills/harness/references/pr-evidence-upload.md` for the recipe.
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
- **Truncating review comments** — reading 300-char previews instead of full text. Always fetch complete comment bodies before classifying.
- **Reflexive dismissal** — rejecting automated reviewer comments with "by design" or "established pattern" without steelmanning the argument. See disposition criteria in `references/pr-fix.md`.
- **Batch reply without fixing** — replying to all comments in one PR comment instead of addressing each inline. This encourages bulk dismissal.
- Polish without re-running CI afterward
- Simplifying without verifying behavior is preserved
- Skipping simplify because "it works"
- Posting "PR Unblocked" while async reviewers can still add findings
- Merging the PR yourself — your job ends at merge-ready. Never call `gh pr merge`. The human decides when to merge.

## Output

Report per phase:
- **Fix:** conflicts resolved, CI failures fixed, review comments addressed (count + dispositions)
- **Polish:** architecture changes made, test gaps filled, confidence level + evidence
- **Simplify:** complexity removed (LOC delta, modules consolidated, abstractions deleted)
- **Final:** PR URL, merge readiness assessment, any remaining risks
