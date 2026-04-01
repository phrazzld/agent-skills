# AGENTS.md — Spellbook

Map, not manual. Points to deeper sources of truth.

## Architecture

8 skills, 7 agents. Resist expansion.

**Workflow:** `backlog.d/ → /groom → /shape → /autopilot → /code-review → ship`

**Skills:** autopilot, code-review, groom, harness, investigate, reflect, research, shape.

**Agents:** planner → builder → critic (GAN triad) + ousterhout, carmack, grug, beck (design review bench).

## Orchestration

Non-trivial work uses the planner→builder→critic pipeline.
Planner specs. Builder implements. Critic evaluates. Most conservative reviewer wins.

For serial edits (< 3 files, low risk): skip the pipeline, just do it.

## Skill creation

Use `/harness create` to create skills. `/harness lint` to validate. `/harness eval` to test.
Quality gates: description triggers correctly, < 500 lines, encodes judgment not procedure,
has gotchas section, passes eval baseline comparison.

## Quality bar

TDD default. Fix what you touch. Never lower quality gates.
Never assert model facts from memory — `/research` first.

## Codification

When encoding a learning: type system > lint rule > hook > test > CI > skill > AGENTS.md > memory.
This file is near the bottom. Prefer mechanical enforcement.

## Harness Doctrine

Prefer thin harnesses over semantic orchestration.

- Launch agents, bound them, and record artifacts
- Let agents explore repos and reason for themselves
- If you're adding regexes over agent prose or inventing semantic workflow phases,
  you're probably compensating in the wrong layer
