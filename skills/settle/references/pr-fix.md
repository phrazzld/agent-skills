# Phase 1: Fix — Unblock the PR

Get from blocked to green. Conflicts resolved, CI passing, every review comment addressed.

## Self-Review Protocol

Before touching reviewer comments:

1. Read the entire diff as if seeing it for the first time
2. Each file change must serve the PR's stated goal — remove what doesn't
3. Strip debug artifacts, commented-out code, TODO placeholders
4. Verify commit messages accurately describe what changed

Self-review catches problems before reviewers do. Fix anything found here
before responding to comments.

## Conflict Resolution

```
fetch origin
  │
  ├─ Few commits, linear history matters, no downstream consumers → rebase
  │    git rebase origin/main
  │
  └─ Many commits, shared branch, complex conflicts → merge
       git merge origin/main
```

**Always:**
- `git fetch origin` first
- Never rebase published shared branches
- Understand both sides before choosing a resolution
- Read the PR description and commit messages for intent
- Prefer the version that matches the spec

**Conflict resolution heuristic:** When both sides changed the same code,
the version aligned with the PR's stated goal wins. When unclear, preserve
the more defensive / more tested version.

## CI Failure Diagnosis

Read the actual logs. Don't guess from the check name.

### Root Cause Categories

| Category | Signal | Action |
|----------|--------|--------|
| Real regression | Test fails deterministically, passes on base branch | Find breaking commit (`git bisect` if needed), fix root cause |
| Flaky test | Passes on retry, no code change | Re-run once. If green, file git-bug issue for the flake. Don't ignore. |
| Environment | Runner version mismatch, cache miss, Docker pull failure | Check runner versions, dependency caches, base images |
| Dependency | Upstream package broke, yanked version, incompatible update | Pin or update dependency, verify lockfile |

### Diagnosis Sequence

1. `gh run view RUN-ID --log-failed` — read the actual failure
2. Identify which test/step failed and the error message
3. Check: does this test pass on the base branch? (`git stash && git checkout main && run test`)
4. If flaky: re-run once via `gh run rerun RUN-ID --failed`
5. If real: find the breaking commit, fix the root cause, push

### Never

- Disable tests to make CI green
- Add retry loops around flaky assertions
- Lower coverage thresholds or lint strictness
- Mark failing checks as "expected failure"

These are not fixes. They are debt with compound interest.

## Review Comment Triage

Read every comment on the PR. Classify and act:

### In scope, valid

Fix it. Commit with a message referencing the feedback. Reply confirming
the fix with the commit SHA.

```
Fixed in abc1234 — switched to the connection pool pattern you suggested.
```

### Valid but out of scope

Create a git-bug issue or `backlog.d/` item. Reply linking the issue.
Explain why it's deferred — scope boundary, not dismissal.

```
Good catch. Filed as backlog.d/042-connection-pool-config.md — out of scope
for this PR but should land before the next release.
```

### Invalid

Reply with clear, specific reasoning. Reference code, tests, or docs that
support your position. Be respectful but firm.

```
The current approach handles this via X (see src/pool.ts:42). The suggested
change would break the invariant documented in ARCHITECTURE.md § Connection
Lifecycle. Happy to discuss further if I'm missing context.
```

### Questions (not requests)

Answer clearly. If the answer reveals a documentation gap, fix the gap
in the same PR.

## Async Settlement

After pushing fixes, do not declare Phase 1 complete. Automation may
still be running:

1. Wait for all CI checks to reach terminal state (pass/fail, not pending)
2. Wait for bot reviewers (linters, security scanners, coverage bots) to post
3. Re-check: `gh pr view --json statusCheckRollup,reviews`
4. If new findings appeared, triage them — loop back to the relevant section

### Merge-Readiness Gate

Before exiting Phase 1:

```bash
gh pr view --json reviews,statusCheckRollup
```

Verify:
- At least one approving review
- All status checks passing
- No unresolved review threads
- No pending bot reviews

If any condition fails, address the gap or escalate. Do not proceed to Phase 2.

## Exit Criteria

Phase 1 is complete when ALL of:

- [ ] No merge conflicts
- [ ] CI green (all checks passing, not pending)
- [ ] Every review comment addressed (fixed, deferred with issue, or rejected with reasoning)
- [ ] No open/unresolved review threads
- [ ] Merge-readiness gate passes

If already green and settled on entry, skip to Phase 2.
