# Focus Search

Search the Spellbook index for skills and agents matching a query.

## Process

### 1. Semantic Search (preferred)

Use the pre-computed embeddings index:

```bash
python3 /path/to/spellbook/scripts/search-embeddings.py "webhook handling" --top 10
```

This embeds the query with Gemini Embedding 2 and ranks all indexed
primitives (local + external sources) by cosine similarity.

### 2. Fallback: Keyword Search

If `embeddings.json` or the API key is unavailable, fall back to
keyword matching against `index.yaml`:
- Skill `name` (exact and substring)
- Skill `description` (keyword matching)
- Agent `name` and `description`

### 3. Present Results

```markdown
## Spellbook Search: "webhook handling"

| # | Score | Type  | Source                    | Name                          |
|---|-------|-------|---------------------------|-------------------------------|
| 1 | 0.77  | skill | phrazzld/spellbook        | stripe                        |
| 2 | 0.73  | agent | phrazzld/spellbook        | stripe-auditor                |
| 3 | 0.68  | skill | phrazzld/spellbook        | external-integration-patterns |
| 4 | 0.64  | skill | anthropics/skills         | mcp-builder                   |

### Actions
- `/focus add stripe` — add to manifest
- `/focus add anthropics/skills@mcp-builder` — add external skill
```

### 4. Offer to Add

If the user wants a result, offer to add it to the manifest and sync.
External skills are added with their fully qualified name.
