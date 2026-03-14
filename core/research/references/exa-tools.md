# Exa Research Tools

Exa provides neural search optimized for code and technical content.

## Access Paths

1. **MCP tools** (primary): `exa_search`, `exa_find_similar`, `exa_get_contents`
2. **inference.sh** (fallback): `curl https://api.exa.ai/search`

## Search Modes

### Code Context Search
Find reference implementations — the highest-leverage research for engineers.

```
exa_search("TLA+ PlusCal payment state machine example", {
  type: "code",
  num_results: 5,
  use_autoprompt: true
})
```

### Neural Search
Semantic understanding, not just keyword matching.

```
exa_search("Elixir OTP supervision tree for concurrent AI agents", {
  num_results: 10,
  use_autoprompt: true
})
```

### Recency-Filtered
For time-sensitive queries (model releases, security advisories).

```
exa_search("Claude API latest model versions 2025", {
  start_published_date: "2025-01-01",
  num_results: 5
})
```

### Answer Mode
Get a synthesized answer with citations.

```
exa_search("best practices for webhook delivery retry", {
  type: "auto",
  use_autoprompt: true,
  summary: true
})
```

## When to Use Each Mode

| Need | Mode | Example |
|------|------|---------|
| "How does X implement Y?" | Code context | Reference architecture search |
| "What's the current best practice for Z?" | Neural + recency | Library/framework decisions |
| "Is X still recommended?" | Recency-filtered | Model currency, deprecation |
| "Explain concept Y" | Answer mode | Quick factual queries |
| "Find papers on X" | Neural search | Academic/formal specs |

## Integration with Research Skill

The `/research web-search` command routes to Exa by default.
Exa results include URLs — always cite them.

Provider chain: Exa → Context7 (for docs) → WebSearch (fallback)
