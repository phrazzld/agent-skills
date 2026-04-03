---
name: research
description: "Multi-source research via parallel fanout to Exa, xAI, thinktank, and codebase search. Delegates subtasks to multiple AI models and synthesizes their responses into a sourced report. Routes to specialized sub-capabilities for web search, AI delegation, thinktank analysis, Readwise highlights, and social sentiment. Use when: 'search for', 'look up', 'research', 'find out', 'web search', 'delegate', 'get perspectives', 'check readwise', 'saved articles', 'what are people saying', 'social sentiment', 'trending'. Trigger: /research, /research delegate, /research thinktank."
argument-hint: "[query] or [web-search|web-deep|web-news|web-docs|delegate|thinktank|introspect|readwise|xai] [args]"
---

# Research

Multi-source triangulation. Fan out to multiple providers, synthesize a sourced report.

Consolidates: `web-search`, `delegate`, `thinktank`, `introspect`.

## Routing

### Explicit sub-capability (user names one)

| Keyword | Reference |
|---------|-----------|
| `web-search`, `web-deep`, `web-news`, `web-docs` | `references/web-search.md` |
| `delegate` | `references/delegate.md` |
| `thinktank` | `references/thinktank.md` |
| `introspect` | `references/introspect.md` |
| `readwise` | `references/readwise.md` |
| `xai` | `references/xai-search.md` |
| `exemplars` | `references/exemplars.md` |

### No sub-capability (default): MANDATORY PARALLEL FANOUT

**A single WebSearch is NOT research.** Launch ALL of these in a single message (parallel Agent/Bash calls):

1. **Exa search** — `curl -s https://api.exa.ai/search -H "x-api-key: $EXA_API_KEY" ...`
   See `references/exa-tools.md`. WebSearch is fallback ONLY if curl fails.
2. **Thinktank** — `thinktank research "$QUERY" --output /tmp/thinktank-out --json`
   Add `--paths ...` for local file context.
3. **xAI / social pulse** — `curl -s https://api.x.ai/v1/responses -H "Authorization: Bearer $XAI_API_KEY" ...`
   Model: `grok-4.20-beta-latest-non-reasoning`. See `references/xai-search.md`. Skip ONLY for purely technical/code queries.
4. **Codebase** — Grep/Glob for existing patterns (skip only if unrelated to codebase).

**Narrow to a single source ONLY when** the user explicitly names one or it's a simple fact lookup.

### Report Format (mandatory)

```
## Exa (neural search)
[Findings with inline URLs]

## xAI / Grok ([web_search | x_search | both])
[Findings with citations from response.citations]

## Thinktank (Pi bench)
[Findings, note disagreements between agents]

## Codebase
[Local patterns/prior art — "None found" is valid, write it explicitly]

## Synthesis
[Consensus, conflicts, recommendations. Every claim cites a source.]
```

If a section is missing, you either skipped that tool (state why) or failed to run it — go back and run it.

## Use When

- Before implementing any system >200 LOC (reference architecture search)
- Before choosing a library, framework, or approach (current best practices)
- When training data may be stale (model releases, API changes, deprecations)
- When you need to verify a fact before asserting it
- When the user asks about something outside the codebase
- During `/groom` architecture critique, `/shape` technical exploration, `/build` understand step
- When another skill says "web search first" or "research before implementing"

## Provider Routing

| Query Type | Primary Provider | Why |
|------------|-----------------|-----|
| Code examples, reference implementations | Exa (code context) | Finds actual code, not blog posts |
| Academic papers, formal specs | Exa (search) | Strong academic indexing |
| Library/framework docs | Context7 | Semantic doc search |
| Current events, model releases | Exa (with recency filter) | Real-time indexing |
| Social sentiment, public discourse, trending | xAI X Search | Real-time X/Twitter data |
| Web pages with image/video analysis | xAI Web Search | Grounded web + multimodal |
| General knowledge fallback | WebSearch / Brave | Broad coverage |

**Exa-first** for code and technical content. **xAI for social/real-time pulse.** See `references/xai-search.md` for API details.

## Anti-Patterns

- Asserting model versions from training data without searching
- Using WebSearch for code examples (Exa code context is better)
- Skipping research because "I'm pretty sure"
- Research without citations (every claim needs a URL)
- Returning results from only one source when no sub-capability was specified
