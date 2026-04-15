# `/implement` — atomic TDD build skill

Priority: high
Status: pending
Estimate: M (~1.5 dev-days)

## Goal

Extract the TDD build loop currently inlined in the pre-032 `/autopilot` (now `/deliver`) into its own
atomic skill. `/implement` takes a context packet (shaped ticket) and
produces code + tests. It does not shape, does not review, does not ship.
Single concern: go from spec to green tests.

## Why Extract

The pre-032 `/autopilot` SKILL.md (now `/deliver`) inlines shape/build/review/ship. That's the
wrong granularity for three reasons:

1. **Reuse.** `/deliver` composes phases; the build phase is useful
   standalone (quick one-off fixes without the full pipeline).
2. **Testability.** A standalone `/implement` skill can be eval'd against
   a library of shaped-but-not-built tickets. You cannot eval a buried
   subroutine.
3. **Judgment scope.** Mixing "pick a ticket" and "TDD a function" in one
   SKILL.md forces the skill to encode judgment about both. One skill,
   one judgment domain.

## Contract

**Input:** Context packet (shaped ticket with goal, constraints, oracle,
implementation sequence, repo anchors). Location: explicit arg, or from
last `/shape` output in current session.

**Output:**
- Code changes on a feature branch
- Test suite green (all new + existing tests pass)
- No uncommitted debug noise
- Commits follow repo convention (one logical unit per commit)

**Stops at:** green tests + clean working tree. Does not run code review,
does not lint (CI skill's job), does not deploy.

## Stance

- Red → Green → Refactor. TDD default. Skip only for exploration or
  generated code (explicitly documented).
- Test behavior, not implementation. One behavior per test.
- Trust the context packet. If the spec is wrong, fail loudly — don't
  reshape the ticket inside `/implement`.
- Uses the `builder` agent (general-purpose) as the primary executor.
  Orchestrator makes proceed/escalate calls.

## Composition

```
/implement <context-packet|ticket-id>
    │
    ▼
  load packet (from arg, session, or backlog.d/<id>)
    │
    ▼
  builder agent → TDD implementation
    │
    ▼
  verify: tests green, tree clean
    │
    ▼
  exit with branch ref
```

## What `/implement` Does NOT Do

- Shape tickets (→ `/shape`)
- Pick tickets (→ caller's job, or `/deliver`)
- Run CI (→ `/ci`)
- Code review (→ `/code-review`)
- QA (→ `/qa`)
- Refactor beyond TDD's refactor step (→ `/refactor`)
- Ship or merge (→ human)

## Oracle

- [ ] `skills/implement/SKILL.md` exists, <300 lines
- [ ] Given a context packet, produces code + tests on a feature branch
- [ ] All tests green at exit; working tree clean
- [ ] Does not inline shape/review/ship logic
- [ ] Eval set: 5 shaped tickets → 5 green implementations, no regressions vs inlined pre-032 build loop

## Non-Goals

- Shape logic — hard error if input isn't a complete context packet
- Multi-ticket operation — one packet per invocation
- Handling merge conflicts — caller's concern
- Prod deploys — out of scope

## Related

- Blocks: 032 (`/deliver` composer needs `/implement` to exist)
- Depends on: nothing — can be extracted from the pre-032 `/autopilot` (now `/deliver`) today
- Uses: `builder` agent (existing)
