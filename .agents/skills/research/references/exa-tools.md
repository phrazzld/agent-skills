# Exa Research Tools

Exa provides neural search optimized for code and technical content.

## Access

**REST API via curl. No MCP.**

Auth: `x-api-key: $EXA_API_KEY` header. Key is set in shell env.

## Search

```bash
curl -s https://api.exa.ai/search \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "YOUR QUERY HERE",
    "type": "auto",
    "numResults": 5,
    "useAutoprompt": true,
    "contents": { "text": { "maxCharacters": 1000 } }
  }'
```

### Code Context Search

Find reference implementations — highest-leverage research for engineers.

```bash
curl -s https://api.exa.ai/search \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "TLA+ PlusCal payment state machine example",
    "type": "code",
    "numResults": 5,
    "useAutoprompt": true,
    "contents": { "text": { "maxCharacters": 2000 } }
  }'
```

### Recency-Filtered

For time-sensitive queries (model releases, security advisories).

```bash
curl -s https://api.exa.ai/search \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Claude API latest model versions",
    "type": "auto",
    "numResults": 5,
    "startPublishedDate": "2026-01-01",
    "contents": { "text": { "maxCharacters": 1000 } }
  }'
```

### Find Similar

Find pages similar to a known URL.

```bash
curl -s https://api.exa.ai/findSimilar \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/good-reference",
    "numResults": 5,
    "contents": { "text": { "maxCharacters": 1000 } }
  }'
```

### Get Contents

Extract content from known URLs.

```bash
curl -s https://api.exa.ai/contents \
  -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "ids": ["https://example.com/page1", "https://example.com/page2"],
    "text": { "maxCharacters": 2000 }
  }'
```

## When to Use Each Mode

| Need | Type | Example |
|------|------|---------|
| "How does X implement Y?" | `code` | Reference architecture search |
| "What's the current best practice for Z?" | `auto` + recency | Library/framework decisions |
| "Is X still recommended?" | `auto` + `startPublishedDate` | Model currency, deprecation |
| "Find papers on X" | `auto` | Academic/formal specs |
| "Pages like this one" | `findSimilar` | Expand from known good source |

## Integration with Research Skill

The `/research` default fanout calls Exa via curl in parallel with thinktank and xAI.
Exa results include URLs — always cite them.

Provider chain: Exa (curl) → WebSearch (fallback only)
