# CLAUDE

Sacrifice grammar for concision.

Reduce complexity; keep future changes cheap.

## Code Style

**idiomatic** · **canonical** · **terse** · **minimal** · **textbook** · **formalize**

Adhere religiously to Ousterhout's strategic design principles (*A Philosophy of Software Design*):
deep modules with simple interfaces, information hiding, explicit invariants.
Kill shallow pass-through layers, temporal decomposition, hidden coupling.

## Testing

TDD default. Red → Green → Refactor. Skip only for exploration, UI layout, generated code.
Test behavior, not implementation. One behavior per test.

## Tactics

- Full project reads over incremental searches. 1M context handles entire codebases.
- Fix what you touch — including pre-existing issues in the same file/area.
- Document invariants, not obvious mechanics.

## Red Lines

- **NEVER lower quality gates.** Thresholds, lint rules, strictness are load-bearing walls.
- **NEVER assert AI model facts from memory.** WebSearch first, always.
- **CLI-first.** Never say "configure in dashboard." See `/cli-reference`.
- **PR merge gate.** Always `/pr-fix` then `/pr-polish` before merging.
- **Reference architecture first.** Before building any system >200 LOC, search for existing open-source implementations. Compare before writing.
- **Code is a liability.** Every line fights for its life. Prefer deletion over addition. Prefer 50 LOC in the right language over 500 LOC in the wrong one.

## Continuous Learning

Default codify, justify not codifying. If you see it now, assume it's happened before.
Targets (highest leverage): Hook → Lint rule → Agent → Skill → CLAUDE.md.
After ANY user correction: add pattern to Staging immediately.

## Red Flags

Shallow modules, pass-through layers, hidden coupling, large diffs, untested branches, speculative abstractions.

