# Backlog — Spellbook

Ideas, deferred work, someday/maybes. Promoted to GitHub Issues when ready.

*Last updated: 2026-03-17*

## Deferred from GitHub Issues

### Compete skill — three-way agent competition
*Demoted from #8 (2026-03-15). Dependencies (#50 risk tiers, #34 parallel subagent) closed in backlog rebuild.*

Spawn 3 Agent Team workers implementing the same spec independently on separate git worktrees. Evaluation is deterministic where possible (test pass rate, coverage delta, lines changed). Thinktank synthesis as tiebreaker. DMI skill, effort/l.

**Why deferred:** Speculative, high effort, depends on infrastructure that doesn't exist yet. Re-evaluate after Foundation milestone ships.

### Pipeline risk tiers + escalation gates
*Demoted from #50 (2026-03-17). Closed in backlog rebuild — architecture changed.*

Autopilot escalation based on risk classification (routine → complex → critical). Higher risk → more verification, human checkpoints, and parallel approaches.

**Why deferred:** The two-tier architecture changed how skills compose. Risk tier design should wait until registry.yaml (#58) establishes the canonical metadata model.

### Parallel subagent bug fix race
*Demoted from #34 (2026-03-17). Closed in backlog rebuild.*

Test-first parallel subagent competition for /debug — spawn N agents on worktrees, first passing test suite wins.

**Why deferred:** Interesting but speculative. Prove simpler debug patterns first.

## Ideas

### Observation pipeline (calibrate → improve)
`references/improve.md` documents `.spellbook/observations.ndjson` as the observation store, appended by `/calibrate`. But `/calibrate` makes no mention of writing to this file. The observation format is documented, the synthesis flow is documented, but the write path doesn't exist. The feedback loop is paper-only.

**Signal:** User runs `/calibrate` and `/focus improve` finds no observations.

### Cross-repo consumer audit
Repos consuming skills via `/focus` may reference old skill names after the architecture refactor. Need an audit of consuming repos to verify their `.spellbook.yaml` manifests and installed skills are current.

**Signal:** First user report of a broken skill reference in a consuming repo.

### Skill composition graph
Skills compose implicitly (e.g., `/groom` invokes `/research thinktank`, `/autopilot` reads settle references). This composition graph isn't documented anywhere. A generated dependency map could help with impact analysis when modifying skills.

**Signal:** Modifying a skill unexpectedly breaks a downstream skill.

### Skill validation script
A lightweight Python script to validate all SKILL.md files: frontmatter completeness, description length ≤1024 chars, trigger phrases present, reference files exist. Could run as pre-commit hook or CI check.

**Signal:** Shipping a skill with broken frontmatter or missing references.

### Versioned skill artifacts
Currently focus pulls HEAD of master. Tagged releases would enable pinning to a known-good state. Consuming repos could declare `skills: [debug@v2.1]` in manifests.

**Signal:** A breaking change to a skill disrupts a consuming project mid-sprint.

### Language/platform domain skills
Go, Convex, Elixir, Swift/iOS, Python domain skills that capture platform-specific conventions. Add only when 3+ repos share identical patterns.

**Signal:** Same convention duplicated across 3+ project CLAUDE.md files.

## Parked Themes

### Agent competition and verification depth
Compete skill → risk tiers → escalation gates → formal verification. Each step should prove value before building the next. Currently at step 0 (no risk tiers yet).

### Feedback loop infrastructure
calibrate → observations.ndjson → improve → PRs. The full loop from session observation to spellbook improvement. Currently only the synthesis step (/focus improve) is documented.
