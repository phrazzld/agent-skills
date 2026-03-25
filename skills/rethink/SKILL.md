---
name: rethink
description: |
  Architectural exploration: understand current system deeply, research alternatives,
  synthesize options with tradeoffs, recommend a simpler path.
  Use when: "rethink this", "is there a better way", "simplify this system",
  "architectural alternatives", "what would you redesign", "question the architecture",
  "step back and rethink".
  Trigger: /rethink, "rethink the architecture", "what would you change".
argument-hint: "[scope] — module, subsystem, directory, or architectural concern"
---

# /rethink

Architectural exploration. Understand deeply, research alternatives, recommend a simpler path.

## When to Use

- Current architecture feels wrong but you can't articulate why
- Complexity has accreted and you want to see the design space
- Before major refactors — know your options first
- System works but is harder to reason about than it should be
- You want to question foundational assumptions, not just fix bugs

NOT for: incremental improvements (use `/settle --simplify`), issue planning (use `/shape`),
backlog strategy (use `/groom`), deciding what to build next (use `/moonshot`).

## Interface

`/rethink [scope]`

Scope is a module, subsystem, directory, or architectural concern.
Examples: `/rethink the auth system`, `/rethink src/payments/`,
`/rethink how we handle state`, `/rethink the build system`.

## Executive / Worker Split

Workers gather evidence; the lead decides. Never delegate the architectural recommendation.

- **Phase 1 workers**: Explore agents gather structure, data flow, pain points, history
- **Phase 2 workers**: Triad agents provide critique; `/research` handles web fanout
- **Phase 3**: Lead model only — all synthesis, recommendation, and judgment

## Process

### Phase 1: Understand

Build a deep mental model before forming opinions.

Spawn 2-4 Explore workers in parallel:

| Worker | Focus |
|--------|-------|
| Structure | Module boundaries, dependency graph, public interfaces, file organization |
| Data flow | How data moves: entry points, transformations, storage, exit points |
| Pain points | Complexity hotspots, large files, deep call chains, leaky abstractions |
| History | Git history (30+ commits) — what changes most, what's coupled, what broke |

Workers return evidence, not opinions.

**Mandatory reads** before proceeding:
- CLAUDE.md, README, any ADRs or project docs
- The actual source files in scope (not just structure)
- Recent PRs touching the scope (last 5-10)

### Phase 2: Research

Three parallel tracks:

1. **Reference architectures** — Invoke `/research "how do production systems implement [this concern]"`.
   Focus on systems that solved the SAME problem differently.

2. **Triad critique** — Spawn ousterhout, carmack, grug agents on the current architecture:
   > "Here is [scope]. What is the single biggest structural problem?
   > What would you change first? What would you delete?"

3. **Prior art in codebase** — Has this been rethought before?
   Check git log for large refactors, ADRs, comments with `TODO: rethink`,
   `tech debt`, `HACK`, `FIXME`.

**All web research MUST use `/research`** — do not bypass the fanout.

If exploration produces variations on the same theme instead of genuine alternatives,
load `references/alternative-lenses.md` for hard reframing moves.

### Phase 3: Synthesize

Produce the Rethink Report (structure below). The lead model does this alone.

**Rules:**
- Recommend one path. Not a menu — a recommendation with conviction.
- Every alternative must be concrete enough to implement, not vague directions.
- "Do nothing" is always an explicit option with honest tradeoffs.
- Cost in complexity-removed matters more than features-added.
- The best rethink often deletes code, not adds it.

## Output: Rethink Report

```
## Current Architecture

[2-3 paragraphs: what exists, how it works, key design decisions (explicit and implicit)]

### Structural Assessment

| Dimension | Rating |
|-----------|--------|
| Module depth | Shallow / adequate / deep |
| Information hiding | Leaky / partial / strong |
| Coupling | High / moderate / low |
| Complexity budget | Over / at / under budget |
| Change cost | High / moderate / low |

### What the Triad Said
- **Ousterhout**: [core structural concern]
- **Carmack**: [shippability/pragmatism concern]
- **Grug**: [complexity concern]

## Alternatives

### Option 0: Do Nothing
[Honest assessment. What happens if we leave it? When does it break?]

### Option 1: [Name]
[Architecture sketch. Key insight. What changes structurally.]
- **Gains**: what improves (be specific)
- **Costs**: what it takes (effort, risk, migration)
- **Deletes**: what goes away (the best part)
- **Unlocks**: what becomes possible that isn't today

### Option 2: [Name]
[Same structure]

### Option N: [2-4 total alternatives]

## Recommendation

[Which option and WHY. The argument for why this is the right move
at this point in the project's life.]

## Next Steps

[Concrete: "/shape this", "create an issue", "try a spike", "do nothing for now"]
```

## Anti-Patterns

- Listing options without recommending one (that's a menu, not a rethink)
- Recommending the current architecture with minor tweaks (that's `/settle --simplify`)
- Ignoring the "do nothing" option (sometimes the answer is "it's fine")
- Over-researching without forming an opinion (research informs; it doesn't decide)
- Proposing rewrites when the real problem is one leaky abstraction
- Adding layers to fix problems caused by too many layers

## Composability

After `/rethink`, the user may:
- `/shape` — plan the recommended alternative in detail
- `/groom` — fit the rethink into the backlog
- `/autopilot` — just build it
- `/research thinktank` — stress-test the recommendation further
