# AGENTS.md — Spellbook

Map, not manual. Points to deeper sources of truth.

## Architecture

Core workflow:
`backlog.d/ -> /groom -> /shape -> /autopilot -> /code-review -> /settle -> ship`

Canonical inventory:
- `index.yaml` is the generated source of truth for skill names and descriptions.
- `agents/` is the source of truth for agent definitions.
- Keep this file map-like; do not duplicate inventory lists here.

## Orchestration

Default posture is executive:
- Keep goal-setting, boundaries, synthesis, and final judgment on the lead model.
- Delegate exploration, implementation, brainstorming, and focused critique aggressively.
- Prefer parallel fanout for independent threads; use sequential handoffs only
  when outputs are dependent.

Non-trivial work uses `planner -> builder -> critic`.
Planner specs. Builder implements. Critic evaluates. Most conservative reviewer wins.

For serial edits (<3 files, low risk): skip the full pipeline and execute directly.

## Skill creation

Use `/harness create` to create skills. `/harness lint` to validate. `/harness eval` to test.
Quality gates: description triggers correctly, < 500 lines, encodes judgment not procedure,
has gotchas section, passes eval baseline comparison.
Every workflow skill should state the lead/subagent split explicitly.

## Refactor Cadence

- Feature branch: `/refactor` compares `base...HEAD`, then proposes or applies the
  highest-leverage simplification in the active diff.
- Primary branch (`main`/`master`): `/refactor` runs repo-wide simplification scouting,
  researches prior art, and writes a shaped backlog item by default.
- Use `/refactor --apply` on primary only for low-risk, well-verified edits.

## Quality bar

TDD default. Fix what you touch. Never lower quality gates.
Never assert model facts from memory — `/research` first.

## Product Lens

Spellbook is primarily a product for other repositories. Its own repo is the
proving ground, not the primary customer.

- Prefer reusable primitives, scaffolds, references, and config-driven patterns
  over spellbook-repo-only convenience.
- Treat local automation as validation for downstream adoption, not the end goal.
- If a backlog item only helps this repo, justify the downstream payoff or reshape it.
- Prioritize work by leverage across downstream repos, then by benefit inside spellbook itself.

## Codification

When encoding a learning: type system > lint rule > hook > test > CI > skill > AGENTS.md > memory.
This file is near the bottom. Prefer mechanical enforcement.

## Harness Doctrine

Prefer thin harnesses over semantic orchestration.

- Launch agents, bound them, and record artifacts
- Let agents explore repos and reason for themselves
- If you're adding regexes over agent prose or inventing semantic workflow phases,
  you're probably compensating in the wrong layer
