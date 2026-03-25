---
name: groom
description: |
  Backlog management, brainstorming, architectural exploration, project bootstrapping.
  File-driven backlog via backlog.d/. Explore, brainstorm, research, synthesize,
  prioritize. Includes divergent thinking and architectural rethinking.
  Use when: backlog session, "groom", "what should we build", "rethink this",
  "biggest opportunity", "backlog", "prioritize", "tidy", "scaffold".
  Trigger: /groom, /backlog, /rethink, /moonshot, /scaffold, /tidy.
argument-hint: "[explore|brainstorm|rethink|scaffold|tidy] [context]"
---

# /groom

Backlog management and strategic thinking. File-driven via `backlog.d/`.

## Modes

| Mode | Intent |
|------|--------|
| **explore** (default) | Interactive brainstorming → prioritized backlog items |
| **rethink** | Deep architectural exploration — understand deeply, research alternatives, recommend simpler path |
| **moonshot** | Divergent thinking — what's the single highest-leverage thing we're not building? |
| **scaffold** | Project bootstrapping — quality gates, test infrastructure, CI, linting |
| **tidy** | Prune, reorder, archive completed items |

## Backlog Format: backlog.d/

```
backlog.d/
├── 001-fix-auth-rotation.md
├── 002-add-webhook-retry.md
└── _done/
    └── 000-initial-scaffold.md
```

Each file:
```markdown
# Fix auth token rotation

Priority: high
Status: ready | blocked | in-progress | done
Estimate: S | M | L | XL

## Goal
<1 sentence — what outcome, not what mechanism>

## Non-Goals
- <what NOT to do>

## Oracle
- [ ] <mechanically verifiable criterion>

## Notes
<context, constraints, prior art>
```

## Workflow: Explore

1. **Gather context** — Spawn parallel sub-agents to read the landscape fast.
   One maps the codebase (architecture, tech debt, recent velocity, opportunities).
   Another reads backlog.d/ and recent git history (what's done, stalled, missing).
2. **Brainstorm** — Generate 3-5 candidate items with tradeoffs
3. **Research** — Use `/research` for prior art, reference architectures
4. **Discuss** — One question at a time. Recommend, don't just list.
5. **Write** — Create backlog.d/ files for approved items
6. **Prioritize** — Reorder by value/effort ratio

## Workflow: Rethink

1. **Understand deeply** — Spawn a sub-agent to map the target system: all
   dependencies, pain points, complexity hotspots. What would it redesign?
2. **Research alternatives** — Invoke `/research thinktank` for multi-perspective
   analysis. This dispatches to multiple external models for independent opinions.
3. **Synthesize options** — 2-3 approaches with honest tradeoffs
4. **Recommend** — One clear recommendation with reasoning
5. **Capture** — Write backlog.d/ item for the recommended change

Anti-patterns: listing options without recommending, proposing rewrites when
the real problem is one leaky abstraction, ignoring the "do nothing" option.

## Workflow: Moonshot

Force divergent thinking. Spawn a planner sub-agent and ask it to forget the
current backlog and think from first principles: what's the single highest-leverage
addition? What would a competitor build? What's the user's biggest unmet need?
One answer, fully argued, with goal + oracle + rough effort estimate.

Review the planner's output. If compelling, write as backlog.d/ item.

## Workflow: Scaffold

Bootstrap a new project with quality gates:
1. Test infrastructure (framework, coverage gates)
2. Linting (ESLint/Biome/clippy with strict rules)
3. Type checking
4. Pre-commit hooks
5. CI pipeline (if applicable)
6. CLAUDE.md / AGENTS.md with project-specific instructions

## Workflow: Tidy

1. Archive completed items to `backlog.d/_done/`
2. Reorder remaining by priority
3. Delete stale items (>30 days untouched, no longer relevant)
4. Verify each remaining item has goal + oracle

## Gotchas

- **Items without oracles:** If you can't write a "definition of done" with checkable criteria, the item isn't scoped. Go back and scope it.
- **Listing without recommending:** "Here are 5 options" is a menu, not grooming. Pick one and argue for it.
- **Scope creep during rethink:** Rethink mode explores, but it must end with one concrete recommendation, not a wish list.
- **Backlog as graveyard:** Items >30 days old with no progress are dead. Archive or delete during tidy.
- **Over-decomposing:** An agent-hour of work is one item, not three. Agent compression ratios make most splits unnecessary.

## Principles

- Recommend, don't just list — always have an opinion
- File-driven — backlog.d/ is the source of truth, not GitHub Issues
- One question at a time — don't overwhelm
- Every item needs an oracle — if you can't verify done, the item isn't ready
