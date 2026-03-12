# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A unified skills monorepo for multi-model AI agents (Claude, Codex, Gemini, Factory, Pi). Markdown-first, with some TypeScript helper scripts and tests (e.g., `core/research/`). Skills are distributed to agent harnesses via symlinks.

Core skills, domain packs, and repo-local skills for AI coding agents. Skills are added, absorbed, and reorganized over time, so avoid hard-coding inventory counts in docs.

## Repo Structure

```
agent-skills/
├── core/           # Universal skills, synced to ~/.claude/skills/
│   ├── groom/
│   ├── autopilot/
│   ├── build/
│   └── ...
├── packs/          # Domain packs, loaded per-project on demand
│   ├── payments/   # Payment-focused skills and checklists
│   ├── growth/     # Growth and marketing skills
│   ├── scaffold/   # Project scaffolding and migration skills
│   └── finance/    # Personal finance workflows
├── docs/
│   └── context/    # Starter cold-memory artifacts for tuned repos
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
./scripts/sync.sh pack payments ~/Development/cerberus
./scripts/sync.sh pack growth ~/Development/cerberus-web
./scripts/sync.sh pack finance --global
```

Harness overlays are applied automatically during sync when present:

```text
overlays/<harness>/<skill>/...
```

Overlay files are merged onto `core/<skill>/` at sync time. Special file:
- `SKILL.append.md` appends harness-specific instructions to `SKILL.md`

Pack loading symlinks skills into the project's `.claude/skills/` and syncs
`audit-references/*.md` into ignored runtime state at
`core/audit/generated-references/` so audit/fix/log-issues can discover them
without mutating tracked source.

No build, lint, or test commands — this repo is documentation only.

## Auto-Sync (git hooks)

Git hooks auto-run `sync.sh all --prune` after pulls and merges, keeping all harness symlinks current. Covers both merge-based (`post-merge`) and rebase-based (`post-rewrite`) pulls.

**New machine setup (one-time):**
```bash
git config core.hooksPath .githooks
```

Manual `sync.sh` is still needed for pack loading and explicit refresh.

## Skill Directory Convention

Core skills live in `core/{skill-name}/`.
Pack skills live in `packs/{pack-name}/{skill-name}/`.
Every skill directory needs a required `SKILL.md`:

```
{core|packs/<pack>}/{skill-name}/
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

Keep the budget-consuming surface lean. Prefer DMI for user-only workflows, and use packs for per-project specialization so the global core stays within budget.

## Core Delivery Pipeline

```
/groom → /shape → /autopilot → /pr-fix → /pr-polish → merge
```

`/autopilot` chains shape → build → walkthrough → pr with commit/PR behavior inlined.

## Unified Audit / Fix / Log

Three unified skills replace all domain-specific check-*/fix-*/log-* skills:

```
/audit stripe          # Domain audit (dispatches via argument)
/fix stripe            # Domain fix (model-invocable for autonomous work)
/log-issues production # Create GitHub issues from audit findings
```

Core domain checklists live in `core/audit/references/`. Pack checklists live in
`packs/<pack>/audit-references/` and get symlinked into ignored runtime state at
`core/audit/generated-references/` when a pack is loaded via
`sync.sh pack <name>`. Audit/fix/log-issues discover available domains
dynamically by scanning both checklist directories.

## Umbrella Skills (Absorption Pattern)

Umbrella skills consolidate related standalone skills into one budget entry.
Sub-capabilities become `references/{name}.md` files, loaded on-demand.

**Three-level progressive disclosure:** description → SKILL.md body → one or more references loaded on-demand.

```text
core/{umbrella}/
├── SKILL.md          # Routing table (consumes budget)
└── references/
    ├── sub-cap-1.md  # Former standalone skill body
    └── sub-cap-2.md  # Loaded only when needed
```

Budget scales O(umbrellas), not O(skills). Adding sub-capabilities costs zero.

**Canonical examples:**
- `core/design/` — 11 absorbed skills, mode-based routing
- `core/audit/` — dynamic domain routing (`/audit stripe`)
- `core/research/` — 4 absorbed skills (web-search, delegate, thinktank, introspect)

See `skill-builder` (absorption lifecycle) and `skill-creator` (umbrella creation process).

## Adding or Modifying a Skill

**Always use both skill engineering skills:**

1. **`/skill-builder`** (reference, auto-loaded) — Quality gates, classification (foundational vs workflow), when to create. Consult first to decide *whether* to create and *what kind*.
2. **`/skill-creator`** (DMI, `/skill-creator`) — Structure, frontmatter, progressive disclosure, packaging. Follow its process for *how* to create well.

**Workflow:**
1. `/skill-builder` quality gates → pass all 4 (reusable, non-trivial, specific, verified)
2. Classify: foundational (`user-invocable: false`) vs workflow (default/DMI)
3. `/skill-creator` process → understand, plan resources, init, edit, package, iterate
4. Choose invocation mode: default (model+user), DMI (user-only), or reference (auto-load)
5. Follow patterns from existing skills in the same category
6. Run `./scripts/sync.sh all` to distribute

## Principles

- **Deep modules** — hide complexity behind simple interfaces
- **Compose, don't duplicate** — orchestrators call primitives
- **Budget-aware** — use DMI for user-only workflows to keep budget free
- **References auto-load** — `user-invocable: false` skills provide ambient context
- **Agent-agnostic** — skills work across Claude, Codex, Gemini, Pi

## Artifact Hygiene

Workflow skills must not create merge-conflict bait.

- Default scratch output goes to `/tmp` or another ignored ephemeral directory, not repo-relative shared paths.
- If a durable repo-hosted artifact is truly required, it must use a PR- or branch-unique path such as `walkthrough/pr-123/...` or `walkthrough/<branch-slug>/...`.
- Never require stable shared filenames for PR-local evidence, QA reports, screenshots, or videos.
- Commit artifacts only when the repo explicitly wants them versioned. Otherwise prefer PR bodies, comments, attachments, or temp files.
