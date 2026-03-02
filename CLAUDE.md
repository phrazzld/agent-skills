# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A unified skills monorepo (~74 skills) for multi-model AI agents (Claude, Codex, Gemini, Factory, Pi). Markdown-first, with some TypeScript helper scripts and tests (e.g., `core/web-search/`). Skills are distributed to agent harnesses via symlinks.

## Repo Structure

```
agent-skills/
├── core/           # ~74 skills, synced to ~/.claude/skills/
│   ├── groom/
│   ├── autopilot/
│   ├── build/
│   └── ...
├── packs/          # Domain packs, loaded per-project on demand
├── scripts/
│   └── sync.sh
└── CLAUDE.md
```

## Key Commands

```bash
# Sync core skills to agent harnesses
./scripts/sync.sh claude            # → ~/.claude/skills/
./scripts/sync.sh codex             # → ~/.codex/skills/ (skips .system)
./scripts/sync.sh gemini            # → ~/.gemini/skills/
./scripts/sync.sh all               # All harnesses
./scripts/sync.sh claude --dry-run  # Preview without changes

# Prune stale symlinks (for deleted skills)
./scripts/sync.sh --prune claude
./scripts/sync.sh --prune all

# Load a domain pack into a project
./scripts/sync.sh pack marketing ~/Development/myproject
./scripts/sync.sh pack marketing --global
```

No build, lint, or test commands — this repo is documentation only.

## Skill Directory Convention

Every skill lives in `core/{skill-name}/` with a required `SKILL.md`:

```
core/{skill-name}/
├── SKILL.md          # Required. Frontmatter + skill definition.
├── AGENTS.md         # Optional. Multi-agent guidance.
└── references/       # Optional. Supporting docs, templates.
```

No README.md in skill dirs (prohibited).

## SKILL.md Frontmatter

```yaml
---
name: skill-name
description: |
  [What it does] + [When to use it / trigger phrases] + [Key capabilities]
user-invocable: false                  # Optional. Reference skills only.
disable-model-invocation: true         # Optional. User-only workflows (free — no budget cost).
argument-hint: "[optional example]"    # Optional. Shown in /menu.
---
```

## Invocation Modes & Budget

Claude Code has a ~16K char description budget. Skills consume budget based on mode:

| Mode | Frontmatter | Invoked By | Budget Cost |
|------|-------------|------------|-------------|
| Model+User | (default) | Both | **Consumes budget** |
| Reference | `user-invocable: false` | Auto-loaded by model | **Consumes budget** |
| DMI | `disable-model-invocation: true` | User via `/command` | **Free** |

Current split: ~26 budget-consuming + ~48 DMI = ~74 total. Well within 16K.

## Core Delivery Pipeline

```
/groom → /shape → /autopilot → /pr-fix → /pr-polish → merge
```

`/autopilot` chains shape → build → pr with commit/PR behavior inlined.

## Unified Audit / Fix / Log

Three unified skills replace all domain-specific check-*/fix-*/log-* skills:

```
/audit stripe          # Domain audit (dispatches via argument)
/fix stripe            # Domain fix (model-invocable for autonomous work)
/log-issues production # Create GitHub issues from audit findings
```

Domain checklists live in `audit/references/`, `fix/references/`.

## Adding a Skill

1. Create `core/{name}/SKILL.md` with frontmatter
2. Choose invocation mode: default (model+user), DMI (user-only), or reference (auto-load)
3. Follow patterns from existing skills in the same category
4. Run `./scripts/sync.sh all` to distribute

## Principles

- **Deep modules** — hide complexity behind simple interfaces
- **Compose, don't duplicate** — orchestrators call primitives
- **Budget-aware** — use DMI for user-only workflows to keep budget free
- **References auto-load** — `user-invocable: false` skills provide ambient context
- **Agent-agnostic** — skills work across Claude, Codex, Gemini, Pi
