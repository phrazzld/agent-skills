# Critic Checklist — /focus postmortem

The critic runs once in `/tailor` Phase 2 against every artifact the
planner proposes. One round. No loop. Any blocking objection aborts
/tailor before Phase 3.

This is **the** structural differentiator from `/focus`, which shipped
71 commits over two months (87 skills, 41 auditors) before being
killed in March 2026 for ceremony-to-value inversion. The four
criteria below encode the failure modes.

Apply in order. First rejection wins; stop evaluating.

## 1. Does this already exist globally?

**Reject if yes.** Global spellbook primitives (`groom`, `shape`,
`deliver`, `flywheel`, `code-review`, `settle`, `reflect`, `harness`,
`tailor`) and the philosophy bench (`beck`, `carmack`, `grug`,
`ousterhout`, `planner`, `critic`) are canonical. A project-local
copy is either dead weight or silent divergence.

- Reject: `.claude/skills/code-review/`
- Allow: an AGENTS.md pointer *to* the global `/code-review`

## 2. Would a scaffold-on-demand skill cover it?

**Reject if yes.** `/qa scaffold`, `/demo scaffold`, etc. generate
repo-specific scaffolding on invocation. Don't pre-bake their output.

- Reject: a tailored `/qa` hardcoding test golden paths
- Allow: a `settings.local.json` permissions entry that lets `/qa
  scaffold` run without prompts

## 3. Is the scope focused, or 41-auditor ceremony?

**Reject if the proposal exceeds 2 tailored skills**, or qualitatively
sprawls into near-duplicate reviewers / kitchen-sink skills.
`tailor-lint.sh` enforces the numeric cap; the critic also rejects
qualitative bloat.

- Reject: four near-duplicate Rust reviewers
  (`unsafe-`, `lifetime-`, `trait-bound-`, `generic-reviewer`)
- Allow: one focused `rust-unsafe-reviewer` if the repo has unusual
  `unsafe` patterns that justify it

## 4. Can Phase 4 prove the artifact's value?

**Reject if removing this file wouldn't plausibly change the A/B
outcome.** Every artifact must pay rent in measurable `tool_calls`,
`wall_s`, or `passed` deltas against the canned task. Nice-to-have
documentation the agent wouldn't act on during tool execution fails
this test.

- Reject: an `ARCHITECTURE.md` about repo history
- Allow: `AGENTS.md` build/test commands (change which Bash
  invocations the agent runs)

## Stopping condition

Critic emits a list of blocking objections (possibly empty).
/tailor Phase 3 proceeds iff empty. No round 2. No appeals.
User can re-run `/tailor` with different inputs or adjust the
planner's instructions.
