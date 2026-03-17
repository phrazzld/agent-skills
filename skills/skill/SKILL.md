---
name: skill
description: |
  Create or update agent skills. Quality gates, classification, structure,
  frontmatter, progressive disclosure, packaging, absorption lifecycle.
  Use when: "create a skill", "make this a skill", "update skill",
  "capture this as a skill", "skill engineering".
disable-model-invocation: true
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
| **Global** | Meta-process, useful everywhere (focus, research, calibrate, reflect, skill) | DMI |
| **Distributable** | Domain or workflow skill, useful across projects | Default or DMI |
| **Project-local** | This-repo-only workflow | DMI typically |

### 3. Create

1. **Understand** — what problem does this solve?
2. **Plan resources** — SKILL.md body vs references/ for progressive disclosure
3. **Init** — create directory, write SKILL.md with frontmatter
4. **Edit** — write the skill body with routing table if umbrella

**For Spellbook skills:**
```bash
mkdir -p skills/{name}/references
# Write skills/{name}/SKILL.md
# Run ./scripts/generate-index.sh
# Run python3 scripts/generate-embeddings.py
# Commit and push
```

**For project-local skills:**
```bash
mkdir -p .claude/skills/{name}
# Write .claude/skills/{name}/SKILL.md
# Do NOT create a .spellbook marker
# Commit with the project
```

### 4. Update

For spellbook skills: edit in the spellbook repo, regenerate index + embeddings.
For project-local skills: edit in place.

For either: if the skill references `skill-builder` or `skill-creator`,
load those for detailed guidance on structure and packaging.

### 5. Absorption (consolidating skills)

When absorbing a standalone skill into an umbrella:
1. Extract SKILL.md body → `references/{name}.md`
2. Merge any existing `references/` with parent prefix
3. Add routing entry to parent's SKILL.md
4. Delete old skill directory
5. Regenerate index + embeddings

### 6. Agents

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
