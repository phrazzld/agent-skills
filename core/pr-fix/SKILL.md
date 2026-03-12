---
name: pr-fix
description: |
  Unblock a PR end-to-end: resolve conflicts, fix CI, self-review the diff, reconcile every review comment, and wait for async reviewers to settle before declaring success.
  Use when: PR blocked, CI red, open review threads remain, bot comments keep reopening, or a branch looks green but is not actually review-clean.
  Trigger: /pr-fix, /fix-ci, /review-branch, /review-and-fix, /respond, /address-review, /refactor.
argument-hint: "[PR-number]"
---

# /pr-fix

Take a PR from blocked to actually mergeable.

## Role

Senior engineer unblocking a PR. Think like an owner, not a task runner.

## Objective

Take PR `$ARGUMENTS` (or the current branch PR) to this state:
- no merge conflicts
- required CI green
- self-review complete
- every actionable review item handled
- no open review threads
- no misleading "PR Unblocked" comment while review automation can still add findings
- durable PR evidence still truthful after the last fix or push

## Latitude

- Use judgment on whether feedback should be fixed now, deferred, or rejected.
- Prefer deterministic tooling for exact inventory and state checks.
- Prefer model reasoning for semantic triage, scope decisions, and reviewer synthesis.

## Non-Negotiable Invariants

1. **Inventory beats counts.** Do not trust a green merge button, `reviewDecision`, or a single unresolved-thread count. Build a full review inventory and reconcile each item.
2. **Reply per item.** Aggregate "covered above" comments are not enough for actionable review findings.
3. **Settle async reviewers before signaling success.** After every push, `gh pr ready`, or any action that can retrigger bots, rerun the review inventory after reviewer activity settles.
4. **No quality-gate downgrades.** Fix the code or the tests. Do not weaken thresholds.
5. **Evidence must stay current.** If a fix changes behavior, verification, or review confidence, refresh the walkthrough and reviewer evidence before signaling success.

## Dependency Order

Conflicts -> CI -> Self-Review -> Review Reconciliation -> Settlement -> Signal

## Core Workflow

Read [references/workflow.md](./references/workflow.md) and execute the phases in order:
- assess the PR and list blockers
- resolve conflicts first
- fix CI before arguing with reviewers
- self-review the diff
- build a deterministic review inventory
- reconcile every actionable item with a decision and direct reply
- push, rerun inventory, and reconcile again
- wait for async reviewers to settle
- update the PR body if the implementation or evidence changed
- only then post the unblocked summary

`dogfood`, `agent-browser`, and `browser-use` are available for user-flow verification when the diff is user-facing.

## Required References

- Review reconciliation: [references/reconciliation-ledger.md](./references/reconciliation-ledger.md)
- Detailed unblock sequence: [references/workflow.md](./references/workflow.md)

## Required Tooling

Use the inventory script during review reconciliation:

```bash
python3 scripts/review_inventory.py $PR > /tmp/pr-fix-review-inventory.json
```

That inventory is mandatory and is the source of truth for review cleanup.

## Hard Stop Rules

Do not post `PR Unblocked` if any of these are still true:
- required CI is failing
- review-related checks are `QUEUED`, `IN_PROGRESS`, or `PENDING`
- any actionable review item lacks a decision
- any actionable PR review comment lacks a direct reply
- any actionable review thread remains unresolved
- the post-settlement inventory changed and has not been reconciled
- the PR walkthrough or reviewer evidence is stale, text-only, or no longer proves the current branch state

## Retry Policy

Max 2 full-pipeline retries when one phase breaks another. After 2, stop and summarize clearly for the user.

## Anti-Patterns

- Treating `mergeable=MERGEABLE` as proof the PR is review-clean
- Posting `PR Unblocked` before reviewer settlement
- Using counts without reconciling individual comment ids
- Replying with one aggregate comment instead of per-finding responses
- Resolving threads without verifying the code actually matches the reply
- Ignoring older comments because newer checks are green
- Trusting prior "fixed" or "unblocked" comments without rebuilding the inventory

## Output

Summarize:
- blockers found
- phases executed
- CI fixes applied
- review items fixed / deferred / rejected
- final check status
- explicit confirmation that the review inventory is closed

## Absorbed Skills (References)

- **fix-ci** — [references/fix-ci.md](./references/fix-ci.md)
- **review-branch** — [references/review-branch.md](./references/review-branch.md)
