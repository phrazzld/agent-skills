# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## What This Repo Is

**Spellbook** — a centralized library of agent primitives (skills and agents) for multi-model AI harnesses (Claude Code, Codex, Pi, Factory, Gemini). Markdown-first. Distributed to projects via the `/focus` skill, which pulls primitives from GitHub into local harness directories.

**Architecture**: Flat skill library → Manifest-driven activation → Harness-specific installation.

## Repo Structure

```
spellbook/
├── skills/              # ALL skills, flat (72 skills)
│   ├── focus/           # Meta-skill: manages primitive activation
│   ├── debug/           # Investigate, audit, triage, fix
│   ├── autopilot/       # Full delivery pipeline
│   ├── stripe/          # Stripe integration patterns
│   └── ...
├── agents/              # Agent definitions, flat
├── collections.yaml     # Named groups of skills (payments, web, etc.)
├── index.yaml           # Generated catalog for discovery
├── bootstrap.sh         # One-command install of focus skill
├── scripts/
│   ├── generate-index.sh
│   └── sync.sh          # Legacy — being replaced by /focus
├── overlays/            # Legacy — harness-specific skill customizations
├── docs/
└── CLAUDE.md
```

## How It Works

### For consumers (other repos)

1. **Bootstrap** (one-time per machine): `curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/main/bootstrap.sh | bash`
2. **Init** (per project): Run `/focus init` — analyzes project, generates `.spellbook.yaml`
3. **Sync**: Run `/focus` — pulls declared primitives from GitHub into local harness dirs
4. **Manage**: `/focus add stripe`, `/focus remove moonshot`, `/focus search webhook`

### Manifest format (.spellbook.yaml)

```yaml
skills:
  - debug
  - autopilot
  - groom
collections:
  - payments
agents: []
```

Checked into git. Harness-agnostic. Collections resolve via `collections.yaml`.

### Managed vs Unmanaged

Spellbook-managed primitives have a `.spellbook` marker file in their directory.
`/focus` only touches directories with this marker. Project-specific skills
without a marker are invisible to Spellbook and never modified.

## Primitives

Two types: **skills** and **agents**.

### Skills

A directory with a `SKILL.md` file following the [Agent Skills spec](https://agentskills.io):

```
skill-name/
├── SKILL.md          # Required. Frontmatter + instructions.
├── references/       # Optional. Supporting docs loaded on-demand.
├── scripts/          # Optional. Executable code.
└── assets/           # Optional. Templates, resources.
```

### Agents

Agent definitions for harness subagent systems. Format varies by harness
(Markdown for Claude Code, TOML for Codex). Spellbook stores in a canonical
format and `/focus` translates per-harness.

## SKILL.md Frontmatter

```yaml
---
name: skill-name
description: |
  [What it does] + [When to use it / trigger phrases] + [Key capabilities]
disable-model-invocation: true    # Optional. User-only (zero budget in Claude Code).
argument-hint: "[example args]"   # Optional. Shown in skill menu.
---
```

## Collections

Named groups of skills defined in `collections.yaml`:

```yaml
payments:
  description: Payment processing, billing, and financial integrations
  skills: [stripe, bitcoin, lightning]
```

Use in manifests: `collections: [payments]` expands to individual skills.

## Key Commands

```bash
# Generate the skill index (run after adding/modifying skills)
./scripts/generate-index.sh

# Legacy sync (being replaced by /focus)
./scripts/sync.sh claude
```

## Adding a Skill

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Add references/, scripts/, assets/ as needed
3. Add to relevant collection in `collections.yaml` (if applicable)
4. Run `./scripts/generate-index.sh` to update the index
5. Commit and push — consumers get it on next `/focus sync`

## Principles

- **Flat over nested** — every skill at `skills/{name}/`, no hierarchy
- **Manifest-driven** — projects declare what they need, focus delivers it
- **Harness-agnostic** — primitives work across Claude Code, Codex, Pi, Factory
- **Nuke and rebuild** — focus deletes and recreates managed primitives each sync
- **Marker-based ownership** — `.spellbook` file distinguishes managed from unmanaged
- **Progressive disclosure** — description → SKILL.md body → references on-demand
- **GitHub as source of truth** — focus pulls from GitHub, works on any machine

## Artifact Hygiene

- Default scratch output goes to `/tmp`, not repo-relative paths
- Never require stable shared filenames for PR-local evidence
- Commit artifacts only when the repo explicitly wants them versioned
