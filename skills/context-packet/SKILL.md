---
name: context-packet
description: |
  Write a context packet — the unit of specification that precedes implementation.
  Encodes senior judgment as explicit constraints so agents stop guessing.
  Use when: starting any non-trivial implementation, writing specs, scoping work,
  "context packet", "write a spec for the agent", "what does done look like".
  Trigger: /context-packet, /cp.
trigger: context-packet|cp
category: design
---

# Context Packet

The context packet is the unit of specification that precedes implementation.
It turns "senior intuition" into explicit constraints and executable truth.
Agents stop guessing, juniors learn faster, reviews become about invariants
instead of vibes.

> "If you ask an agent for a vibe, it will give you a vibe-shaped completion."
> — Sunil Pai

## When to Use

Before any non-trivial agent implementation. If the work touches >1 file or
takes >10 minutes, write a context packet first.

NOT for: trivial fixes, typos, single-line changes. Use judgment.

## The Packet

Write each section. Skip none. If a section is genuinely empty, write "None"
— the explicit absence is information.

### 1. Goal (1 sentence)

What outcome, not what mechanism. The test: can you verify this sentence is
true by looking at the result?

Bad: "Refactor the auth middleware to use JWT"
Good: "Users can log in with existing credentials after the auth rewrite"

### 2. Non-Goals

The "helpful creativity" kill switch. What the agent must NOT do, even if
it seems like a good idea. Agents drift toward scope expansion — non-goals
are load-bearing constraints.

### 3. Constraints / Invariants

The laws of physics for this change. Things that must remain true before,
during, and after the work. Performance budgets, API contracts, backward
compatibility requirements, security invariants.

These are the highest-signal content. A 576,000-line LLM-generated SQLite
rewrite was 20,171x slower because one performance invariant was missing.

### 4. Authority Order

When sources disagree, what wins? Default:

```
tests > type system > code > docs > lore > vibes
```

Override this when the domain requires it (e.g., regulatory docs > code
for compliance work).

### 5. Repo Anchors

The 3-10 files that define truth for this change. Not "files to read" —
files whose patterns the implementation MUST follow. The agent should read
these before writing any code.

### 6. Prior Art / Blessed Patterns

What to copy, what to reuse, what patterns are established. If there's an
existing implementation of something similar, point to it. The agent should
extend, not reinvent.

### 7. Oracle (Definition of Done)

The checks that decide success. Must be mechanically verifiable — not
"looks good" but "these tests pass, this endpoint returns 200, this
invariant holds." The oracle IS the acceptance criteria.

If you can't write an oracle, the goal isn't clear enough. Go back to step 1.

### 8. Risk + Rollout

How it could fail. How to undo it. What to monitor after deployment.
Feature flags, canary percentages, rollback procedures. If the answer is
"yolo deploy to all users" — write that explicitly so everyone sees it.

## Output Format

Write the context packet as a markdown file. If working on a GitHub issue,
write it as a comment on the issue. If working locally, write it to
`/tmp/context-packet-<slug>.md`.

```markdown
# Context Packet: <title>

## Goal
<1 sentence>

## Non-Goals
- <thing the agent must not do>

## Constraints
- <invariant that must hold>

## Authority Order
tests > code > docs

## Repo Anchors
- `src/auth/middleware.ts` — current auth pattern
- `tests/auth/` — existing test coverage

## Prior Art
- `src/payments/middleware.ts` — similar middleware pattern

## Oracle
- [ ] All existing auth tests pass
- [ ] New endpoint returns 200 with valid token
- [ ] Response time < 100ms p99

## Risk + Rollout
- Feature flag: `new-auth-middleware`
- Rollback: disable flag, old middleware still deployed
- Monitor: auth error rate dashboard for 24h post-deploy
```

## Integration

After writing a context packet:
- `/shape` — expand it into a full implementation plan
- `/autopilot` — build directly from the packet
- `/night-shift` — queue for overnight autonomous implementation

## Anti-Patterns

- Skipping non-goals ("the agent will figure it out" — it won't, it'll add scope)
- Writing vague oracles ("it should work" — that's not verifiable)
- Listing 50 repo anchors (if everything is an anchor, nothing is — pick 3-10)
- Writing the packet after implementation (that's documentation, not specification)

## Related

- `/shape` — uses context packet as input for planning
- `/autopilot` — reads context packet before building
- `/night-shift` — context packet is the handoff artifact
