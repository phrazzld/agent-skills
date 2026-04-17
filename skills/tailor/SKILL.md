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
files under the target repo root; never touches the global spellbook
or the user's `~/.claude`. Rollback is automatic on Phase 5 loss —
tailored artifacts do not stay on disk unless they measurably beat
the baseline.

Not to be confused with `/tailor-skills`, which picks *which global
skills* load for this repo. `/tailor` specializes the content of
the harness; `/tailor-skills` narrows the catalog. Run `/tailor-skills`
first.

## Invariants

- Never modify files under `$SPELLBOOK` or `~/.claude`.
- Never write `.claude/.tailor/manifest.json` without a completed
  Phase 5 verdict. No manifest = treat as never-tailored.
- Never exceed 2 skills in `.claude/skills/` (MVP cap). Enforced
  structurally by `scripts/tailor-lint.sh`.
- Never create `.claude/skills/<name>/` where `<name>` is a global
  spellbook primitive. Also enforced by `tailor-lint.sh`.
- Never loop the planner/critic dialectic. One round. Critic blocks
  → abort before Phase 4. No round 2 — that is where `/focus` rotted.
- Never fall back to a synthetic canned task when the repo has no
  test or lint command. Abort Phase 5 with a clear message; don't
  write the manifest. Per `references/eval-task.md`.

## Composition

```
/tailor [generate | refresh]
    │
    ▼
┌─ Phase 0: Preflight ──────────────────┐
│  cooldown: manifest < 7d?             │ reject unless --force
│  backup: .tailor-backup-<ts>/         │ restore path for Phase 5 rollback
└───────────────────────────────────────┘
    │
    ▼
┌─ Phase 1: Repo analysis — 3 parallel Explore subagents ─┐
│  lang-detector     → primary_lang, frameworks            │
│  ci-inspector      → test_cmd, lint_cmd, build_cmd       │
│  existing-harness  → current .claude/ + AGENTS.md state  │
└──────────────────────────────────────────────────────────┘
    │ verdicts in one round; ~15k tokens total
    ▼
┌─ Phase 3: Dialectic (one round, no loop) ───────────────┐
│  planner → proposed artifact tree                        │
│  critic  → apply references/focus-postmortem.md          │
│  any blocking objection → abort before Phase 4           │
└──────────────────────────────────────────────────────────┘
    │ critic returns empty objection list
    ▼
┌─ Phase 4: Generation ───────────────────────────────────┐
│  .claude/settings.local.json  (permissions + MCP)        │
│  AGENTS.md                    (build/test/gotchas)       │
│  .claude/.tailor/manifest.json (WITHOUT eval block yet) │
│  MVP: no skills/, agents/, hooks/                        │
└──────────────────────────────────────────────────────────┘
    │
    ▼
┌─ Phase 5: A/B eval — killswitch ────────────────────────┐
│  derive canned task per references/eval-task.md          │
│  scripts/tailor-ab.sh "<task>" "$PWD"                    │
│    exit 0 (ship)    → amend manifest with eval block     │
│    exit 1 (rollback) → restore backup; delete manifest    │
│    exit 2 (infra)    → restore backup; exit 3            │
└──────────────────────────────────────────────────────────┘
    │
    ▼
  report verdict + deltas (ship) or rollback reason (loss)
```

## Phase Details

### Phase 0 — Preflight

Read `.claude/.tailor/manifest.json`. If `generated_at` is less
than 7 days old and `--force` was not passed, reject with the
remaining cooldown + instructions. Rationale: /tailor is not a
continuous loop; rerunning on fresh signal is the user's call.

Back up the current harness state:

```
.tailor-backup-<unix-ts>/
├── .claude/       (whole-dir copy if present)
├── AGENTS.md      (file copy if present)
└── CLAUDE.md      (file copy if present)
```

The backup path is Phase 5's rollback target. On ship, delete the
backup on exit. On rollback or infra failure, restore from it.

### Phase 1 — Repo analysis

Dispatch three Explore subagents in **one message, three Agent tool
calls in parallel**. Each returns a focused verdict; the skill's
main context never reads source files directly.

- **lang-detector** — inspect manifest files (Cargo.toml,
  package.json, pyproject.toml, go.mod, Gemfile…) and entrypoints.
  Return: `{primary_lang, secondary_langs, frameworks, entrypoint}`.
- **ci-inspector** — read CI configs (`.github/workflows/`,
  `.circleci/`, `dagger.json`, `Makefile`, etc.). Return:
  `{test_cmd, lint_cmd, build_cmd, ci_platform}`. If no test
  command is findable, return `test_cmd: null` — Phase 5 will see
  this and abort.
- **existing-harness** — read current `.claude/`, `AGENTS.md`,
  `CLAUDE.md`, and any per-repo hooks. Return a concise map so
  Phase 3 doesn't redundantly suggest things already present.

These three feed the `repo_sig` section of the manifest.

### Phase 3 — Dialectic (one round)

First, a planner pass (in-context, use the `planner` agent):

> Given the repo_sig from Phase 1, propose the artifacts to generate
> for /tailor MVP. In-scope: `.claude/settings.local.json`
> (permissions allowlist + MCP settings), `AGENTS.md` (build/test
> commands, hot paths, gotchas). Out of scope: `.claude/skills/`,
> `.claude/agents/`, hooks, anything under $SPELLBOOK or ~/.claude.

Then a critic pass (use the `critic` agent with
`references/focus-postmortem.md` as explicit input). The critic
returns a list of blocking objections, possibly empty.

**Stopping rule: if the critic returns ANY blocking objection,
/tailor aborts. Do not iterate.** Print the objections, do not
write Phase 4 files, exit non-zero. This is the rule that /focus
didn't have — the reason /tailor exists.

### Phase 4 — Generation

On critic-clear, write (in this order):

1. `.claude/settings.local.json` — permissions allowlist derived
   from `ci-inspector.test_cmd`, `lint_cmd`, `build_cmd` (e.g.,
   `Bash(cargo test:*)`, `Bash(cargo clippy:*)`), plus any MCP
   servers the existing-harness reader found in use.
2. `AGENTS.md` — sections for build/test commands (verbatim from
   ci-inspector), hot paths (from `lang-detector.entrypoint` +
   framework conventions), and known gotchas (only if the existing
   reader surfaced them — do not invent).
3. `.claude/.tailor/manifest.json` with `schema_version: 1`,
   `generated_at` (ISO 8601), `spellbook_version` (from
   `git -C $SPELLBOOK rev-parse HEAD`), `repo_sig` (from Phase 1),
   `owned_files` (each written path + sha256), and **no `eval`
   block yet** — Phase 5 adds it on ship.

### Phase 5 — A/B eval (killswitch)

Derive the canned task per `references/eval-task.md`. Priority:
`test_cmd` → `lint_cmd` → **abort** (no synthetic fallback).

Invoke the runner:

```
scripts/tailor-ab.sh "<derived task>" "$PWD"
```

The runner writes verdict JSON to stdout. Route by its exit code:

- **exit 0 (ship)** — parse the verdict JSON, amend the manifest
  with an `eval` block containing `{task, baseline: {...},
  tailored: {...}, deltas, verdict: "ship"}`, delete the backup dir,
  print the wall-time and tool-call deltas to the user, exit 0.
- **exit 1 (rollback)** — the runner already printed the reason.
  Delete `.claude/`, `AGENTS.md`, `CLAUDE.md`, and the partial
  manifest from the current worktree. Restore from
  `.tailor-backup-<ts>/`. Exit 1 after surfacing the rollback
  reason in one line.
- **exit 2 (infra/usage failure)** — same rollback path. Exit 3
  (distinguishable upstream) with an explicit infra error.

## Failure Modes

| Failure | Recovery |
|---|---|
| ci-inspector returns `test_cmd: null` AND `lint_cmd: null` | Abort before Phase 5; delete Phase 4 artifacts; restore backup; exit 3 ("no eval anchor") |
| Phase 3 critic blocks | Print objections; no Phase 4 writes; restore backup (identity — nothing changed); exit 2 |
| Phase 5 rollback (exit 1) | Restore `.tailor-backup-<ts>/`; delete manifest; exit 1 with reason |
| Phase 5 infra error (exit 2) | Restore backup; exit 3 |
| Cooldown check fails (<7d, no --force) | Print remaining wait + `--force` hint; exit 0 (preflight-rejected, not an error) |
| `tailor-lint.sh` pre-commit rejects user's later edits | Hook blocks locally; user reads the lint error; resolves before commit |
| Human edited a generated file between runs | `manifest.owned_files[].hash` detects drift on next `refresh`; /tailor preserves human changes and re-plans around them |

## Operational Notes

- **Cost floor.** Phase 1 runs three subagents in parallel
  (~15k tokens). Phase 5 runs two `claude -p` sessions over
  ephemeral worktrees. Cold-cache runs cost ~$0.30 per session
  on typical repos; Phase 5 is ~$0.60–$1.00 end-to-end. Set
  `TAILOR_AB_BUDGET_USD` to cap per-run spend; defaults to $0.40.
- **Permissions in headless runs.** `tailor-ab-spike.sh` uses
  `--permission-mode bypassPermissions` because headless tool use
  otherwise stalls. This is safe for the canned task because both
  worktrees are ephemeral and cleaned up on exit.
- **Dogfooding.** Validate on three real repos before trusting
  verdicts at scale. If three can't show tailored > vanilla, the
  MVP premise is falsified — pivot to Alt C (LLM-as-judge) per
  `backlog.d/029-tailor-per-repo-harness-generator.md`.

## References

- `references/focus-postmortem.md` — critic's 4-criterion rejection checklist
- `references/eval-task.md` — Phase 5 canned-task derivation rules
- `scripts/tailor-ab.sh` — Phase 5 A/B runner (exit 0/1/2 routing)
- `scripts/tailor-ab-spike.sh` — single-run measurement library
- `scripts/tailor-lint.sh` — pre-commit enforcement (shadow + cap)
- `backlog.d/029-tailor-per-repo-harness-generator.md` — full spec, v2 overlay design, implementation notes
- `skills/tailor-skills/SKILL.md` — companion subset picker; run before /tailor
