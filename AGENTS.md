# AGENTS.md — agent-skills

## Scope
- agent-skills repository-specific Pi foundation.
- Optimized for local agent workflows.

## Engineering doctrine
- Root-cause remediation over symptom patching.
- Favor convention over configuration.

## Skill creation/modification

When creating or modifying any skill, always compose both skill engineering skills:

- **`skill-builder`** — decision layer: quality gates (reusable? non-trivial? specific? verified?), foundational vs workflow classification, proactive creation triggers
- **`skill-creator`** — execution layer: structure, frontmatter, progressive disclosure, bundled resources, packaging

Never hand-write a skill without consulting both. They complement — builder decides *whether and what kind*, creator decides *how*.

## Quality bar
- Ensure local tests pass before merge.
- Meaningful test coverage over line-count gaming.
