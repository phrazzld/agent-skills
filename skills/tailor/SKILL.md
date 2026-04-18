---
name: tailor
description: |
  Generate a project-local harness specialized to this repo. Writes
  .claude/settings.local.json + AGENTS.md, then A/B-evaluates them
  against a canned task and rolls back automatically on regression.
  The structural differentiator from /focus (killed March 2026) is
  the Phase 5 killswitch: tailored artifacts do not survive unless
  they measurably beat the vanilla baseline.
  Use when: "tailor this repo", "generate project harness", "tune
  agents for this codebase", "specialize claude to this repo". Run
  /tailor-skills first to scope the global catalog; /tailor then
  specializes the artifacts *within* that scope.
  Trigger: /tailor.
argument-hint: "[generate|refresh] [--force] [--task \"<canned-task>\"]"
---

# /tailor

Specializes the agent harness for THIS repo. Writes only uncommitted
files under the target repo root; never touches `$SPELLBOOK` or
`~/.claude`. Rollback is automatic on Phase 5 loss.

## Layering with globals

/tailor operates *on top of* two layers already in place:

1. **Global skills** in `~/.claude/skills/` (symlinked by spellbook's
   bootstrap).
2. **Scoped globals** — if the user ran `/tailor-skills` in this repo,
   `.spellbook.yaml` already narrowed those symlinks to a subset.

/tailor does not re-pick the skill set (that is `/tailor-skills`). It
writes content that parameterizes the *already-loaded* scoped set for
this repo: build/test commands in `AGENTS.md`, a permissions allowlist
in `settings.local.json`. Phase 5's baseline worktree strips only
project-level files; the scoped globals still load. So the A/B asks:
does project-local tailoring add value on top of the scoped globals?

## Invariants

- Never modify files under `$SPELLBOOK` or `~/.claude`.
- Never write `.claude/.tailor/manifest.json` without a completed
  Phase 5 verdict. No manifest = never-tailored.
- Never exceed 2 skills in `.claude/skills/` (MVP cap). `tailor-lint.sh`
  enforces structurally.
- Never shadow a global workflow-primitive name in `.claude/skills/`
  (also `tailor-lint.sh`).
- One round of planner/critic dialectic. Critic blocks → abort.
  **No round 2. That is where `/focus` rotted.**
- If the repo has no test or lint command, abort before Phase 5 —
  no synthetic canned task. See `references/eval-task.md`.

## Phases

**0. Preflight.** Reject if the existing manifest is <7 days old
(unless `--force`). Back up current `.claude/`, `AGENTS.md`,
`CLAUDE.md` to `.tailor-backup-<ts>/` as the Phase 5 rollback target.

**1. Repo analysis.** Three parallel Explore subagents: lang-detector
(primary_lang, frameworks, entrypoint); ci-inspector (test_cmd,
lint_cmd, build_cmd, ci_platform); existing-harness (current
`.claude/`, `AGENTS.md`, `.spellbook.yaml`, any hooks). Verdicts feed
Phase 3's `repo_sig`.

**2. Dialectic (one round).** Planner proposes artifacts within MVP
scope (`settings.local.json`, `AGENTS.md` sections only — no skills,
agents, hooks). Critic applies `references/focus-postmortem.md`
checklist. Any blocking objection aborts before Phase 3.

**3. Generation.** Write `.claude/settings.local.json`, `AGENTS.md`,
and `.claude/.tailor/manifest.json` with `schema_version`,
`generated_at`, `spellbook_version`, `repo_sig`, and `owned_files`
(sha256 per path). **No `eval` block yet** — Phase 5 adds it on ship.

**4. A/B eval (killswitch).** Derive the canned task from Phase 1
per `references/eval-task.md`. Abort here if neither `test_cmd` nor
`lint_cmd` exists.

Run via Bash tool (no dedicated script — the plumbing is trivial):

```bash
AB=$(git rev-parse --git-common-dir)/tailor-ab-$$
git worktree add --detach "$AB/baseline" HEAD
git worktree add --detach "$AB/tailored" HEAD
(cd "$AB/baseline" && rm -rf .claude AGENTS.md CLAUDE.md)
(cd "$AB/tailored" && rm -rf .claude AGENTS.md CLAUDE.md)
cp -R .claude AGENTS.md CLAUDE.md "$AB/tailored/" 2>/dev/null || true

baseline=$(TAILOR_AB_CWD="$AB/baseline" scripts/tailor-ab-spike.sh "<task>")
tailored=$(TAILOR_AB_CWD="$AB/tailored" scripts/tailor-ab-spike.sh "<task>")

git worktree remove --force "$AB/baseline" "$AB/tailored"
```

Each run emits `{tool_calls, wall_s, passed}`. Compare the two by
judgment against this rule:

> Ship iff **≥2 of 3 metrics favor tailored AND none regress.** Tie
> (wall_s within ±5%, or identical tool_calls, or matching passed) is
> neutral. Any metric strictly worse on tailored blocks the ship.

Apply directly — don't serialize into a scorer script. The rule is
one sentence; the model reads both JSONs and decides.

**Ship (B won):** amend manifest with `eval` block (task, both metric
triplets, verdict, reason, spike_version). Delete backup. Report
deltas to the user.

**Rollback (B lost or tied):** `rm -rf .claude AGENTS.md CLAUDE.md`;
restore from `.tailor-backup-<ts>/`; delete the partial manifest; exit
non-zero with the blocking metric(s) named in one line.

## Failure modes

| Failure | Recovery |
|---|---|
| No `test_cmd` and no `lint_cmd` | Abort before Phase 4; exit 3 with "no eval anchor" |
| Critic blocks in Phase 2 | Print objections; no files written; exit 2 |
| Phase 4 A/B: tailored does not win | Restore backup; delete manifest; exit 1 |
| Cooldown check fails | Print remaining wait + `--force` hint; exit 0 |
| Ambient dirty tree | Refuse; worktrees need clean HEAD snapshot |

## Notes

Cold-cache `claude -p` runs cost ~$0.30 on typical repos; Phase 4
end-to-end is ~$0.60–$1.00. Set `TAILOR_AB_BUDGET_USD` to cap
per-run spend. Headless tool use requires
`--permission-mode bypassPermissions` — already in the spike.

Validate the MVP premise on three real repos before trusting verdicts
at scale. If three can't show tailored > baseline, the premise is
falsified — pivot to Alt C (LLM-as-judge) per
`backlog.d/029-tailor-per-repo-harness-generator.md`.

## References

- `references/focus-postmortem.md` — critic's rejection checklist
- `references/eval-task.md` — canned-task derivation
- `scripts/tailor-ab-spike.sh` — headless measurement (JSONL parse)
- `scripts/tailor-lint.sh` — pre-commit shadow + cap enforcement
- `skills/tailor-skills/SKILL.md` — companion subset picker
- `backlog.d/029-tailor-per-repo-harness-generator.md` — full spec + v2 overlay design
