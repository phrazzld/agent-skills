# Shared Engineering Principles

Common doctrine across all harnesses. Each harness's config file
references or adapts these principles for its specific format.

## Code Style

**idiomatic** · **canonical** · **terse** · **minimal** · **textbook** · **formalize**

Adhere to Ousterhout's strategic design: deep modules with simple interfaces,
information hiding, explicit invariants. Kill shallow pass-through layers,
temporal decomposition, hidden coupling.

## Engineering Doctrine

- Root-cause remediation over symptom patching
- Prefer the highest-leverage strategic simplification
- Default to clean design over backwards compatibility
- Favor convention over configuration and Unix-style composition
- Code is a liability — every line fights for its life

## Testing

TDD default. Red → Green → Refactor. Skip only for exploration, UI layout, generated code.
Test behavior, not implementation. One behavior per test.

## Quality Bar

- **NEVER lower quality gates.** Thresholds, lint rules, strictness are load-bearing walls.
- **NEVER assert AI model facts from memory.** WebSearch first, always.
- Fix what you touch — including pre-existing issues in the same file/area.
- Document invariants, not obvious mechanics.

## Orchestration

For non-trivial multi-step work: planner + builder + critic.
Serial execution only for tiny, low-risk edits.
Workers propose; the lead decides.

## Continuous Learning

Default codify, justify not codifying.
Targets (highest leverage): Type system → Lint rule → Hook → Test → CI → Skill → AGENTS.md → Memory.

## Red Flags

Shallow modules, pass-through layers, hidden coupling, large diffs, untested branches,
speculative abstractions, compatibility shims with no real users.
