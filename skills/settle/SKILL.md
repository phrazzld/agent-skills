---
name: settle
description: |
  Unblock, polish, and merge. Works in two modes:
  GitHub mode (PR exists): fix CI/conflicts/reviews, polish, refactor, land PR.
  Git-native mode (no PR): use verdict refs, Dagger CI, agent swarm review.
  /land alias: validate verdict ref, run Dagger, merge branch.
  Use when: PR is blocked, CI red, review comments open, "land this",
  "get this mergeable", "fix and polish", "unblock", "clean up",
  "make this merge-ready", "address reviews", "fix CI", "land this branch".
  Trigger: /settle, /land (alias), /pr-fix, /pr-polish.
argument-hint: "[PR-number|branch-name]"
---

# /settle

Take a branch from blocked to merge-ready. Fix everything, polish everything, refactor everything.
Dual-mode: works with GitHub PRs or git-native verdict refs.

## Role

Senior engineer who owns the lane end-to-end. Not done until the PR is genuinely
clean — not just "CI green" but architecturally sound, well-tested, and simple.

## Execution Stance

You are the executive orchestrator.
- Keep review-comment disposition, risk tradeoffs, and merge-readiness judgment on the lead model.
- Delegate bounded evidence gathering and implementation to focused subagents.
- Use parallel fanout for independent fixes; serialize when fixes share files or checks.

## Mode Detection

`/settle` operates in two modes based on context:

**GitHub mode** — when `$ARGUMENTS` is a PR number, or `gh pr view` succeeds for
the current branch. Uses GitHub PR state, review threads, and `gh` CLI.

**Git-native mode** — when no PR exists. Uses verdict refs (`scripts/lib/verdicts.sh`),
local Dagger CI, and agent swarm review output. No GitHub API calls.

Detection sequence:
1. If `$ARGUMENTS` matches `^[0-9]+$` → GitHub mode (PR number)
2. If `gh pr view` for current branch succeeds → GitHub mode
3. Otherwise → git-native mode

When invoked as `/land <branch>`, always use git-native mode regardless of
whether a PR exists. `/land` delegates to `scripts/land.sh`, which validates
the verdict ref (must exist and point at HEAD), rejects `dont-ship` verdicts,
runs Dagger CI when available, and merges `--no-ff` to master.
`SPELLBOOK_NO_REVIEW=1` bypasses the verdict gate for emergencies.

## Objective

Take the current branch through three phases until it reaches:
- No merge conflicts
- CI green (Dagger local + GitHub checks in GitHub mode)
- Every review finding addressed
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

### Phase 1: Fix — Unblock

Read `references/pr-fix.md` and follow it completely.

**Goal:** Get from blocked to green.

1. **Conflicts** — rebase or merge, resolve all conflicts
2. **CI** — run `dagger call check` (always). In GitHub mode, also check remote CI.
3. **Self-review** — read the entire diff as a reviewer would
4. **Review findings** —
   - **GitHub mode:** read every PR comment via `skills/settle/scripts/fetch-pr-reviews.sh`
   - **Git-native mode:** run `/code-review` if no verdict ref exists, then read
     `.evidence/<branch>/review-synthesis.md` for findings
   - For each finding: fix (in scope), defer (out of scope → git-bug/backlog), or reject (with reasoning)
5. **Async settlement** —
   - **GitHub mode:** wait for CI checks and bot reviewers; re-check via `gh pr view --json statusCheckRollup,reviews`
   - **Git-native mode:** re-run `dagger call check` after fixes. No async bots to wait for.

Dispatch fixes to smaller worker subagents when scope is clear and bounded.

6. **Merge-readiness verification** —
   - **GitHub mode:** `gh pr view --json reviews,statusCheckRollup` — at least one
     approving review, all checks passing
   - **Git-native mode:** `source scripts/lib/verdicts.sh && verdict_validate <branch>`
     — verdict ref exists and SHA matches HEAD. Plus `dagger call check` passes.

**Exit gate:** CI green, all review findings addressed, merge-readiness verified.

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
6. **Confidence assessment** — how confident are we this won't break anything?
   Treat confidence as an explicit deliverable with evidence.

Use the strongest available model for hindsight review and confidence judgment.
Use smaller workers for narrow polish follow-through once the direction is clear.

**Exit gate:** Architecture clean, tests solid, docs current, confidence stated.

If polish generates changes, return to Phase 1 (CI must stay green).

### Phase 3: Refactor — Reduce complexity

Invoke `/refactor` for this branch and use it as the simplification engine.

**Goal:** Remove complexity that doesn't earn its keep.

1. **Run refactor pass** — invoke `/refactor` and rely on its built-in base-branch auto-detection; pass `--base <branch>` only if auto-detection fails or is ambiguous.
2. **Select one bounded change** — deletion > consolidation > state reduction > naming clarity > abstraction.
3. **Implement + verify** — preserve behavior, run tests, commit.
4. **Validate simplification** — run `assess-simplify` (strong tier) when available.
   `complexity_moved_not_removed` must be false to exit this phase.

**Mandatory when diff >200 LOC net.** For smaller diffs, manual module-depth
review using Ousterhout checks: shallow modules, information leakage,
pass-throughs, compatibility shims with no active contract.

**Exit gate:** No obvious complexity to remove, or explicit justification for keeping it.

If refactor generates changes, return to Phase 1 (CI must stay green).

## Loop Until Done

```text
Phase 1 (fix) → Phase 2 (polish) → Phase 3 (refactor)
       ↑                                      │
       └──────── if changes pushed ───────────┘
```

Each phase that generates commits sends you back to Phase 1 to re-verify
CI and reviews. The loop terminates when a full pass produces no changes.

## Reviewer Artifact Policy

When settlement needs screenshots, videos, logs, or walkthrough proof:

**GitHub mode:**
- Upload screenshots/GIFs to draft GitHub release assets, embed download URLs
  in PR comments. See `skills/demo/references/pr-evidence-upload.md` for the recipe.
- Convert `.webm` → `.gif` before upload (GitHub renders GIFs inline, not video).
- Never use `raw.githubusercontent.com` URLs (breaks for private repos).
- Link the full release at the bottom of every evidence comment.

**Git-native mode:**
- Store evidence in `.evidence/<branch>/<date>/` (LFS-tracked for binaries).
- Write `qa-report.md` and `review-synthesis.md` alongside captures.
- Commit evidence to the branch. It becomes part of the auditable history.
- Convert `.webm` → `.gif` before committing (easier to browse).

**Both modes:**
- Prefer CI artifacts or step summaries for generated verification output.
- Never commit binary evidence directly to tracked git (use LFS or GitHub releases).

## Flags

- `$ARGUMENTS` as PR number — target specific PR
- If no argument, uses the current branch's PR

## Anti-Patterns

- Declaring "done" while CI is still running
- Ignoring review comments instead of addressing them
- **Truncating review comments** — reading 300-char previews instead of full text. Run `skills/settle/scripts/fetch-pr-reviews.sh <PR>` to get complete bodies.
- **Reflexive dismissal** — rejecting automated reviewer comments with "by design" or "established pattern" without steelmanning the argument. See disposition criteria in `references/pr-fix.md`.
- **Batch reply without fixing** — replying to all comments in one PR comment instead of addressing each inline, one at a time.
- Polish without re-running CI afterward
- Refactoring without verifying behavior is preserved
- Skipping refactor because "it works"
- Posting "PR Unblocked" while async reviewers can still add findings
- Merging the PR yourself — your job ends at merge-ready. Never call `gh pr merge`. The human decides when to merge.
- **Git-native mode: merging without a verdict ref.** Always validate via
  `verdict_validate` before merging. No verdict = no merge.

## Output

Report per phase:
- **Fix:** conflicts resolved, CI failures fixed, review comments addressed (count + dispositions)
- **Polish:** architecture changes made, test gaps filled, confidence level + evidence
- **Refactor:** complexity removed (LOC delta, modules consolidated, abstractions deleted)
- **Final:** PR URL, merge readiness assessment, any remaining risks
