# Workflow

Use this reference for the ordered `/pr-fix` execution path.

## 1. Assess

Read the PR, the linked issue, and the current check state. Understand what the branch is trying to do before touching conflicts or reviews.

```bash
gh pr view $PR --json number,title,headRefName,baseRefName,mergeable,reviewDecision,statusCheckRollup,isDraft
gh pr checks $PR --json name,state,startedAt,completedAt,link
gh pr view $PR --json body --jq '.body | split("\n")[:80] | join("\n")'
BASE="$(gh pr view $PR --json baseRefName --jq .baseRefName)"
git fetch origin "$BASE"
```

Build a short blocker list:
- conflicts
- failing checks
- open review threads
- actionable bot issue comments
- pending review automation

## 2. Resolve Conflicts

Skip if `mergeable != CONFLICTING`.

Rebase onto base and resolve semantically. Preserve the PR's behavior; integrate upstream structure.

```bash
git rebase "origin/$BASE"
```

Verify locally before moving on.

## 3. Fix CI

Skip if required checks already pass.

Push the current branch, inspect failing jobs, classify the failure, and fix root cause.

```bash
git push --force-with-lease
gh run list --limit 5 --json databaseId,workflowName,status,conclusion,headBranch
gh run view <run-id> --log-failed | tail -n 200
```

If the CI fix creates conflicts, return to step 2.

## 4. Self-Review the Diff

Always do this, even when CI is green.

```bash
BASE="$(gh pr view $PR --json baseRefName --jq .baseRefName)"
git diff "origin/$BASE"...HEAD
```

Look for:
- dead code
- logic bugs
- wasted computation
- wrong log levels
- semantic mismatches between names, comments, and behavior

Fix what you find. Re-run the relevant verification before moving on.
If the branch already has walkthrough or reviewer evidence, check whether self-review changes invalidated it. If so, plan to refresh the artifact before signaling success.

If the PR links an issue with `## Acceptance Criteria`, run `verify-ac` as a secondary check before leaving self-review:
- treat `UNVERIFIED` criteria as a blocker to resolve or defer explicitly before signaling the branch is clean
- treat `PARTIAL` as advisory evidence to report in the PR, not a hard stop by default
- never mark self-review complete while acceptance-criteria drift is still unexplained


## 5. Build the Review Inventory

Read [reconciliation-ledger.md](./reconciliation-ledger.md) and use the inventory script.

```bash
python3 scripts/review_inventory.py $PR > /tmp/pr-fix-review-inventory.json
```

From that inventory, build a working ledger of actionable items across:
- GraphQL review threads
- REST PR review comments
- REST issue comments from bots

For each actionable item, record:
- source
- comment or thread id
- author
- classification: `bug | risk | style | question`
- severity: `critical | high | medium | low`
- decision: `fix now | defer | reject`
- reply status
- thread status

Do not continue while any actionable item lacks a decision.

## 6. Address the Ledger

For each actionable item:
- **fix now**: write the fix, verify it, commit it
- **defer**: create or link a follow-up issue, then reply publicly
- **reject**: reply publicly with reasoning

For every actionable PR review comment:
- reply directly on that thread
- include classification, severity, decision, change, and verification

For every actionable bot issue comment:
- reply explicitly; do not rely on a summary comment elsewhere on the PR

For every actionable review thread:
- resolve it after replying

If a new push or `gh pr ready` retriggers reviewers, the ledger is stale. Rebuild it.

## 7. Verify, Push, and Reconcile Again

```bash
git push --force-with-lease
```

After any push, rerun the review inventory and reconcile again. Do not assume previously closed gaps stayed closed.
After any push that changes behavior, update or regenerate the walkthrough artifact if the old evidence is no longer truthful.

If a review fix breaks CI, go back to step 3.

## 8. Dogfood User-Facing Changes

If the fixes touch UI or user behavior:
- run `/dogfood http://localhost:3000`
- fix P0/P1 findings
- rerun on affected scope

Skip only when the diff is fully internal.

## 9. Settlement Gate

Before signaling success:
- wait for review automation triggered by your last action to settle
- rerun the review inventory after settlement
- verify the ledger is still fully reconciled

Treat these as review automation unless you know the repo says otherwise:
- `CodeRabbit`
- `Greptile`
- `Cerberus`
- `Gemini`
- `Claude`
- `Codex`
- checks named like `review / ...`

Do **not** post `PR Unblocked` while review-related checks are still `QUEUED`, `IN_PROGRESS`, or `PENDING`.

If the repo is known to post delayed findings even after checks complete, require one more quiet poll with no new review items before signaling success.

## 10. Refresh PR Description

If the fix materially changes implementation, evidence, or merge risk, update the PR body and walkthrough.

Before editing, read `../../pr/references/pr-body-template.md`.

Refresh:
- `Why This Matters`
- `Trade-offs / Risks`
- `What Changed`
- `Before / After`
- `Walkthrough`
- `Reviewer Evidence`

Do not leave a text-only or stale walkthrough artifact attached to a branch that has changed since it was recorded.

## 11. Signal

Only after the settlement gate passes, post the PR summary comment:

```bash
gh pr comment $PR --body "$(cat <<'EOF'
## PR Unblocked

**Conflicts**: [resolved N files / none]
**CI**: [green / was: failure type]
**Reviews**: [N fixed, N deferred (#issue), N rejected]
**Open Threads**: 0
**Review Automation**: settled

Ready for re-review.
EOF
)"
```

If the settlement gate fails, do not post this comment.
