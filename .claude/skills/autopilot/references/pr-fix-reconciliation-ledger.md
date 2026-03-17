# Reconciliation Ledger

Use this reference during the review phase of `/pr-fix`.

## Purpose

Every actionable review item has a decision, a direct reply, and (for threads) a resolution. Not "counts are zero" — every item reconciled individually.

## Building the Ledger

Fetch comments with `gh`:

```bash
gh api repos/{owner}/{repo}/pulls/$PR/comments --paginate   # inline review comments
gh api repos/{owner}/{repo}/issues/$PR/comments --paginate   # issue comments
gh api repos/{owner}/{repo}/pulls/$PR/reviews --paginate     # PR reviews
```

Read every comment body. Classify each as actionable or non-actionable. Build one ledger row per actionable item.

| source | id | author | finding | decision | replied | resolved |
|--------|----|--------|---------|----------|---------|----------|
| inline | 123 | greptile | empty prompt fallback | fix now | yes | yes |
| issue  | 456 | coderabbit | missing test | fix now | yes | n/a |

Required states:
- `decision`: `fix now | defer | reject`
- `replied`: `yes`
- `resolved`: `yes` for review threads, `n/a` for issue comments

If any actionable row is incomplete, the PR is not unblocked.

## Actionable vs Non-Actionable

Usually actionable:
- bug reports
- security findings
- correctness concerns
- explicit suggestions tied to behavior or recovery
- requests for missing tests

Usually non-actionable:
- pure summaries
- "review in progress" status comments
- check-run dashboards with no concrete ask
- informational bot help text

When unsure, bias toward treating the item as actionable until you classify it explicitly.

## Direct Reply Rule

Do not replace direct replies with a summary comment.

For PR review comments:
- reply on the thread itself
- then resolve the thread

For bot issue comments:
- post a direct response comment that references the specific finding or comment id
- do not rely on a generic "addressed all bot comments" post

For every actionable review thread:
- resolve it after replying

## Settlement Gate

After every push, `gh pr ready`, or explicit bot trigger:
1. wait for review automation to settle
2. reread all PR comments
3. compare against your ledger
4. reconcile any newly-added items

Do not post `PR Unblocked` until the post-settlement read is clean.

Review automation commonly includes:
- `CodeRabbit`
- `Greptile`
- `Cerberus`
- `Gemini`
- `Claude`
- `Codex`
- checks named `review / ...`

If the repo is known to emit comments after the checks finish, require one more quiet poll with no new items.

## Final Verification Checklist

Before signaling success, confirm all of these:
- required CI is green
- no review-related checks are still pending
- actionable ledger rows are fully closed
- unresolved review thread count is zero
- no actionable bot issue comment is left without a response
- no new comments appeared in the final post-settlement read
