# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A unified skills monorepo for multi-model AI agents (Claude, Codex, Gemini, Factory, Pi). Markdown-first, with some TypeScript helper scripts and tests (e.g., `core/research/`). Skills are distributed to agent harnesses via symlinks.

**Architecture**: CLAUDE.md for universal norms → Skills for workflows → Packs for domain specialization → MCP for external capabilities.

## Repo Structure

```
agent-skills/
├── core/           # 11 universal skills, synced to ~/.claude/skills/
│   ├── debug/      # Investigate, audit, triage, fix (implicit)
│   ├── research/   # Web search, delegation, validation (implicit)
│   ├── forage/     # Skill discovery + pack activation (implicit)
│   ├── autopilot/  # Full delivery pipeline (DMI)
│   ├── calibrate/  # Mid-session harness postmortem (DMI)
│   ├── groom/      # Backlog grooming and planning (DMI)
│   ├── moonshot/   # Strategic divergent thinking (DMI)
│   ├── pr/         # Commit and open pull requests (DMI)
│   ├── reflect/    # Session retrospective + codification (DMI)
│   ├── settle/     # Fix, polish, simplify PRs (DMI)
│   └── skill/      # Create and update skills (DMI)
├── packs/          # Domain packs, loaded per-project via /forage
│   ├── web/        # Frontend, UI, visual QA, browser testing
│   ├── design/     # Design systems, aesthetics, tokens
│   ├── agent/      # AI/LLM agent infrastructure, skill engineering
│   ├── infra/      # DevOps, sysadmin, security, CI/CD, observability
│   ├── quality/    # Code quality, naming, patterns, linting
│   ├── payments/   # Stripe, Bitcoin, Lightning
│   ├── growth/     # SEO, ads, CRO, content, brand
│   ├── scaffold/   # Project scaffolding and migration
│   └── finance/    # Personal finance workflows
├── docs/
│   └── context/    # Starter cold-memory artifacts for tuned repos
├── scripts/
│   └── sync.sh
└── CLAUDE.md
```

## Core Skills (11)

Only 3 skills compete for automatic model routing. 8 are user-invoked only (DMI = free budget).

| Skill | Mode | Role |
|-------|------|------|
| **debug** | implicit | Investigate, audit, triage, fix |
| **research** | implicit | Web search, delegation, multi-perspective validation |
| **forage** | implicit | Skill discovery, pack activation |
| **autopilot** | DMI | Full delivery: plan → build → ship → settle |
| **calibrate** | DMI | Mid-session harness postmortem |
| **groom** | DMI | Backlog grooming, planning, prioritization |
| **moonshot** | DMI | Strategic divergent thinking |
| **pr** | DMI | Commit and open pull requests |
| **reflect** | DMI | Session retrospective, codification |
| **settle** | DMI | Fix, polish, simplify PRs to merge-ready |
| **skill** | DMI | Create and update agent skills |

Autopilot's sub-commands (`/build`, `/shape`, `/pr`, `/pr-fix`, `/pr-polish`, `/simplify`, `/commit`, `/issue`, `/check-quality`, `/test-coverage`, `/verify-ac`, `/pr-walkthrough`) are routed via its SKILL.md routing table to `references/`.

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

# Auto-detect packs from project dependencies
./scripts/sync.sh detect ~/Development/myproject

# Search pack skills (used by /forage)
./scripts/sync.sh index                # Rebuild pack skill index
```

Harness overlays are applied automatically during sync when present:

```text
overlays/<harness>/<skill>/...
```

Overlay files are merged onto `core/<skill>/` at sync time. Special file:
- `SKILL.append.md` appends harness-specific instructions to `SKILL.md`

Pack loading symlinks skills into the project's `.claude/skills/` and syncs
`audit-references/*.md` into ignored runtime state at
`core/debug/generated-references/` so audit/fix/log-issues can discover them
without mutating tracked source.

No build, lint, or test commands — this repo is documentation only.

## Auto-Sync (git hooks)

Git hooks auto-run `sync.sh all --prune` after pulls and merges, keeping all harness symlinks current. Covers both merge-based (`post-merge`) and rebase-based (`post-rewrite`) pulls.

**New machine setup (one-time):**
```bash
git config core.hooksPath .githooks
```

Manual `sync.sh` is still needed for pack loading and explicit refresh.

## Project Pack Declaration

Add `.claude/packs` to any repo for explicit pack loading:

```
# .claude/packs
payments
growth
```

Read by `sync.sh detect` alongside auto-detection. Committed to git.

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

Core budget: ~1.4K (3 implicit skills). Down from ~10.2K with 67 skills.

## Delivery Pipeline

```
/groom → /autopilot (shape → build → pr → pr-fix → pr-polish → merge)
```

All pipeline steps are sub-capabilities of `/autopilot`, loaded on-demand from `references/`.

## Audit / Fix / Log (via debug)

Absorbed into debug as sub-capabilities:

```
/debug audit stripe          # Domain audit (routes via debug)
/debug fix stripe            # Audit then fix top issue
/debug log-issues production # Create GitHub issues from findings
```

Domain checklists live in `core/debug/references/audit-*.md`. Pack checklists live in
`packs/<pack>/audit-references/` and get symlinked into `core/debug/generated-references/`
when a pack is loaded.

## Umbrella Skills (Absorption Pattern)

Umbrella skills consolidate related capabilities into one budget entry.
Sub-capabilities become `references/{name}.md` files, loaded on-demand.

**Three-level progressive disclosure:** description → SKILL.md body → references loaded on-demand.

```text
core/{umbrella}/
├── SKILL.md          # Routing table
└── references/
    ├── sub-cap-1.md  # Loaded only when needed
    └── sub-cap-2.md  # Zero budget cost
```

Budget scales O(umbrellas), not O(skills). Adding sub-capabilities costs zero.

**Current umbrellas:**
- `core/autopilot/` — 12 absorbed delivery skills
- `core/debug/` — 4 absorbed investigation/audit skills
- `core/reflect/` — 4 absorbed retrospective skills
- `core/research/` — 5 absorbed research/delegation skills

## Adding or Modifying a Skill

Use `/forage agent` to load the agent pack, which contains skill-builder and skill-creator.

**Workflow:**
1. Skill-builder quality gates → pass all 4 (reusable, non-trivial, specific, verified)
2. Classify: core skill (rare — only if universal workflow) vs pack skill (normal)
3. Skill-creator process → understand, plan resources, init, edit, package, iterate
4. Choose invocation mode: default (model+user), DMI (user-only), or reference (auto-load)
5. Follow patterns from existing skills in the same category
6. Run `./scripts/sync.sh all` to distribute

## Principles

- **Deep modules** — hide complexity behind simple interfaces
- **Compose, don't duplicate** — orchestrators call primitives
- **Budget-aware** — use DMI for user-only workflows to keep budget free
- **Packs over core** — domain knowledge goes in packs, discovered via forage
- **Agent-agnostic** — skills work across Claude, Codex, Gemini, Pi

## Artifact Hygiene

Workflow skills must not create merge-conflict bait.

- Default scratch output goes to `/tmp` or another ignored ephemeral directory, not repo-relative shared paths.
- If a durable repo-hosted artifact is truly required, it must use a PR- or branch-unique path such as `walkthrough/pr-123/...` or `walkthrough/<branch-slug>/...`.
- Never require stable shared filenames for PR-local evidence, QA reports, screenshots, or videos.
- Commit artifacts only when the repo explicitly wants them versioned. Otherwise prefer PR bodies, comments, attachments, or temp files.
