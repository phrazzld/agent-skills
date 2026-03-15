# Intent Gating Contract

Intent is authored in the GitHub issue and referenced in the PR.

## Issue requirements

Every implementation issue must include:

1. `## Product Spec`
2. `### Intent Contract`
- Intent (what must be true after shipping)
- Success conditions
- Hard boundaries
- Non-goals
3. `### Acceptance Criteria` (Given/When/Then)
4. `### Verification` (deterministic commands)

## PR requirements

Every PR implementing an issue must include:

1. `Closes #N`
2. `## Intent Reference` section
3. Summary of intent contract copied from issue
4. Acceptance criteria checklist status

## Skill integration points

- `groom`: emits issues with intent contract.
- `shape/spec/architect`: drafts and locks intent contract.
- `autopilot` and `build`: block implementation until intent contract exists.
