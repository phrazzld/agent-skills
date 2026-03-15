---
name: research
description: |
  Web research, multi-AI delegation, and multi-perspective validation.
  /research [query], /research delegate [task], /research thinktank [topic].
  Triggers: "search for", "look up", "research", "delegate", "get perspectives",
  "web search", "find out", "investigate", "introspect", "session analysis",
  "check readwise", "saved articles", "reading list", "highlights".
argument-hint: "[query] or [web-search|web-deep|web-news|web-docs|delegate|thinktank|introspect|readwise] [args]"
---

# Research

Retrieval-first research, multi-AI orchestration, and expert validation.

## Absorbed Skills

This skill consolidates: `web-search`, `delegate`, `thinktank`, `introspect`.

## Routing

| Intent | Sub-capability |
|--------|---------------|
| Search the web, find docs/info, `web-search`, `web-deep`, `web-news`, `web-docs`, `/web`, `/web-deep`, `/web-news`, `/web-docs` | `references/web-search.md` |
| Delegate work to Codex/Gemini/agents, orchestrate multi-AI | `references/delegate.md` |
| Multi-perspective expert validation, consensus | `references/thinktank.md` |
| Analyze session history, usage patterns, improvement opportunities | `references/introspect.md` |
| Search saved articles, highlights, reading list | `references/readwise.md` |

If first argument matches `web-search`, `web-deep`, `web-news`, `web-docs`,
`delegate`, `thinktank`, `introspect`, or `readwise`, read the corresponding reference.
If no argument, select based on user intent. If user specifies a sub-capability
by name (e.g., "delegate this to codex"), route directly.

Read the relevant reference and follow its instructions.

## Use When

- Before implementing any system >200 LOC (reference architecture search)
- Before choosing a library, framework, or approach (current best practices)
- When training data may be stale (model releases, API changes, deprecations)
- When you need to verify a fact before asserting it
- When the user asks about something outside the codebase
- During `/groom` architecture critique (reference implementations)
- During `/shape` technical exploration (how others solve this)
- During `/build` understand step (existing patterns and examples)
- When another skill says "web search first" or "research before implementing"

## Decision Framework

**If you're about to assert something from training data that could be wrong,
invoke `/research web-search` first.** The cost of a search is negligible;
the cost of hallucination is high.

This applies especially to:
- Model names and versions (stale within months)
- Library APIs and best practices (change with major versions)
- Pricing, availability, feature comparisons
- Security advisories, CVEs, deprecation notices

## Provider Routing

| Query Type | Primary Provider | Why |
|------------|-----------------|-----|
| Code examples, reference implementations | Exa (code context) | Finds actual code, not blog posts |
| Academic papers, formal specs | Exa (search) | Strong academic indexing |
| Library/framework docs | Context7 | Semantic doc search |
| Current events, model releases | Exa (with recency filter) | Real-time indexing |
| General knowledge fallback | WebSearch | Broad coverage |

**Exa-first.** Exa's code context search finds reference implementations
that enforce the CLAUDE.md "reference architecture first" red line. Default
to Exa unless the query is clearly better suited to another provider.

## Anti-Patterns

- Asserting model versions from training data without searching
- Using WebSearch for code examples (Exa code context is better)
- Skipping research because "I'm pretty sure" (you're not)
- Research without citations (every claim needs a URL)
