---
name: code-review
description: |
  Parallel multi-agent code review. Launch reviewer team, synthesize findings,
  auto-fix blocking issues, loop until clean.
  Use when: "review this", "code review", "is this ready to ship",
  "check this code", "review my changes".
  Trigger: /code-review, /review, /critique.
argument-hint: "[branch|diff|files]"
---

# /code-review

Launch a parallel team of reviewers. Synthesize findings. Fix blocking issues
automatically. Loop until clean or escalate to human.

## Workflow

Launch 3-5 subagents to review changes from distinct perspectives. Ousterhout,
Grug, and Carmack are great choices, generally. You may want to pick others,
or define your own ad-hoc, that are more specifically focused on the current
repo and the changes being reviewed. All reviewers run as **Explore type**
(read-only). For blocking fixes, dispatch **builder** (general-purpose type).

Collect all verdicts. Deduplicate overlapping concerns. Rank by severity.

**Any Don't Ship** → spawn a builder sub-agent for each blocking concern, giving it the specific file:line and fix instruction. Builder fixes, runs tests. Then re-review (return to step 2). Max 3 iterations.

## Live Verification

**Trigger:** the diff touches files matching user-facing patterns — `.tsx`, `.jsx`,
`pages/`, `app/`, `routes/`, `api/`, `endpoints/`, or component directories.
Determine this by scanning the diff file list.

**Rule:** when triggered, at least one reviewer must exercise the affected
routes/components (run the app, hit the endpoint, render the component).
"Ship" verdict is **blocked** until live verification passes.

**Skip:** pure refactors, config-only changes, test-only changes, and
backend-only changes with no user-facing surface skip live verification.

**Failure:** if live verification fails or cannot be performed, verdict is
"Don't Ship" with reason: "live verification not performed/failed."

### Plausible-but-Wrong Patterns

LLMs optimize for plausibility, not correctness. Reviewers must actively hunt for code that *looks right* but isn't:
- Wrong algorithm complexity (O(n²) where O(log n) is needed)
- Unnecessary abstractions (82K lines vs 1-line solution)
- Stub implementations that pass tests but don't actually work
- "Specification-shaped" code — right module names, wrong behavior
- Missing invariant checks that only matter at scale

## Simplification Pass

After review passes, if diff > 200 LOC net:
- Look for code that can be deleted
- Collapse unnecessary abstractions
- Simplify complex conditionals
- Remove compatibility shims with no real users

## Review Scoring

After the final verdict, append one JSON line to `.groom/review-scores.ndjson`
in the target project root (create `.groom/` if needed):

```json
{"date":"2026-03-30","pr":42,"correctness":8,"depth":7,"simplicity":9,"craft":8,"verdict":"ship"}
```

- Scores (1-10) reflect bench consensus, not any single reviewer.
- `pr` is the PR number, or `null` when reviewing a branch without a PR.
- `verdict`: `"ship"`, `"conditional"`, or `"dont-ship"`.
- This file is committed to git (not gitignored). `/groom` reads it for quality trends.

## Gotchas

- **Self-review leniency:** Models consistently overrate their own work. Reviewers must be separate sub-agents, not the builder evaluating itself.
- **Reviewing the whole codebase:** Review the diff, not the repo. `git diff main...HEAD` is the scope.
- **Skipping the bench:** Running only the critic misses structural issues. The philosophy agents add perspectives the critic doesn't cover.
- **Treating all concerns equally:** Blocking issues (correctness, security) gate shipping. Style preferences don't.
