---
name: codified-context-architecture
description: |
  Organize project knowledge for AI agents into hot memory, specialist routing,
  and cold-memory subsystem docs. Use when tuning a repo, designing agent
  infrastructure, deciding where knowledge should live, or replacing bloated
  single-file manifests with tiered context that can scale.
user-invocable: false
---

# Codified Context Architecture

Use a 3-tier model:

1. **Hot memory** — always-loaded constitution (`CLAUDE.md`, `AGENTS.md`)
2. **Specialists** — failure-driven agents or workflows for risky domains
3. **Cold memory** — on-demand subsystem docs under `docs/context/`

## Placement Rules

Put knowledge in hot memory if:
- it must apply on every turn
- violating it is expensive
- it fits in a few sharp bullets

Put knowledge in a specialist if:
- a domain repeatedly fails without priming
- the work needs a synthesized mental model
- the same mistakes recur across sessions

Put knowledge in cold memory if:
- the subsystem is too large for hot memory
- details are needed only when touching that area
- multiple sessions keep re-reading the same files

## Routing Rules

Encode routing, don't rely on memory.

- Maintain `docs/context/ROUTING.md`
- Map file patterns or task signals to the right specialist / workflow
- If no route exists for a risky area, that is a context gap

## Drift Rules

Stale specs are load-bearing bugs.

- Maintain `docs/context/DRIFT-WATCHLIST.md`
- Map subsystem docs to the files that should trigger review
- If source changes without spec updates, flag drift

## Creation Triggers

- If you explained it twice, write it down
- If retrieval returns nothing for a risky subsystem, stop and document first
- If a domain keeps failing, create a specialist and restart with context
- If hot memory keeps growing, push detail down into cold memory

## Anti-Patterns

- Treating `CLAUDE.md` as an encyclopedia
- Creating specialists before observing failure patterns
- Over-compressing high-risk domains into vague summaries
- Letting docs drift while agents continue trusting them

## References

- `references/templates.md` -- Templates for `docs/context/` artifacts
