# /harness engineer

Design harness improvements: hooks, enforcement, context, codification.

## Codification hierarchy

When encoding knowledge, target the highest-leverage mechanism:

```
Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
```

## The Design Test (Norman Principle)

For any harness component, apply the Norman test:

1. **Can an agent make this error?** — The harness allows it. Add prevention.
2. **Does the harness make this error likely?** — The harness induces it. Fix urgently.
3. **After an error, does the response fix the system?** — If not, you're teaching
   burner mappings. Redesign the stove.

Prevention hierarchy: Type system > Hook > Lint > Test > Skill > Prose.
Prose is the burner label. Hooks are the redesigned stove.

## Local CI via Dagger

If the project has a `dagger.json`, it has a Dagger CI pipeline. Run `dagger call check`
to execute all quality gates locally before push. Individual gates are also callable
(e.g., `dagger call lint-shell`). When scaffolding a new project or adding CI,
prefer Dagger (pipelines as code) over GitHub Actions YAML for the inner dev loop.
See spellbook's own `ci/` directory for a reference implementation.

## Hooks are the highest-leverage investment

Hooks run on every tool use. CLAUDE.md is read once. A hook that blocks
`rm -rf` is infinitely more reliable than a CLAUDE.md line saying
"don't delete files." Invest in hooks over prose.

Source of truth: `harnesses/claude/hooks/`

## AGENTS.md is a map, not a manual

Keep AGENTS.md under 100 lines. It should point to deeper sources of truth
(skills, references, docs/) rather than containing all instructions inline.
A monolithic AGENTS.md becomes a graveyard of stale rules.

## Stress-test assumptions

Every harness component encodes an assumption about model limitations.
When a new model drops, audit: is this skill still needed? Is this hook
still catching real problems? Strip what's not load-bearing.

## Thin harness default

Default to a thin harness:

- define agents, tools, prompts, and boundaries
- launch them
- capture raw artifacts
- optionally synthesize with another agent

Do not default to semantic workflow engines, regex recovery of agent structure,
or heavy handoff machinery. If the harness is reasoning about the repo or
recovering meaning from free-form agent prose, that is a strong smell.
