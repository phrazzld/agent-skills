# Create settle reference files — unblock /settle skill

Priority: high
Status: done
Estimate: M

## Goal

Create the three reference files that /settle SKILL.md references but don't exist. Move them to `skills/settle/references/` (settle owns its own references) and update SKILL.md paths.

## Non-Goals
- Don't rewrite the settle skill itself — just fill the missing references
- Don't duplicate content already inline in settle SKILL.md — extract and expand

## Files to Create

### skills/settle/references/pr-fix.md
Phase 1 methodology: conflict resolution (rebase vs merge decision tree), CI failure diagnosis (read logs, trace root cause, not band-aid), review comment triage (in-scope: fix; valid-but-out-of-scope: create git-bug issue; invalid: reply with reasoning).

### skills/settle/references/pr-polish.md
Phase 2 methodology: hindsight architecture review (shallow modules, pass-throughs, hidden coupling, temporal decomposition), test audit (coverage gaps, brittle tests, edge cases, assertion density), confidence assessment framework.

### skills/settle/references/simplify.md
Phase 3 methodology: survey-imagine-simplify protocol, deletion-first hierarchy (deletion > consolidation > abstraction > refactoring), complexity metrics (LOC, nesting depth, import fan-in/fan-out), Chesterton's fence check, diminishing returns signal.

## Oracle
- [x] `/settle` can read all three reference files without error
- [x] settle SKILL.md paths updated to `references/pr-fix.md` (not `../autopilot/references/`)
- [x] Each reference file < 200 lines (145, 158, 152)
- [x] Content extracted from settle SKILL.md inline descriptions, expanded with operational detail

## What Was Built
- `skills/settle/references/pr-fix.md` (145 lines) — Phase 1 methodology: rebase vs merge
  decision tree, CI failure diagnosis (root cause, not band-aid), review comment triage
  (fix/defer/reject), self-review protocol, async settlement.
- `skills/settle/references/pr-polish.md` (158 lines) — Phase 2 methodology: hindsight
  architecture review (7-item smell catalog from Ousterhout), test audit (coverage, brittleness,
  edge cases, assertion density), confidence assessment framework, agent-first assessment.
- `skills/settle/references/simplify.md` (152 lines) — Phase 3 methodology: survey-imagine-simplify
  protocol, deletion-first hierarchy, complexity metrics (LOC, nesting, fan-in/out, cyclomatic),
  Chesterton's fence check, diminishing returns signal.
- `skills/settle/SKILL.md` — Updated 3 paths from `../autopilot/references/` to `references/`.
