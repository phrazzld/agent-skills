# Shared Engineering Principles

Common doctrine across all harnesses (Claude, Codex, Pi).

## Code Style

**idiomatic** · **canonical** · **terse** · **minimal** · **textbook** · **formalize**

Ousterhout's strategic design: deep modules with simple interfaces,
information hiding, explicit invariants. Kill shallow pass-throughs,
temporal decomposition, hidden coupling.

## Engineering Doctrine

- Root-cause remediation over symptom patching
- Prefer the highest-leverage strategic simplification
- Code is a liability — every line fights for its life
- Favor convention over configuration
- Reference architecture first: search before building

## Testing

TDD default. Red → Green → Refactor.
Test behavior, not implementation. One behavior per test.

## Quality Bar

- NEVER lower quality gates — thresholds, lint rules, strictness are load-bearing
- NEVER assert model facts from memory — `/research` first
- Fix what you touch — including pre-existing issues in the same area

## Orchestration

Non-trivial work: planner → builder → critic.
Workers propose; the lead decides.

## Codification Hierarchy

When encoding a learning, target the highest-leverage mechanism:

```
Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
```

Default codify. Exception: justify not codifying.

## Red Flags

Shallow modules, pass-through layers, hidden coupling, large diffs,
untested branches, speculative abstractions, stale context.
