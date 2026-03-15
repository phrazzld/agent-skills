---
name: org-quality-governance
description: |
  Enforce organization quality policy across org and repos: protected default
  branches, required CI checks, conversation resolution, deterministic gates,
  security defaults (Dependabot + secret scanning + trufflehog), and issue-to-PR
  intent gating. Use when standardizing or auditing CI/CD and reviewer strategy.
disable-model-invocation: true
---

# /org-quality-governance

Apply a machine-first quality baseline without requiring human PR approvals.

## Policy Baseline

1. No required human PR approvals (solo maintainer flow).
2. Protect default branch on every repo (no direct pushes/force pushes/deletes).
3. Require one or more CI checks on every protected default branch.
4. Require conversation resolution.
5. Keep Actions policy permissive: allow all actions, no SHA pinning requirement.
6. Enable security defaults org-wide and repo-wide:
- Dependency graph
- Dependabot alerts and security updates
- Secret scanning and push protection
- Trufflehog workflow in each repo

## Process

1. Audit org + repo baseline (`references/org-baseline.md`).
2. Apply branch/ruleset baseline to all repos (`references/org-baseline.md`).
3. Enforce deterministic CI gate design (`references/repo-gate-template.md`).
4. Enforce issue-to-PR intent contract (`references/intent-gating-contract.md`).
5. Apply reviewer strategy defaults (`references/reviewer-policy.md`).

## Output

```markdown
## Governance Audit
- org defaults: [pass/fail]
- repos protected: [N/N]
- repos with required checks: [N/N]
- repos with conversation resolution: [N/N]
- repos with security defaults + trufflehog: [N/N]

## Intent Gate Coverage
- groom: [pass/fail]
- shape/spec/architect: [pass/fail]
- autopilot/build issue->PR intent link: [pass/fail]

## Reviewer Posture
- config simplicity: [pass/fail]
- adversarial reviewer stance in prompts: [pass/fail]
- deterministic gates integrated: [pass/fail]
```

## References

- `references/org-baseline.md`
- `references/repo-gate-template.md`
- `references/intent-gating-contract.md`
- `references/reviewer-policy.md`
