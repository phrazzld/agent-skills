---
name: ci-spend-optimizer
description: |
  Audit and reduce GitHub Actions spend across repositories. Use when minutes are
  exhausted, CI is noisy/duplicative, or multiple AI reviewers run together.
  Produces top spend drivers,
  overlap hotspots, and applies concrete workflow changes with tradeoffs.
disable-model-invocation: true
---

# /ci-spend-optimizer

Cut CI cost without gutting signal. Never reduce assurance.

## Process

1. Baseline spend first.
```bash
gh api "/organizations/${ORG}/settings/billing/usage/summary?year=${YEAR}&month=${MONTH}"
gh api "/organizations/${ORG}/settings/billing/usage?year=${YEAR}&month=${MONTH}"
```

2. Rank high-cost repos + workflows.
- Aggregate Linux + macOS minute rows by `repositoryName`.
- Pull completed workflow runs since month start.
- Compute duration proxy: `updated_at - created_at`.
- Rank workflow names by total minutes.

3. Detect AI reviewer overlap.
- Match workflow names for a configured keyword set (for example:
  `claude`, `codex`, `gemini`, `coderabbit`, `greptile`, custom reviewer names).
- Flag repos where primary and secondary reviewers both run automatically.
- Estimate overlap minutes and list top offenders.

4. Apply workflow hygiene in each hot repo.
- Add `concurrency.cancel-in-progress: true`.
- Skip draft PRs for expensive reviewer workflows.
- Keep required workflow present; gate heavy jobs via job-level `if` to avoid stuck required checks.
- Remove duplicate test execution across CI/security workflows.
- Move heavyweight scans to `schedule` + `workflow_dispatch` unless required for every PR.

5. Enforce branch protection baseline.
- Protect default branch from direct pushes.
- Require at least one CI check on every protected branch.
- Require conversation resolution.
- Keep required human approvals at `0` for solo-maintainer repos.

6. Apply AI reviewer arbitration policy.
- Use one default blocking reviewer per repo.
- Make secondary reviewers opt-in (`issue_comment`, label, or manual dispatch).
- Escalate to secondary reviewers only on risk signals (primary reviewer WARN/FAIL, large diff, sensitive paths).
- Keep one stable required check name (for example `merge-gate`).

7. Decide runner strategy by workload.
- Keep fast/unit jobs on GitHub-hosted.
- Move heavy integration/e2e to self-hosted or external CI if minutes are saturated.
- Use the migration matrix in `references/migration-options.md`.

## Acceptance bar

- Monthly minute burn reduced by >=30% on top 5 repos.
- No increase in escaped defects or rollback rate.
- Median PR feedback time unchanged or better.
- Required checks remain deterministic (no flaky naming).
- Branch protection baseline holds on every repo.

## Output format

```markdown
## CI Spend Findings
- [Top repos/workflows + minutes]

## Overlap Findings
- [Repos running primary + secondary reviewers]

## Changes Applied
- [Per-repo workflow edits]

## Top 3 Moves
1. [Move + expected savings + risk]
2. [Move + expected savings + risk]
3. [Move + expected savings + risk]
```

## References

- `references/reviewer-arbitration.md`
- `references/migration-options.md`
- `../org-quality-governance/references/org-baseline.md`
