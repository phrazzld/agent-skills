# Focus Init

Generate a `.spellbook.yaml` manifest for a project that doesn't have one.

## Process

### 1. Deeply Analyze the Project

Read everything available to understand what this project IS:

| Signal | Where |
|--------|-------|
| Project purpose, tech stack | `CLAUDE.md`, `README.md`, `AGENTS.md` |
| Dependencies | `package.json`, `go.mod`, `mix.exs`, `Gemfile`, `requirements.txt`, `Cargo.toml` |
| Directory structure | `ls` top-level dirs |
| Recent activity | `git log --oneline -20` |
| Existing skills | `.claude/skills/`, `.codex/skills/` |

Synthesize a 1-2 paragraph description of the project covering:
what it does, what tech it uses, what domains it touches.

### 2. Semantic Search for Relevant Primitives

Use `scripts/search-embeddings.py` to find matching skills and agents:

```bash
python3 /path/to/spellbook/scripts/search-embeddings.py \
  --project-dir . --top 20
```

This embeds the project context and runs cosine similarity against
the full Spellbook index (local + external sources).

If `search-embeddings.py` is not available or `embeddings.json` is missing,
fall back to keyword matching against `index.yaml`.

### 3. Curate with Discernment

For each candidate from the search results:

**Include if:**
- The skill addresses a concrete need this project has
- The project's tech stack matches the skill's domain
- The similarity score is > 0.65

**Exclude if:**
- No concrete use case in THIS specific repo
- The skill targets a technology not present in the project
- It's a domain skill for a domain this project doesn't touch

**Discernment over coverage.** 8 precisely-relevant primitives beats
25 that include noise. If a skill scored high but doesn't make sense,
trust your analysis of the project over the embedding score.

### 4. Handle External Sources

Skills from external sources use fully qualified names (FQN):

```yaml
skills:
  - debug                                        # phrazzld/spellbook (default)
  - anthropics/skills@frontend-design            # external source
  - vercel-labs/agent-skills@vercel-react-best-practices
  - Leonxlnx/taste-skill@design-taste-frontend
```

Unqualified names resolve to `phrazzld/spellbook`. Any other source
must use `owner/repo@skill-name` format.

The `.spellbook` marker for external skills records the source:
```yaml
source: anthropics/skills
name: frontend-design
installed: 2026-03-16T20:00:00Z
```

### 5. Include Agents

Recommend agents alongside skills. The same search covers both types.
Agents that match the project's needs go in the `agents:` section:

```yaml
agents:
  - ousterhout          # phrazzld/spellbook agent
  - react-pitfalls      # phrazzld/spellbook agent
```

### 6. Generate Manifest

```yaml
# .spellbook.yaml
skills:
  - debug
  - autopilot
  - groom
  - anthropics/skills@frontend-design
  - vercel-labs/agent-skills@vercel-react-best-practices
agents:
  - ousterhout
  - test-strategy-architect
```

### 7. Present for Confirmation

Show the user:
- What was detected (tech stack, dependencies, project purpose)
- Each recommended primitive with reasoning
- The proposed manifest

Ask: "Write this to .spellbook.yaml?"

Only write after explicit confirmation.

### 8. Run Sync

After writing the manifest, immediately run the sync flow to install
the declared primitives.
