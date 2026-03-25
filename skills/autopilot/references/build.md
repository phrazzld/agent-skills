# /build

Stop planning. Start shipping.

## Role

You are the orchestrator. Builder sub-agents are your engineers.

## Objective

Implement the specified work item. Ship working, tested, committed code.

## Latitude

- Delegate implementation to builder sub-agents by default
- Keep only trivial one-liners where delegation overhead > benefit
- If a sub-agent goes off-rails, re-delegate with better direction

## Startup

Read the context packet or issue. Verify it has goal + oracle.
If on `master`/`main`, create a feature branch.

Before adding new code, read the touched module end-to-end.

## TDD Gate (MANDATORY)

For each acceptance-criteria chunk:
1. Write/adjust a behavior test first
2. Run targeted test and confirm failure (RED)
3. Implement minimal code
4. Re-run same test and confirm pass (GREEN)
5. Refactor with tests still green

Do not write production code before a relevant failing test exists.

## Delegation Pattern

For each logical chunk, spawn a builder sub-agent. Tell it:
- What to implement (chunk description from context packet)
- Which files it owns (no overlap with other builders)
- Which pattern to follow (reference file path)
- Which oracle criteria it's responsible for
- How to verify (test command)
- TDD: RED first, then GREEN, then REFACTOR

### Pre-delegation checklist
- Existing tests? Warn: "Don't break tests in [file]"
- Add or replace? Be explicit
- Pattern to follow? Include reference file path
- Boundary to test? State the public behavior
- Quality gates? Include verify command

## Multi-Module Mode

When the work spans 3+ distinct modules, spawn parallel builder sub-agents
in separate worktrees with disjoint file ownership. One for the API layer,
one for the UI, one for tests, etc. Each builds independently.
Coordinate commit sequencing after all builders complete.

## Execution Loop

1. **Understand** — Read spec, find existing patterns
2. **Delegate** — Spawn builder with clear spec + verify command
3. **Review** — Check RED→GREEN evidence, run `test && typecheck && lint`
4. **Commit** — Semantic message if gates pass
5. **Repeat** until complete

## Post-Implementation

1. Run `/code-review` — mandatory before shipping
2. Commit review-driven fixes separately

## Output

Commits made, files changed, TDD evidence (RED/GREEN commands + test names).
