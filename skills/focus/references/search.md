# Focus Search

Search the Spellbook index for skills and agents matching a query.

## Process

### 1. Semantic Search

Run the search script bundled with the focus skill:

```bash
# Free-text query
python3 ${SKILL_DIR}/scripts/search.py "webhook handling" --top 10

# Project analysis
python3 ${SKILL_DIR}/scripts/search.py --project-dir . --top 15

# JSON output for programmatic use
python3 ${SKILL_DIR}/scripts/search.py "query" --json

# Filter by type
python3 ${SKILL_DIR}/scripts/search.py "query" --type skill
python3 ${SKILL_DIR}/scripts/search.py "query" --type agent
```

The script fetches `index.yaml` and `registry.yaml` from GitHub, builds a
local embeddings cache on first use, and reuses that cache until the catalog
changes or the cache ages out.

Cache location:
- `$CODEX_HOME/cache/spellbook/discovery/` when `CODEX_HOME` is set
- otherwise `~/.cache/spellbook/discovery/`

Requires `GEMINI_API_KEY` or `GOOGLE_API_KEY` for both corpus and query
embedding. First run is slower because it builds the cache locally.

### 2. Fallback

If the script fails (no API key, no network), fetch `index.yaml`:
```bash
curl -sfL https://raw.githubusercontent.com/phrazzld/spellbook/master/index.yaml
```
Read descriptions and match manually.

### 3. Filter Globals

Remove results matching any global skill or agent from the output.
These are already available via bootstrap. The canonical list is in
`registry.yaml` under `global.skills` and `global.agents`.

### 4. Present Results

```markdown
## Spellbook Search: "webhook handling"

| # | Score | Type  | Source                    | Name                          |
|---|-------|-------|---------------------------|-------------------------------|
| 1 | 0.77  | skill | phrazzld/spellbook        | stripe                        |
| 2 | 0.73  | agent | phrazzld/spellbook        | stripe-auditor                |
| 3 | 0.68  | skill | anthropics/skills         | mcp-builder                   |

### Actions
- `/focus add stripe` — add to manifest
- `/focus add anthropics/skills@mcp-builder` — add external skill
```

### 5. Offer to Add

If the user wants a result, offer to add it to the manifest and sync.
External skills are added with their fully qualified name.
