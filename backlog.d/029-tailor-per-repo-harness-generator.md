# `/tailor` — per-repo harness generator

Priority: high
Status: pending
Estimate: L (MVP ~1 week)
Aliases: `/attune`

## Goal

Generate a project-local harness (`.claude/` tree + `AGENTS.md`) specialized
to the target repo, **gated by an A/B eval that rolls back losers.**

Ownership: project-local artifacts only. Global workflow skills are
untouchable.

## The Central Question

Off-the-shelf Claude/Codex = minimum maintenance, minimum specificity.
Hand-tuned per-task harness = max quality, unbearable maintenance. Per-repo
is the **legibility unit** — a human reads `.claude/` and understands
"here's what this repo expects of an agent." Per-task (Live-SWE-agent)
regenerates context every prompt; off-the-shelf (Windsurf SWE-1.5 MoE)
undershoots on novel repo idioms.

## Why This Isn't `/focus` Rebuilt

`/focus` was 71 commits over two months, killed March 2026 (commit 6092678).
It did **discovery + install of existing skills** via embeddings: 87
candidate skills, 41 domain auditors. Failure mode: ceremony-to-value,
choice paralysis, install ≠ usage, no killswitch.

`/tailor` is different:

| `/focus` (killed) | `/tailor` |
|---|---|
| Discovery + install of existing skills | Generation of new bespoke artifacts |
| No killswitch | **A/B eval with rollback on loss (Phase 5)** |
| Ran continuously | Runs once; refresh is manual in MVP |
| 87 skills, 41 auditors | **Cap 2 domain skills in MVP** |
| Recommended skills | Writes files, bounded + gated |
| Prose rules on scope | **Loader-level enforcement** (pre-commit lint) |

If a global skill exists, tailor is forbidden to generate a project-local
override of it. Enforced structurally, not in prose. Closes bug #014
territory.

## State Model

Single source of truth: `.claude/.tailor/manifest.json`

```json
{
  "schema_version": 1,
  "generated_at": "2026-04-14T...",
  "spellbook_version": "<git sha>",
  "repo_sig": {
    "primary_lang": "rust",
    "frameworks": ["axum", "tokio"],
    "ci": "github-actions+dagger",
    "hotspots": ["src/ingest/...", "..."],
    "commit_count_at_gen": 12431
  },
  "owned_files": [
    {"path": ".claude/settings.local.json", "hash": "sha256:..."},
    {"path": "AGENTS.md", "hash": "sha256:...", "sections": [...]}
  ],
  "eval": {
    "task": "run test suite and report failures",
    "baseline": {"tool_calls": 47, "wall_s": 312, "passed": true},
    "tailored": {"tool_calls": 29, "wall_s": 198, "passed": true},
    "verdict": "win"
  },
  "domains_owned": ["qa"]
}
```

### Human-Edit Preservation

Any file whose on-disk hash ≠ `manifest.owned_files[].hash` is treated as
human-touched; subsequent regens preserve it. `<!-- tailor:keep -->` fences
in markdown mark permanent protected sections.

### Enforcement (structural, not prose)

`scripts/tailor-lint.sh` runs as pre-commit hook on `.claude/skills/`:
- Reject if `.claude/skills/<name>/SKILL.md` shadows a global workflow skill name (`groom`, `shape`, `autopilot`, `code-review`, `settle`, `reflect`, `iterate`, `tailor`, `harness`)
- Reject if the 2-skill MVP cap is exceeded

## Control Flow

```
/tailor [generate | refresh | drift]
    │
    ▼
┌─ Phase 0: Preflight ─┐
│ cooldown check       │ (reject if manifest <7 days, unless --force)
│ .claude backup       │
└──────────────────────┘
    │
    ▼
┌─ Phase 1: Repo analysis (parallel, 3 Explore agents) ─┐
│  lang-detector    → stack, frameworks                  │
│  ci-inspector     → build/test/lint commands, gates    │
│  existing-harness → current .claude/, AGENTS.md        │
└────────────────────────────────────────────────────────┘
    │ verdicts in ~90s, ~15k tokens
    ▼
┌─ Phase 3: Dialectic (1 round, no loop) ─┐
│  planner → proposed artifacts tree       │
│  critic  → focus-postmortem checklist    │
│  lead    → synthesize; abort if critic blocks │
└──────────────────────────────────────────┘
    │
    ▼
┌─ Phase 4: Generation (diff-and-confirm gate) ─┐
│  writes:                                       │
│   .claude/settings.local.json                  │
│   AGENTS.md (repo-specific content only)       │
│   .claude/.tailor/manifest.json                │
│  (MVP stops here — no skills/agents/hooks)     │
└────────────────────────────────────────────────┘
    │
    ▼
┌─ Phase 5: A/B eval (killswitch) ─────────────┐
│  ephemeral worktree A: CLAUDE_SKIP_PROJECT=1  │
│  ephemeral worktree B: tailored               │
│  run canned task (from ci-inspector output)   │
│  compare: tool_calls, wall_s, passed          │
│  if B not better on ≥2 of 3 → ROLLBACK        │
│     delete owned_files, restore backup        │
│     surface delta to user, exit non-zero      │
└───────────────────────────────────────────────┘
    │
    ▼
  write manifest, done
```

MVP skips: Phase 2 (external research via /research), Phase 6 (drift
detection at 200 commits / 90 days). Refresh is manual in MVP.

### Critic Checklist (`references/focus-postmortem.md`)

The critic attacks each proposed artifact against:
- Does this exist globally already? (If yes — reject.)
- Would scaffold-on-demand (`/qa scaffold`, `/demo scaffold`) cover it? (If yes — reject.)
- Is this a 1–3 workflow domain skill, or 41-auditor ceremony? (If ceremony — reject.)
- Can this file's value be proven in Phase 5 eval? (If no — reject.)

Stopping condition: critic returns zero blocking objections in round 1.
No round 2. That's where `/focus` rotted.

## Components

| Component | Type | Owns |
|---|---|---|
| `skills/tailor/SKILL.md` | skill | orchestration |
| `skills/tailor/references/focus-postmortem.md` | reference | critic checklist |
| `skills/tailor/references/eval-task.md` | reference | how to derive canned task from ci-inspector output |
| `scripts/tailor-lint.sh` | script | shadow-name + cap enforcement (pre-commit) |
| `scripts/tailor-ab.sh` | script | ephemeral worktree A/B runner |
| `agents/planner.md`, `agents/critic.md` | existing | reused for Phase 3 |

## What Specializes Per-Repo vs Global

| Layer | Owner | Examples |
|---|---|---|
| Workflow primitives | **Global (spellbook)** | groom, shape, autopilot, code-review, reflect, settle, harness, iterate, tailor |
| Philosophy bench | Global | beck, carmack, grug, ousterhout, planner, critic |
| Domain skills | **Per-repo (generated)** | `<repo>-migrations`, `<repo>-fixtures`, `<repo>-deploy` — v2+ |
| AGENTS.md content | Per-repo | build/test commands, hot paths, gotchas |
| Hooks | Per-repo | pre-edit lint, post-test runner — v2+ |
| Permissions allowlist | Per-repo | actual binaries used (`settings.local.json`) |
| Reviewer agents | Per-repo only if stack-specific beats generic | `rust-unsafe-reviewer` yes, `general-reviewer` no — v2+ |

Sharp line enforced by `tailor-lint.sh`.

## Interfaces

- **Input:** target repo (pwd), optional `--force`, optional `--task "<canned eval>"`
- **Output:** `.claude/settings.local.json`, `AGENTS.md` deltas, `.claude/.tailor/manifest.json`, stdout A/B summary
- **Exit codes:** 0 = win, 1 = rollback (tailored lost), 2 = user rejected diff, 3 = preflight failed

## Failure Modes

| Failure | Recovery |
|---|---|
| A/B eval: tailored loses | Rollback: delete owned_files, restore `.claude.backup.<ts>/`, log delta, exit 1 |
| Eval task doesn't exist (no tests) | Abort Phase 5, refuse to write manifest (no generation without eval) |
| Human edited generated file between runs | Refresh detects hash mismatch; preserves human version, re-plans around it |
| Generation attempts shadowing skill | `tailor-lint.sh` rejects pre-commit |
| `ls .claude/skills/` exceeds cap | Lint rejects |

## Interaction Contract with `/iterate`

Two touchpoints:

1. **Auto-scaffold arbitration.** `/iterate` reads
   `.claude/.tailor/manifest.json:domains_owned` before auto-scaffolding
   `/qa` or `/deploy`. If tailor owns, iterate uses tailored artifact.
   Single ownership file. No race.

2. **Drift counter isolation** (v2). When `/tailor drift` counts commits,
   exclude refs matching `refs/heads/cycle/*` and
   `refs/heads/harness/auto-tune`. `/iterate` writes to those branches;
   they're not "repo evolution."

## MVP Slice (~week 1)

Ship only:
1. `skills/tailor/SKILL.md` (~200 lines, one mode: generate)
2. Phase 1 with **3 subagents only**: lang-detector, ci-inspector, existing-harness-reader
3. Skip Phase 2 entirely (no external context — pure introspection)
4. Phase 3: single planner pass + critic pass (no synthesis loop)
5. Phase 4 generates only `AGENTS.md` + `.claude/settings.local.json` + `.claude/.tailor/manifest.json` — no skills, no agents, no hooks
6. Phase 5: one canned task ("run test suite and report failures"). Compare wall time + tool-call count A vs B. **Rollback on loss active from day 1** (this is the central differentiator from /focus — non-negotiable).
7. Skip Phase 6. Refresh is manual via `/tailor generate --force`.

Validate premise: if three real repos can't show tailored > vanilla on the A/B, **kill before building Phases 2 and 6.**

## Oracle

- [ ] `/tailor generate` in a real repo produces `AGENTS.md` + `settings.local.json` + `manifest.json`
- [ ] `manifest.json` conforms to schema, includes `repo_sig`, `owned_files` with hashes, `eval` block
- [ ] A/B eval runs two ephemeral worktrees, reports tool_calls + wall_s + passed for both
- [ ] If tailored loses on ≥2 of 3 metrics, rollback happens automatically and user sees the delta
- [ ] `tailor-lint.sh` pre-commit hook rejects a test commit attempting to create `.claude/skills/shape/SKILL.md` (global shadow)
- [ ] `tailor-lint.sh` rejects a test commit exceeding 2-skill cap
- [ ] Human edit of `AGENTS.md` section outside `<!-- tailor:keep -->` fence is preserved on regen
- [ ] `/tailor` refuses to run if manifest is <7 days old without `--force`
- [ ] `/iterate` reads `manifest.json:domains_owned` and defers to tailored artifact when present
- [ ] Validated on 3 real repos showing tailored > vanilla on the A/B

## Non-Goals (MVP)

- External research phase (exemplar-finder, framework-harness-hunter, best-practice fetcher)
- Domain skill generation (`<repo>-migrations` etc.) — v2
- Reviewer agent generation (`rust-unsafe-reviewer` etc.) — v2
- Hook generation — v2
- Drift detection at 200 commits / 90 days — v2; manual refresh only in MVP
- Continuous monitoring — no background process
- Multi-round planner/critic loop — one round max
- Touching global spellbook skills — ever
- Merging or PRing changes — writes to working tree, human commits

## Related

- Depends on: 028 (`/iterate` — cycle events provide eval signal and refresh triggers in v2)
- Structurally supersedes: 014 (archived 2026-04-14 — commit `6d3944d` fixed
  the name-matching root cause; `tailor-lint.sh` prevents the broader class
  of shadowing bugs)
- Prior art (killed): `/focus` skill (commit 6092678, March 2026)

## Name Collision Notes

- `/tailor` has one niche collision (obscure `tailor` git-history rewriter, different domain — low practical risk)
- `/attune` fully clean
- `/forge` rejected (Laravel Forge, Foundry, Sourcegraph Forge)
- `/provision` rejected (Terraform/Ansible/Pulumi)
- `/init-harness` rejected (collides with native `/init` + spellbook `/harness`)
- `/scaffold-harness` rejected (collides with `/groom`'s scaffold alias)
