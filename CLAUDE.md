# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## What This Repo Is

**Spellbook** — a centralized library of agent primitives (skills and agents) for multi-model AI harnesses (Claude Code, Codex, Pi, Factory, Gemini). Markdown-first. Distributed to projects via the `/focus` skill, which pulls primitives from GitHub into local harness directories.

**Architecture**: Flat skill library → Embeddings-based discovery → Manifest-driven activation → Harness-specific installation.

## Repo Structure

```
spellbook/
├── skills/                  # All skills, flat
│   ├── focus/               # Meta-skill: manages primitive activation
│   ├── research/            # Multi-source web research
│   ├── debug/               # Investigate, audit, triage, fix
│   ├── autopilot/           # Full delivery pipeline
│   └── ...
├── agents/                  # Agent definitions, flat (markdown + YAML frontmatter)
├── registry.yaml            # Single source of truth: globals, sources, collections
├── embeddings.json          # Pre-computed Gemini Embedding 2 index (all sources)
├── bootstrap.sh             # Installs global skills (reads registry.yaml)
├── .spellbook.yaml          # This repo's own manifest
└── scripts/
    ├── generate-embeddings.py  # Rebuild embeddings.json (sources from registry.yaml)
    └── search-embeddings.py # Query the embeddings index
```

## How It Works

### For consumers (other repos)

1. **Bootstrap** (once per machine): `curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/master/bootstrap.sh | bash`
2. **Init** (per project): `/focus init` — analyzes project via embeddings, generates `.spellbook.yaml`
3. **Sync**: `/focus` — pulls declared primitives from GitHub into project-local harness dirs
4. **Manage**: `/focus add stripe`, `/focus remove moonshot`, `/focus search "webhook"`

### Manifest format (.spellbook.yaml)

```yaml
skills:
  - debug                                      # phrazzld/spellbook (default)
  - autopilot
  - anthropics/skills@frontend-design          # external source (FQN)
  - vercel-labs/agent-skills@vercel-react-best-practices
agents:
  - ousterhout
  - grug
```

Checked into git. Harness-agnostic. Unqualified names resolve to `phrazzld/spellbook`.

### Managed vs Unmanaged

Spellbook-managed primitives have a `.spellbook` marker file in their directory.
`/focus` only touches directories with this marker. Project-specific primitives
without a marker are invisible to Spellbook and never modified.

### Multi-Source Discovery

`embeddings.json` contains pre-computed vectors (Gemini Embedding 2, 768-dim) for all
indexed primitives across multiple GitHub sources. `/focus init` and `/focus search`
use cosine similarity against this index for semantic matching.

External sources are defined in `registry.yaml` under `sources`. To add a new source,
add an entry there and re-run the embeddings generator.

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

Markdown files with YAML frontmatter. Canonical format (Claude Code native).
`/focus` translates to TOML for Codex during install.

```yaml
---
name: agent-name
description: When to use this agent
tools: Read, Grep, Glob, Bash
---
[System prompt in markdown]
```

## Key Commands

```bash
# Rebuild the embeddings index (requires GEMINI_API_KEY)
python3 scripts/generate-embeddings.py

# Search the index
python3 scripts/search-embeddings.py "your query"
python3 scripts/search-embeddings.py --project-dir /path/to/project
```

## Adding a Skill

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Add references/, scripts/, assets/ as needed
3. Run `python3 scripts/generate-embeddings.py`
4. Commit and push — consumers get it on next `/focus`

## Principles

- **Flat over nested** — every skill at `skills/{name}/`, no hierarchy
- **Manifest-driven** — projects declare what they need, focus delivers it
- **Harness-agnostic** — primitives work across Claude Code, Codex, Pi, Factory
- **Nuke and rebuild** — focus deletes and recreates managed primitives each sync
- **Always project-local** — focus installs to project dirs, never global
- **Marker-based ownership** — `.spellbook` file distinguishes managed from unmanaged
- **Embeddings-first discovery** — semantic search via Gemini Embedding 2
- **Multi-source** — index and install from any GitHub skill repo
- **Progressive disclosure** — description → SKILL.md body → references on-demand
- **GitHub as source of truth** — focus pulls from GitHub, works on any machine

## Artifact Hygiene

- Default scratch output goes to `/tmp`, not repo-relative paths
- Never require stable shared filenames for PR-local evidence
- Commit artifacts only when the repo explicitly wants them versioned
