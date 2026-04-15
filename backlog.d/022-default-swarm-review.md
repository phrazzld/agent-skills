# Make agent swarm review the mandatory default

Priority: high
Status: pending
Estimate: M

## Goal

Wire `/code-review` into `/deliver` and `/settle` so that agent swarm review
is mechanically enforced, not optional. No branch can land without a verdict.

## Changes

- `/deliver` must run `/code-review` after build, before declaring "ready"
- `/settle` (git-native mode from 021) must require a verdict ref
- Pre-merge git hook validates verdict ref exists
- `/settle` must trigger `/code-review` if no verdict exists for the branch

## Multi-Provider Default

The recent multi-provider review (thinktank + codex + gemini) should be the
default path, not single-model review. This gives diverse perspectives and
catches model-specific blind spots.

## Oracle

- [ ] `/deliver` pipeline includes code review step that produces verdict
- [ ] `/land` refuses without verdict ref
- [ ] Pre-merge hook blocks `git merge` without verdict
- [ ] Skipping review requires explicit `--no-review` flag (escape hatch)

## Non-Goals

- Requiring human review (agent review is sufficient for merge)
- Blocking on individual reviewer disagreement (synthesis decides)
