# Deterministic Gate Template

## Required check contract

Use one stable required check name per repo, for example `merge-gate`.
`merge-gate` depends on deterministic jobs only.

## Deterministic jobs baseline

1. `lint`
2. `typecheck` (if typed language)
3. `test` (unit/integration as applicable)
4. `build` (where relevant)
5. `dep-review` / dependency audit
6. `secret-scan` (Trufflehog or equivalent)

## Workflow design rules

1. Keep required workflow always triggerable on PRs to avoid pending required checks.
2. Gate expensive jobs with job-level `if`, not workflow-level skip for required checks.
3. Enable `concurrency.cancel-in-progress: true`.
4. Keep explicit timeouts for expensive jobs.
5. Keep deterministic jobs blocking; place exploratory/expensive audits behind schedule/manual unless risk path touched.

## Trufflehog baseline

- Add a workflow running trufflehog on PR and push to default branch.
- Include this in required checks or as a dependency of `merge-gate`.
