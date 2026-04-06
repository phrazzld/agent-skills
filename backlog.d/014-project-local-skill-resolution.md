# Project-local skill resolution doesn't override global skills

Priority: high
Status: done
Estimate: M

## Goal

Project-local skills in `.claude/skills/` should override global skills in
`~/.claude/skills/` when both define the same skill name. Currently the global
fallback always wins.

## Evidence

Scaffolded `/qa` and `/demo` for thinktank (misty-step/thinktank#286):
- Wrote `.claude/skills/qa/SKILL.md` (name: `thinktank-qa`)
- Wrote `.claude/skills/demo/SKILL.md` (name: `thinktank-demo`)
- Invoked `/qa` and `/demo` from the thinktank project directory
- Both resolved to the global `~/.claude/skills/qa/` and `~/.claude/skills/demo/`
  fallback stubs instead of the project-local versions

## Hypotheses

1. **Name mismatch:** Global skill is `name: qa`, project-local is `name: thinktank-qa`.
   Resolution may key on the `name` field, not the directory name. Fix: use `name: qa`
   in the project-local skill.
2. **Directory not searched:** Claude Code may not search `.claude/skills/` at project
   root — may need `.claude/commands/` or a different convention.
3. **Load order:** Global skills load first and short-circuit before project-local
   skills are checked.

## Oracle

- [ ] `/qa` invoked from thinktank root resolves to `.claude/skills/qa/SKILL.md`
- [ ] `/demo` invoked from thinktank root resolves to `.claude/skills/demo/SKILL.md`
- [ ] Global fallback still fires in projects without a scaffolded skill

## Non-Goals

- Changing the global fallback skill content
- Supporting nested skill overrides (project > org > global)
