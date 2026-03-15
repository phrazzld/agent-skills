# AI Reviewer Arbitration Policy

## Goal

Reduce duplicate AI review spend while preserving bug-finding depth.

## Default policy

1. One auto-run reviewer per PR.
- Choose one primary reviewer.
- Keep this check required in branch protection.
- No required human approvals for solo-maintainer repos.

2. Secondary reviewers run only when triggered.
- Trigger by `issue_comment` command (`/review claude`), label (`review:deep`), or `workflow_dispatch`.
- Never auto-run all reviewers on every push.

3. Escalate on risk signals.
- Primary reviewer verdict is `WARN` or `FAIL`.
- Changed paths match sensitive patterns (`auth/**`, `billing/**`, `infra/**`, `.github/workflows/**`).
- Diff size crosses threshold (example: `> 800` lines).

4. Keep reviewer prompts adversarial by default.
- In reviewer initialization/execution prompts: explicitly hunt for edge cases,
  break assumptions, and challenge prior reviewer conclusions.
- Do not require rigid evidence templates; allow strong free-form findings plus inline comments.

## Trigger wiring patterns

## `pull_request` default reviewer
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
```

For required reviewer checks, avoid workflow-level `paths` filters. A filtered
required check can fail to run on some PRs and block merges.

## Secondary reviewer on comment
```yaml
on:
  issue_comment:
    types: [created]
jobs:
  review:
    if: ${{ github.event.issue.pull_request && contains(github.event.comment.body, '/review claude') }}
```

## Escalation on label
```yaml
on:
  pull_request:
    types: [labeled]
jobs:
  review:
    if: ${{ github.event.label.name == 'review:deep' }}
```

## Guardrails

- `concurrency.cancel-in-progress: true` on every reviewer workflow.
- Draft PR guard for expensive reviewers.
- Stable check names; avoid changing required check IDs per repo.
- Keep a manual override path for critical releases.
