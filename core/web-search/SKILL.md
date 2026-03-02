---
name: web-search
description: Retrieval-first web research with citations and recency controls. Use for web, docs, and news lookups via /web, /web-deep, /web-news, and /web-docs.
---

# Web Search Skill

Provides retrieval-first web research with citations and recency controls.

## Commands
- `/web <query>`: fast top links
- `/web-deep <query>`: fetch and summarize with citations
- `/web-news <query>`: recency-biased search results
- `/web-docs <query>`: library/docs-focused retrieval

## Behavior Contract
- Return structured result envelope (see schema below)
- Include citation URL for every claim
- Prefer Context7 for docs/library lookups
- Prefer Exa as primary general provider
- Fallback to Brave on provider failure
- Optional Perplexity pass allowed only for synthesis, never source of truth

## Output Schema
```json
{
  "results": [
    {
      "title": "string",
      "url": "string",
      "snippet": "string",
      "published_at": "ISO-8601 or null",
      "score": 0.0,
      "source_provider": "context7|exa|brave|perplexity"
    }
  ],
  "meta": {
    "query": "string",
    "command": "web|web-deep|web-news|web-docs",
    "provider_chain": ["context7", "exa", "brave"],
    "provider_used": "context7|exa|brave|null",
    "cache_hit": false,
    "time_sensitive": false,
    "recency_days": null,
    "confidence": "high|medium|low",
    "uncertainty": "string|null"
  },
  "synthesis": {
    "summary": "string",
    "citations": ["https://..."]
  }
}
```

## Safety and Quality
- Never fabricate URLs
- Mark uncertain facts as uncertain
- Apply recency filters for time-sensitive queries

## Runtime Notes
- Pi extension entrypoint: `~/.pi/agent/extensions/web-search/` (loaded via settings.json)
- CLI entrypoint (optional debug): `core/web-search/cli.ts`
- Cache: `cache/web-search-cache.json` (TTL via `WEB_SEARCH_TTL_MS`)
- Logs: `logs/web-search.ndjson` (size-rotated)
- `PI_WEB_SEARCH_LOG_MAX_BYTES` / `PI_WEB_SEARCH_LOG_MAX_BACKUPS` / `PI_WEB_SEARCH_LOG_ROTATE_CHECK_MS`
- Cost controls:
  - `WEB_SEARCH_MAX_RESULTS` caps results per query
  - Cache dedupe prevents repeated provider calls for same normalized query
