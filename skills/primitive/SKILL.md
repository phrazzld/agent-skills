---
name: skill
description: |
  Create or update agent skills. Quality gates, classification, structure,
  frontmatter, progressive disclosure, packaging, absorption lifecycle.
  Use when: "create a skill", "make this a skill", "update skill",
  "capture this as a skill", "skill engineering".
argument-hint: "[create|update|absorb] [skill-name]"
---

# /skill

Create, update, or absorb agent skills.

## First Question: Where Does This Skill Live?

Before anything else, determine the destination:

| Destination | When | Location | Marker |
|------------|------|----------|--------|
| **Spellbook** | Reusable across projects. Universal or domain-specific. | `skills/{name}/` in the spellbook repo | N/A (it's the source) |
| **Project-local** | Specific to this project. Not distributable. | `.claude/skills/{name}/` in this repo | **No `.spellbook` marker** |

**Spellbook skills** are the canonical source — `/focus` distributes them to
consuming projects. They live in the spellbook repo's `skills/` directory.

**Project-local skills** live in `.claude/skills/` without a `.spellbook` marker.
Focus will never touch them. They're checked into the project's git repo and
are specific to that project's workflows.

**The `.spellbook` marker means "managed by focus, will be blown away on sync."**
Project-local skills must NOT have this marker.

### Decision Guide

- "Would another project ever use this?" → **Spellbook**
- "Is this specific to how THIS repo works?" → **Project-local**
- "Is this a workflow pattern I keep repeating?" → **Spellbook**
- "Is this about THIS repo's unique deployment/domain?" → **Project-local**

## Process

### 1. Quality Gates

Before creating any skill, pass all 4 gates:

1. **Reusable** — will this be used more than once?
2. **Non-trivial** — is this more than a one-liner for CLAUDE.md?
3. **Specific** — is this concrete enough to be actionable?
4. **Verified** — has this pattern been tested in practice?

If any gate fails, don't create the skill. Suggest the right home:

| Alternative | When |
|------------|------|
| CLAUDE.md rule | Simple convention, one line |
| Hook | Mechanical enforcement, pre/post tool |
| Agent definition | Specialized review persona |
| Memory | User/project preference |

### 2. Classify

| Type | Characteristics | Mode |
|------|----------------|------|
| **Global** | Meta-process, useful everywhere (focus, research, calibrate, reflect, skill) | Non-DMI (must be chainable by other skills) |
| **Distributable** | Domain or workflow skill, useful across projects | Default or DMI |
| **Project-local** | This-repo-only workflow | DMI typically |

### 3. Research and Design (Mandatory for New Skills)

A skill that restates what the model already knows is worthless.
The value of a skill is encoding knowledge the model DOESN'T have:
specific processes, hard-won best practices, integration gotchas,
failure modes, repo-specific conventions, operational patterns.

**Run all three before writing a single line of SKILL.md:**

1. **`/research`** — Find best practices, reference implementations,
   and real-world patterns for this domain. Specifically hunt for:
   - What do experienced practitioners know that isn't obvious?
   - What are the common failure modes and production gotchas?
   - What decisions seem arbitrary but have strong reasons behind them?
   - What's the gap between "works in a tutorial" and "works in production"?
   - What's specific to the current repository's stack/domain combination?

2. **`/context-engineering`** — Design the skill's context architecture:
   - What goes in SKILL.md body (always loaded) vs references/ (on-demand)?
   - What's the progressive disclosure strategy?
   - What context does an agent need at decision time vs research time?

3. **`/harness-engineering`** — Ensure the skill works well in agent workflows:
   - How will the agent invoke this? What triggers loading?
   - What other skills does this chain with?
   - What feedback loops (tests, linters, CI) validate the skill's advice?

**The bar:** After reading the skill, an agent should make decisions a senior
domain specialist would approve — decisions it could NOT make from training
data alone. If the skill doesn't clear that bar, it's not specific enough.

#### Command Surface Design

Default to concentrated, opinionated skills. Use arguments only when they
select between a few stable sub-capabilities inside one coherent domain.

Use arguments when ALL are true:

- The modes belong to one clear mental model (`focus init`, `focus sync`)
- The skill has one obvious no-arg happy path
- The modes share most artifacts, references, and scripts
- The selector list is short and stable, not an expanding menu

Split into separate skills when ANY are true:

- Modes have different trigger language
- Modes need different context packs or references
- Modes have different success criteria or outputs
- The core flow starts depending on flags, not intent words

Treat `argument-hint` as an intent router, not CLI help text. Prefer noun or
verb selectors. Reserve flags for mechanics and rare overrides.

Good:

```yaml
argument-hint: "[init|sync|add|remove] [name]"
```

Bad:

```yaml
argument-hint: "[mode] [name] --draft --no-push --strategy smart --skip-checks"
```

### 4. Create

1. **Understand** — what problem does this solve?
2. **Plan resources** — SKILL.md body vs references/ for progressive disclosure
3. **Init** — create directory, write SKILL.md with frontmatter
4. **Edit** — write the skill body with routing table if umbrella

**For Spellbook skills:**
```bash
mkdir -p skills/{name}/references
# Write skills/{name}/SKILL.md
# Run ./scripts/generate-index.sh
# Optional: run python3 scripts/generate-embeddings.py to prewarm your local cache
# Commit and push
```

**For project-local skills:**
```bash
mkdir -p .claude/skills/{name}
# Write .claude/skills/{name}/SKILL.md
# Do NOT create a .spellbook marker
# Commit with the project
```

### 5. Update

For spellbook skills: edit in the spellbook repo and regenerate `index.yaml`.
Embeddings regenerate locally on first search, or you can prewarm them manually.
For project-local skills: edit in place.

For either: if the skill references `skill-builder` or `skill-creator`,
load those for detailed guidance on structure and packaging.

### 6. Absorption (consolidating skills)

When absorbing a standalone skill into an umbrella:
1. Extract SKILL.md body → `references/{name}.md`
2. Merge any existing `references/` with parent prefix
3. Add routing entry to parent's SKILL.md
4. Delete old skill directory
5. Regenerate `index.yaml` (and optionally prewarm your local embeddings cache)

### 7. Agents

The same managed/unmanaged distinction applies to agents:

| Destination | Location | Marker |
|------------|----------|--------|
| **Spellbook** | `agents/{name}.md` in spellbook repo | N/A (source) |
| **Project-local** | `.claude/agents/{name}.md` in this repo | No marker needed (agents are files, not dirs) |

Focus only manages agent files it installed. Project-local agents
without a matching `.spellbook` marker are left alone.

## Anti-Patterns

- Creating spellbook skills for project-specific knowledge
- Adding `.spellbook` markers to project-local skills (focus will delete them)
- Skipping quality gates because "it seems useful"
- Creating a skill that duplicates an existing one (search embeddings first)
- Shallow skills that are just a checklist (prefer CLAUDE.md or a hook)
- Skipping the research phase — skills without research are just reformatted training data
- Writing generic advice the model already knows instead of specific, hard-won knowledge
- Building mini-CLIs into `argument-hint` instead of keeping one happy path and a few stable selectors
