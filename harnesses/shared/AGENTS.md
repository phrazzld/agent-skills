# AGENTS

Engineering doctrine. One file, symlinked to every harness.

## The Norman Principle

When an agent makes an error, it is a system error.

> "If the system lets you make the error, it is badly designed.
> And if the system induces you to make the error, then it is really badly designed."
> — Don Norman, *The Design of Everyday Things*

Redesign the stove, don't teach the burner mapping:
- **Prevent > Detect > Recover > Document**
- If the harness allows the error, it's a harness bug
- If the harness's instructions induced the error — worst case
- Every agent mistake is a bug report against the system

## Code Style

**idiomatic** · **canonical** · **terse** · **minimal** · **textbook** · **formalize**

Ousterhout's strategic design: deep modules with simple interfaces,
information hiding, explicit invariants. Kill shallow pass-throughs,
temporal decomposition, hidden coupling.

## Doctrine

- Root-cause remediation over symptom patching
- Code is a liability — every line fights for its life. Prefer deletion over addition
- Reference architecture first: search before building any system >200 LOC
- Favor convention over configuration
- Full project reads over incremental searches
- Fix what you touch — including pre-existing issues in the same area
- Document invariants, not obvious mechanics

## Testing

TDD default. Red → Green → Refactor. Skip only for exploration, UI layout, generated code.
Test behavior, not implementation. One behavior per test.

## Red Lines

- **NEVER lower quality gates.** Thresholds, lint rules, strictness are load-bearing walls.
- **NEVER assert model facts from memory.** Research first, always.
- **CLI-first.** Never say "configure in dashboard."

## Orchestration

Non-trivial work: planner → builder → critic pipeline.
Workers propose; the lead decides. Serial only for tiny edits.
For delegated work: surface progress delta and stall detection.

## Continuous Learning

Default codify, justify not codifying.
Codification hierarchy: Type system → Lint rule → Hook → Test → CI → Skill → AGENTS.md → Memory.
After ANY correction: codify at the highest-leverage target immediately.
Every agent error is a harness bug. Prevent > Detect > Recover > Document.

## Output

Keep context high-signal and minimal. Evidence, decisions, residual risks.
If output exceeds 1000 characters, append a TLDR (1–3 bullets).

## Red Flags

Shallow modules, pass-through layers, hidden coupling, large diffs,
untested branches, speculative abstractions, stale context,
responding to agent errors with prose instead of structural fixes.
