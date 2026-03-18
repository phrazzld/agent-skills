# Spellbook

Portable library of agent primitives (skills + agents) for multi-model AI harnesses. Works with Claude Code, Codex, Gemini, Factory, and Pi.

Markdown-first. No application code, no dependencies. Primitives teach agents *how to work*: debugging, PR workflows, design systems, incident response, and domain-specific playbooks.

## Quick Start

```bash
# Bootstrap (one-time per machine)
curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/master/bootstrap.sh | bash
```

This installs two global skills: `/focus` (primitive manager) and `/research` (multi-source web research). Everything else is project-local.

```bash
# In any project:
/focus init                    # Analyze project, generate .spellbook.yaml
/focus                         # Pull declared primitives from GitHub
/focus add stripe              # Add a skill to manifest
/focus search "webhook handler" # Semantic search across all sources
```

## How It Works

Projects declare what they need in `.spellbook.yaml`:

```yaml
skills:
  - debug
  - autopilot
  - anthropics/skills@frontend-design    # external source
agents:
  - ousterhout
  - grug
```

`/focus` reads the manifest, pulls primitives from GitHub, and installs them into the project's local harness directory (`.claude/skills/`, `.claude/agents/`). Managed primitives are marked with a `.spellbook` file — project-local primitives without the marker are never touched.

### Multi-Source Discovery

Spellbook indexes skills from multiple GitHub repos using Gemini Embedding 2 for semantic search. When you run `/focus init` or `/focus search`, it matches your project context or query against the full index.

Unqualified names (`debug`) resolve to `phrazzld/spellbook`. External skills use fully qualified names (`owner/repo@skill-name`) to avoid collisions.

Spellbook keeps the text catalog in `index.yaml`. Embeddings are generated and
cached locally on first search under `$CODEX_HOME/cache/spellbook/` when
available, otherwise `~/.cache/spellbook/`.

## Repo Structure

```
spellbook/
├── skills/              # All skills, flat
├── agents/              # Agent definitions, flat
├── index.yaml           # Generated text catalog
├── collections.yaml     # Named skill groups (human browsing)
├── bootstrap.sh         # One-command global install
└── scripts/
    ├── generate-index.sh
    ├── generate-embeddings.py
    └── search-embeddings.py
```

## Adding a Skill

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Add `references/`, `scripts/`, `assets/` as needed
3. Run `./scripts/generate-index.sh`
4. Optional: run `python3 scripts/generate-embeddings.py` to prewarm your local cache
5. Commit and push — consumers get the updated catalog on next `/focus`

## Principles

- **Flat over nested** — every skill at `skills/{name}/`
- **Manifest-driven** — projects declare needs, `/focus` delivers
- **Harness-agnostic** — works across Claude Code, Codex, Pi, Factory, Gemini
- **Nuke and rebuild** — `/focus` deletes and recreates managed primitives each sync
- **Embeddings-first discovery** — semantic search, not keyword matching
- **Multi-source** — index skills from any GitHub repo, not just this one
- **Always project-local** — `/focus` installs to project dirs, never global

## License

MIT
