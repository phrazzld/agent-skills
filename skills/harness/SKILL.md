---
name: harness
description: |
  Harness design, skill engineering, context lifecycle, primitive management.
  Build and maintain the infrastructure that makes agents effective.
  Use when: "create a skill", "update skill", "focus", "sync skills",
  "harness engineering", "context engineering", "tune the harness",
  "add skill", "remove skill", "init spellbook".
  Trigger: /harness, /focus, /skill, /primitive.
argument-hint: "[sync|init|add|remove|search|create|engineer] [target]"
---

# /harness

Build and maintain the infrastructure that makes agents effective.
Covers: skill engineering, primitive management, context lifecycle,
harness design patterns.

## Modes

| Mode | Intent |
|------|--------|
| **sync** | Pull declared primitives from spellbook into project |
| **init** | Analyze project, generate .spellbook.yaml manifest |
| **add/remove** | Manage primitives in .spellbook.yaml |
| **search** | Find relevant skills/agents by description |
| **create** | Create a new skill or agent |
| **engineer** | Design harness improvements (hooks, enforcement, context) |

## Primitive Management (was /focus)

### Sync
Read `.spellbook.yaml`, pull declared skills and agents from GitHub
into project-local harness directories. Nuke-and-rebuild each sync.

### Init
Analyze the project (stack, dependencies, domain), recommend primitives,
generate `.spellbook.yaml`. Interactive — confirm before writing.

### Manifest Format
```yaml
skills:
  - debug
  - autopilot
  - anthropics/skills@frontend-design  # external source
agents:
  - ousterhout
  - grug
```

### Managed vs Unmanaged
Spellbook-managed primitives have a `.spellbook` marker file.
/harness sync only touches directories with this marker.

## Skill Engineering (was /craft-primitive)

### Creating a Skill
1. `skills/{name}/SKILL.md` with frontmatter (name, description, trigger)
2. Optional: `references/`, `scripts/`, `assets/`
3. Keep SKILL.md < 200 lines. Encode judgment, not procedures.
4. Progressive disclosure: description triggers loading → body gives instructions → references for deep context

### Quality Gates for Skills
- Does it encode judgment the model lacks? (If not, delete it)
- Is the description specific enough to trigger correctly?
- Is it < 200 lines? (If not, extract to references)
- Does it have an oracle (definition of done)?

## Context Engineering (was /context-engineering)

### Principles
- Write context for machines, not humans
- Progressive disclosure: load only what's needed
- Authority order: tests > type system > code > docs > lore
- Staleness kills: stale context is worse than no context

### Codification Hierarchy
When encoding knowledge, use the highest-leverage mechanism:
```
Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
```

## Harness Engineering

### Core Principle
The harness is the product. Models are commodities. Leverage comes from
persistent context infrastructure.

### Mechanical Enforcement
A rule in CLAUDE.md is a suggestion. A lint rule is a law. A test is physics.

### Stress-Test Assumptions
Every harness component encodes an assumption about model limitations.
When a new model drops, re-examine: is this still load-bearing?
Strip what's not.

### Hooks (Claude Code)
Enforcement scripts in `harnesses/claude/hooks/`. Highest-leverage
codification target — they run on every tool use, not just when the
model remembers to check.

## Related

- `/reflect` — uses codification hierarchy when extracting learnings
- `/groom` — scaffold mode bootstraps projects with harness infrastructure
- `/autopilot` — the workflow that the harness supports
