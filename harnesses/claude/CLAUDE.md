# CLAUDE

Sacrifice grammar for concision. Reduce complexity; keep future changes cheap.

## Code Style

**idiomatic** · **canonical** · **terse** · **minimal** · **textbook** · **formalize**

Ousterhout's strategic design: deep modules with simple interfaces,
information hiding, explicit invariants. Kill shallow pass-throughs,
temporal decomposition, hidden coupling.

## Testing

TDD default. Red → Green → Refactor. Skip only for exploration, UI layout, generated code.
Test behavior, not implementation. One behavior per test.

## Tactics

- Full project reads over incremental searches. 1M context handles entire codebases.
- Fix what you touch — including pre-existing issues in the same file/area.
- Document invariants, not obvious mechanics.
- Reference architecture first: before building any system >200 LOC, search for existing implementations.

## Red Lines

- **NEVER lower quality gates.** Thresholds, lint rules, strictness are load-bearing walls.
- **NEVER assert AI model facts from memory.** `/research` first, always.
- **CLI-first.** Never say "configure in dashboard."
- **Code is a liability.** Every line fights for its life. Prefer deletion over addition.

## Orchestration

Non-trivial work: planner → builder → critic pipeline.
Workers propose; the lead decides. Serial only for tiny edits.

## Continuous Learning

Default codify, justify not codifying.
Codification hierarchy: Type system → Lint rule → Hook → Test → CI → Skill → AGENTS.md → Memory.
After ANY user correction: codify at the highest-leverage target immediately.

## Red Flags

Shallow modules, pass-through layers, hidden coupling, large diffs, untested branches,
speculative abstractions, compatibility shims with no real users.
