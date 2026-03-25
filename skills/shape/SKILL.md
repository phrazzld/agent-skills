---
name: shape
description: |
  Shape a raw idea into something buildable. Product + technical exploration.
  Spec, design, critique, plan. Output is a context packet.
  Use when: "shape this", "write a spec", "design this feature",
  "plan this", "spec out", "context packet", "technical design".
  Trigger: /shape, /spec, /plan, /cp.
argument-hint: "[idea|issue|backlog-item] [--spec-only] [--design-only]"
---

# /shape

Shape a raw idea into something buildable. Output is a **context packet** —
the unit of specification that precedes implementation.

## Workflow

### Phase 1: Understand

Accept: raw idea, backlog.d/ item, issue ID, or observation.

Spawn parallel sub-agents to gather context fast:

```
Agent(subagent_type: "Explore", prompt: "Map the codebase area relevant to [topic]. What files exist, what patterns are established, what constraints apply?")
Agent(subagent_type: "Explore", prompt: "Search for prior art: how do other projects solve [problem]? Check the codebase, then /research if needed.")
```

Synthesize their findings before proceeding.

### Phase 2: Product Exploration

**GATE: Do NOT write code until product direction is locked.**

1. **Investigate** — Problem space, user impact, prior art
2. **Brainstorm** — 2-3 approaches with tradeoffs. **Recommend one.**
3. **Discuss** — One question at a time. Iterate until locked.
4. **Draft spec** — Goal, non-goals, acceptance criteria

### Phase 3: Technical Exploration

1. **Explore** — 3-5 technical approaches. For each:
   architecture sketch, files to modify, pattern alignment, effort, tradeoffs.
   **Recommend one.**

2. **Validate** — For effort M or larger, spawn the design review bench:
   ```
   Agent(subagent_type: "ousterhout", prompt: "Review this design for module depth and information hiding: [design summary]")
   Agent(subagent_type: "carmack", prompt: "Review this design for shippability and over-engineering: [design summary]")
   Agent(subagent_type: "grug", prompt: "Review this design for complexity: [design summary]")
   ```
   If any reviewer has blocking concerns, revise before proceeding.

3. **Discuss** — No limit on rounds. Design isn't ready until user says so.

### Phase 4: Context Packet

The output of shape. This is what `/autopilot` and builders consume.

```markdown
# Context Packet: <title>

## Goal
<1 sentence — what outcome, not mechanism>

## Non-Goals
- <what NOT to do, even if it seems like a good idea>

## Constraints / Invariants
- <things that must remain true before, during, and after>

## Authority Order
tests > type system > code > docs > lore

## Repo Anchors
- `src/auth/middleware.ts` — current pattern to follow
- `tests/auth/` — existing coverage

## Prior Art
- `src/payments/middleware.ts` — similar pattern

## Oracle (Definition of Done)
- [ ] All existing auth tests pass
- [ ] New endpoint returns 200 with valid token
- [ ] Response time < 100ms p99

## Implementation Sequence
1. <first chunk>
2. <second chunk>

## Risk + Rollout
- <how it could fail, how to undo it>
```

If you can't write an oracle, the goal isn't clear enough. Go back to Phase 2.

## Gotchas

- **Vague oracles:** "It should work" is not an oracle. "These 3 tests pass and this endpoint returns 200" is.
- **Speccing after building:** A context packet written after implementation is documentation, not specification. Spec first.
- **50 repo anchors:** If everything is an anchor, nothing is. Pick 3-10 files whose patterns MUST be followed.
- **Skipping non-goals:** Agents drift toward scope expansion. Non-goals are load-bearing constraints. Write them.
- **Over-speccing implementation details:** Specify WHAT and WHY. Let the builder figure out HOW. Detailed pseudocode cascades errors.

## Principles

- Minimize touch points (fewer files = less risk)
- Design for deletion (easy to remove later)
- Favor existing patterns over novel ones
- YAGNI ruthlessly
- Recommend, don't just list options
- One question at a time
