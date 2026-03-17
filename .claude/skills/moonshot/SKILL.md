---
name: moonshot
description: |
  Identify the single highest-leverage, most innovative addition to the project.
  Forces divergent thinking beyond the current roadmap. One answer, fully argued.
  Use when: "what should we build next", "what's the biggest opportunity",
  "step back and think big", "what's missing", "surprise me".
  Trigger: /moonshot, "biggest opportunity", "what would you build".
disable-model-invocation: true
---

# /moonshot

Stop. Step back from the backlog, the roadmap, the current sprint. Answer one question:

> **What's the single smartest, most radically innovative, accretive, useful, and
> compelling addition you could make to this project at this point?**

## Rules

1. **Exactly one answer.** Not a list. Not options. One thing, fully committed.
2. **Argue it.** Why THIS over everything else? What makes it the inflection point?
3. **Be bold.** This is not incremental improvement. This is the move that changes the trajectory.
4. **Be concrete.** Name the feature, the architecture, the integration — not a vague direction.
5. **Be honest.** If the project needs something unglamorous, say that. Innovation includes knowing when the highest leverage is boring infrastructure.

## Process

### 1. Deep Immersion

Before answering, build a complete mental model:

- Read the full codebase structure (`.glance.md` files, READMEs, CLAUDE.md)
- Read the backlog (GitHub issues, `.groom/BACKLOG.md`)
- Read recent git history (last 30 commits minimum)
- Read any project.md, retro files, or ADRs
- Understand the user, the product, the market context

### 2. Divergent Search

Generate at least 10 candidates internally. For each, evaluate:

- **Leverage**: How much value per unit of effort?
- **Innovation**: Does this exist elsewhere? Is this a novel combination?
- **Accretion**: Does this compound? Does it make future work easier/better?
- **Usefulness**: Does this solve a real problem or create real capability?
- **Timing**: Why now? What makes this the right moment?

### 3. Convergent Selection

Pick one. Kill your darlings. The answer should survive this gauntlet:

- "If we could only ship one more thing, would this be it?"
- "Will this still matter in 6 months?"
- "Does this unlock things that are currently impossible, not just inconvenient?"
- "Is this the kind of thing that makes people say 'why didn't we do this sooner'?"

### 4. The Pitch

Present your answer as:

```
## The Move

[One sentence: what it is]

## Why This, Why Now

[2-3 paragraphs: the argument. What changes. What it unlocks.
Why the timing is right. Why everything else is less important.]

## What It Looks Like

[Concrete description: architecture, UX, integration points.
Enough detail to judge feasibility.]

## What It Costs

[Honest effort estimate. What gets displaced. What risks exist.]

## The Unlock

[What becomes possible AFTER this ships that isn't possible today?]
```

## Anti-Patterns

- Listing 5 ideas and asking the user to pick (that's `/groom`)
- Proposing something the project already does
- Vague directional advice ("invest in testing", "improve DX")
- Safe, incremental, obvious next steps (that's the backlog)
- Ignoring constraints (team size, tech stack, market position)

## Creative Reframing

When the divergent search feels stuck producing variations instead of new ideas,
load `references/break-the-frame.md` for signal detection and hard reframing moves.

## Composability

After `/moonshot`, the user may:
- `/groom` — to fit the moonshot into the backlog
- `/shape` — to plan the moonshot in detail
- `/research thinktank` — to stress-test the idea
- `/autopilot` — to just build it
