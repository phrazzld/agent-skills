---
name: tailor
description: |
  Tailor this repository's harness. Explore the repo, read prior
  session history, browse the spellbook catalog, and install a
  per-repo set of skills into a shared repo-local skill layer, with
  harness-specific entrypoints bridged back to that shared copy.
  Workflow skills get rewritten with this repo's commands and
  conventions embedded throughout — not a generic body with a
  repo-notes appendix. Use when: "tailor this repo", "configure the
  agent for this codebase", "set up a harness", "what skills apply
  here". Trigger: /tailor.
---

# /tailor

You're a tailor, not a wardrobe curator. Spellbook is a reference
library — fabric bolts, pattern drafts, technique books. For this
repo you *cut new garments* from that material, sized to fit in
every seam. Sewing an extra inch onto an off-the-rack jacket is not
tailoring; it's decoration.

## Shape of the work

1. **Explore.** Read enough of this repo to know what it is —
   language, frameworks, test/CI/deploy commands, size, domain.
   `package.json` / `Cargo.toml` / `pyproject.toml`, README, top-level
   structure.

   **Also inventory any existing harness.** Resolve the repo's
   **shared skill root** first: prefer an existing `.agent/skills/`,
   then an existing `.agents/skills/`. If neither exists yet, note
   that you will create one during install. Then inspect that shared
   root plus any existing harness bridges such as `.claude/skills/`,
   `.claude/agents/`, `.codex/skills/`, or `.pi/skills/`. If any
   have content, classify each entry:
   - **Tailor-owned** — has a `.spellbook` marker file with
     `source: <name>`, `installed: <timestamp>`, and (newer runs)
     `installed-by: tailor`. Safe to replace or remove.
   - **Scaffolded** — marker says `installed-by: <skill>-scaffold`
     (e.g. `qa-scaffold`, `demo-scaffold`) or the content is a
     scaffold output the repo explicitly authored. Preserve.
   - **Human-authored / unknown** — no marker, or marker from an
     era before current /tailor (no `installed-by` field). Preserve
     by default; flag for user confirmation before overwriting.

   Read the repo-level `.spellbook/repo-brief.md` if present —
   it's the prior run's brief, useful for diffing what changed.

2. **Prior art.** If your harness keeps session history for this repo
   (Claude Code: `~/.claude/projects/<path-hash>/`, Codex: analogous
   state path), read the session JSONL and memory files. What
   commands does the user actually run here? Where have they
   corrected you? Highest-signal input available.

3. **Browse.** Read the spellbook catalog — resolve via `readlink -f`
   on this SKILL.md, walk up to find `$SPELLBOOK/skills/` and
   `$SPELLBOOK/agents/`. Each primitive's frontmatter describes when
   to use it. That's your map.

4. **Synthesize a repo brief.** Write a short prose document
   (1-2 pages) that every downstream subagent will read. It is
   the shared spine that keeps rewrites coherent — without it,
   `/ci` calls the enforcing layer one thing and `/deliver` calls
   it another. Required anchors:

   - **Vision & purpose** — what this repo is building, for whom.
   - **Stack & boundaries** — layers and what each owns.
   - **Load-bearing gate** — *the* single declaration of what must
     pass to ship (e.g. "`pnpm ci:prepush` IS the gate; the Dagger
     lanes are its components"). Every gate-adjacent skill cites
     this verbatim.
   - **Invariants** — repo-wide rules (don't touch X, base branch
     is Y, commits go through Z).
   - **Known debts** — active issues, hot files, recurring failure
     modes, incident IDs. Pull from backlog, session history, and
     recent git log.
   - **Terminology** — what this repo calls its things.
   - **Session signal** — 3-5 recurring user corrections from
     session JSONL + 3-5 validated patterns the user has ratified.

   Short, dense, concrete. This is the single source of truth for
   "what is this repo" that every rewriter anchors to.

   **Persist the brief to `.spellbook/repo-brief.md`** at the repo
   root. Future runs read it to diff what's changed. Overwrite any
   existing version.

5. **Pick.** Dispatch planner + critic subagents with the repo
   brief attached. Planner proposes a set following the picking
   defaults below; critic applies `references/focus-postmortem.md`.

   **This is the planning leg of a planner → executor → critic
   loop.** The planner owns portfolio selection and rewrite briefs.
   It does not rewrite skills itself. The critic judges the plan
   before any install work begins and sends the planner back with
   specific objections when the pick is shallow, contradictory, or
   missing a repo-defining concern.

   **Planner must also propose ≥1 candidate domain invention per
   round**, with the concrete repo characteristic that would justify
   it (e.g., "`/convex-migrate` — this repo has live-traffic Convex
   schema evolution with `v.optional` upgrade paths in
   `convex/schema.ts`"). The critic evaluates via criterion 4. Landing
   on "none justified" is a valid outcome — the point is to force the
   thinking, not the output. Repos with load-bearing domain needs
   shouldn't slip through because the picker never considered them.

   Run the pick loop until critic-clear or 3 rounds, whichever comes
   first. If the planner and critic still disagree after 3 rounds,
   escalate to a second outside voice (`/research`, Thinktank,
   Gemini, or another fresh-context bench) before converging. Do
   not silently accept a fuzzy pick because the first pass looked
   plausible.

6. **Install.** First reconcile, then write. **The shared skill root
   is canonical; `.claude/skills/` is a bridge layer** — see
   cross-harness install invariant below.

   **Reconcile.** For each tailor-owned item inventoried in step 1
   (has `.spellbook` marker with `installed-by: tailor`):
   - Still in the new pick → replace with fresh rewrite.
   - Not in the new pick → remove the skill/agent directory. This
     is how `/tailor` self-heals canary-class fossils where the
     prior pick no longer matches the repo's current needs.

   For items without a `.spellbook` marker (unknown origin): do not
   touch without user confirmation. If a skill you're about to
   install collides with an unmarked existing skill of the same
   name, surface the conflict against the shared root: "existing
   `<shared-skill-root>/qa/` has no tailor marker — is it
   scaffolded, human-authored, or prior-era /tailor output?
   [preserve / replace / diff]".

   **Install shared, bridge per-harness.** Write every spellbook-
   distributed skill to the shared skill root
   (`.agent/skills/<name>/` or `.agents/skills/<name>/`, whichever
   this repo uses). Then create or refresh per-harness skill bridges
   back to that shared copy:

   - `.claude/skills/<name>` should be a symlink to the shared skill.
   - If the repo already has `.codex/skills/` or `.pi/skills/`
     bridges, keep them pointed at the same shared skill root.
   - Do not duplicate spellbook-distributed skill trees across
     multiple harness-specific directories.

   Agents are different: install them into the repo's existing agent
   directory (today that is usually `.claude/agents/`) unless the
   repo already documents a shared-agent convention. Do not invent a
   second agent layout just because the skills are shared.

   **Write `.spellbook` markers.** Every shared skill directory and
   every installed agent directory or file updated by this run gets a
   marker file at `<skill-or-agent>/.spellbook` with:

   ```yaml
   source: <primitive-name>
   installed: <ISO-8601 timestamp>
   installed-by: tailor
   tailor-version: <git commit SHA of spellbook/skills/tailor>
   category: universal | workflow | domain-invented
   ```

   Markers are how re-runs tell your output apart from human-
   authored content.

   **Shared scripts.** Tailored skills source shared shell helpers
   at a stable path. Install verbatim from `$SPELLBOOK/scripts/lib/`
   to `<repo-root>/scripts/lib/` (create if missing). Do not rewrite
   — divergence breaks sourcing in every consumer at once.

   | Path | Required by | Overwrite policy |
   |---|---|---|
   | `scripts/lib/backlog.sh` | `/ship`, `/groom tidy`, any skill reconciling master against `backlog.d/` | Copy verbatim; merge additively with unrelated files; never overwrite an unmarked script |
   | `scripts/lib/verdicts.sh` | `/ship`, `/settle` (git-native mode) | Copy verbatim; merge additively; never overwrite an unmarked script |

   Emit `.spellbook` markers alongside if the repo uses them for
   scripts; otherwise content parity against spellbook is the drift
   signal.

   Three categories, different install rules:

   - **Universal skills** — `groom`, `office-hours`, `ceo-review`,
     `reflect`, and similar that carry no repo-specific judgment.
     Copy their directories verbatim. Tailoring them would be
     artificial.
   - **Workflow skills** — `deliver`, `shape`, `implement`,
     `code-review`, `ci`, `refactor`, `qa`, `flywheel`, `deploy`,
     `monitor`, `diagnose`, `settle`, `ship`, `yeet`, `research`.
     **Rewrite each SKILL.md with this repo's commands, gates,
     conventions, and file paths embedded throughout.** Use the
     spellbook version as structural reference; fill every example,
     every command, every gotcha with repo-specific content. Preserve
     `references/` and `scripts/` from the source — they travel with
     the skill.

     **Dispatch one executor/rewriter subagent per workflow skill,
     in parallel. These executors are the executor leg of the loop.**
     Monolithic rewriting of 10+ skills in one context causes
     attention decay — the model pattern-matches "just copy this
     one too" and ships byte-identical output. Each executor
     receives: (a) the repo brief from step 4 (shared spine —
     cite these anchors, don't invent parallel vocabulary),
     (b) the planner's rewrite brief for that skill,
     (c) the spellbook source, (d) a reading assignment (see
     table below), (e) the mandate above.

     **Executor ownership is narrow and explicit.** Executors do not
     re-decide the portfolio and they do not argue policy in the
     abstract. Their job is to produce the best repo-specific rewrite
     for their assigned skill, then revise that rewrite in response
     to critic objections until it clears. Quality lives in this
     loop, not in post-hoc semantic lint rules.

     **Every workflow skill gets a reading assignment.** Skills
     with clear command anchors get rewritten easily; abstract-
     process skills (shape, refactor, code-review, flywheel,
     groom, implement, diagnose) are the ones that silently pass
     through because the source looks "already generic enough."
     They aren't — they're the skills where rewriters have to
     encode *this repo's judgment* as content, since there's no
     command to swap in. Assignments:

     | Skill | Read |
     |---|---|
     | ci | `.github/workflows/`, `dagger/`, `Dockerfile*`, CI status history |
     | deliver | `backlog.d/`, recent merged PRs, CONTRIBUTING.md |
     | deploy | `vercel.json`, `fly.*.toml`, `Dockerfile*`, deploy workflows |
     | settle | merge history, branch-protection rules, release tooling |
     | ship | squash-merge history (`git log --merges master`), drift contract (e.g. `docs/context/DRIFT-WATCHLIST.md`), PR templates, branch-naming conventions, `backlog.d/` + `backlog.d/_done/` layout |
     | yeet | commit history, `commitlint.config.*`, semver tooling |
     | qa | test configs, critical-path routes, Playwright/E2E specs |
     | demo | evidence scripts, demo capture tools |
     | monitor | signal surfaces (Sentry/Canary/health), alerts |
     | **shape** | `backlog.d/*.md`, recent shape docs, planning conventions, design-review lineage |
     | **refactor** | git churn (hot files), debt map, ARCHITECTURE.md, recent refactor PRs, named hotspots from repo brief |
     | **code-review** | AGENTS.md red flags, recent review threads, repo's philosophy bench, known anti-patterns |
     | **flywheel** | milestone tracker, issue IDs from repo brief, recent cycle reflections, deploy observables |
     | **groom** | `backlog.d/` (or equivalent file-driven tracker), GitHub issues if in use, grooming cadence, prioritization scheme |
     | **implement** | test runner command, mocking boundaries, test config, recent TDD cycles, branch-naming convention (`<type>/<id>-<slug>`) |
     | **diagnose** | signal surfaces, `.evidence/`, postmortems, observability tooling |
     | **research** | prior research artifacts (`.claude/research/`, `docs/research/`, `.groom/`), stack manifest (`package.json` / `Cargo.toml` / `pyproject.toml`) for domain cues, open research threads in `backlog.d/`, repo-specific source/doc lists |

     **Loop-core skills must not ship shallow.** The seven bolded
     rows above (shape, refactor, code-review, flywheel, groom,
     implement, diagnose) are the development loop's connective
     tissue — they encode *how this team builds here*. Their source
     text looks abstract because its job is generic wisdom. *Your*
     rewrite's job is to name what each skill MEANS in this
     codebase: the actual hotspots, the actual red flags, the
     actual backlog conventions, the actual milestone structure,
     the actual test command, the actual signal surfaces. "Generic
     refactoring discipline" is the source's contribution; your
     contribution is "in this repo, refactor first targets
     `getRevealPhaseState` (N+1, #146) and theme-token leakage."
     If your rewrite could describe any Next.js+Convex repo, any
     Elixir/Phoenix repo, any Rust service — it's shallow. Redo.

     **Backlog-automation load-bearing mandates.** The ship/groom/
     settle/flywheel/implement rewriters MUST preserve the trailer-
     based closure contract — it is not stylistic, it is what lets
     `/groom` sweep master and detect stale active tickets.
     Rewriters that "simplify" these away break the loop.

     | Skill | Must preserve |
     |---|---|
     | `/ship` | Branch-name regex `^(feat\|fix\|chore\|refactor\|docs\|test\|perf)/(\d+)-` (contract with `/implement`); trailer keys `Closes-backlog:` / `Ships-backlog:` (closing) + `Refs-backlog:` (reference), bare numeric IDs, injected via `git interpret-trailers`; `backlog_archive` step (`git mv backlog.d/<id>-*.md backlog.d/_done/` on feature branch pre-squash); explicit-body squash carrying trailers into master merge commit (`gh pr merge --squash --body` for GitHub, `git merge --squash` + `git commit -F` bare-git); `/reflect` invocation with bounded scope (branch, merged SHA, closing IDs, reference IDs); harness-branch routing — reflect outputs land on `harness/reflect-outputs`, never master; embed the repo's doc-sync convention verbatim (cite drift-contract file path if present, state absence explicitly if not — do not invent); embed the repo's merge strategy verbatim with detection logic (remote URL + `gh` on PATH + `gh pr view` exit code) |
     | `/groom` | Always-on `tidy` step sweeping master for `Closes-backlog:` / `Ships-backlog:` trailers via `scripts/lib/backlog.sh`, reconciling against active `backlog.d/` files; strategic-layer modes (brainstorm / ceo-review / technical bench / research / investigate) — trigger vocabulary and dispatch pattern universal, tailored content is the repo's prioritization scheme + cadence + tracker surfaces; canonical tracker set is `backlog.d/` plus GitHub issues when present — name both; no retired third-party trackers (any residual is a stale-source signal to scrub) |
     | `/settle` | Polish-loop framing (CI → code-review → refactor until merge-ready); `/settle` stops at merge-ready, does NOT merge — landing is `/ship`'s job; hand-off to `/ship` (not retired `/land`); only `backlog.d/` + GitHub issues as valid tracker references |
     | `/flywheel` | Composition `pick → /shape → /implement → /yeet → /settle → /ship → /monitor → loop`; `/ship` owns closure (archive + reflect + harness routing); `/flywheel` does NOT invoke `/reflect` directly and does NOT archive tickets itself; harness edits from `/reflect` route to `harness/reflect-outputs` via `/ship`, never master |
     | `/implement` | Branch-naming invariant `git checkout -b <type>/<id>-<slug>` where `<type>` ∈ `feat\|fix\|chore\|refactor\|docs\|test\|perf` and `<id>` is the bare numeric backlog ID; branch name IS the backlog claim (`/ship` reads ID via the regex above); no weakening to free-form branch names or repo-specific prefix schemes without a coordinated `/ship` change |

     **Rewriters may add sections, delete irrelevant structure,
     and restructure — the spellbook source is a reference, not
     a template to fill in.** Stack-native content (Elixir
     `:observer` + `:telemetry`, Rust `cargo miri`, Go `-race`,
     OTP supervision patterns) often has no slot in the JS/TS-
     shaped source. Add the section. Conversely, if the source
     has content that doesn't apply (matrix builds for a
     single-target repo, Playwright config for a CLI), delete it.
     Find-and-replace at the noun level produces B+ output; real
     tailoring restructures where the repo demands it.

     **Critic reviews all rewrites together, not individually.**
     Three checks: (1) **depth** — subtractive test, would this
     rewrite be wrong if applied to another repo with the same
     stack? If no, it's shallow — reject; (2) **cohesion** — does
     every gate-adjacent skill cite the same load-bearing gate
     from the repo brief? The critic must name at least one concrete
     contradiction check per gate-adjacent skill against the repo
     brief's gate statement or a sibling skill's statement. Any
     contradiction against repo brief or sibling skills → reject;
     (3) **completeness** — byte-identical to spellbook source →
     reject. Critic sends only the failing executors back with
     specific objections. Passed skills freeze. Only changed skills go
     back to executors. Re-enter the planner only when the critic has
     found a portfolio problem, missing scope, or cross-skill
     contradiction that the executor brief itself cannot resolve.
     Iterate until coherent. Up to 3 rounds; critic judges
     convergence.
   - **Domain skills (invented)** — greenfield additions like
     `/convex-migrate`, `/rust-unsafe-reviewer`. Only invent when you
     can name the concrete repo characteristic demanding it.

7. **Write `AGENTS.md`.** Project the repo brief + the coherent
   rewrite set into a router (not a manual). Suggested structure:
   - **Stack & boundaries** — stack names and what each layer owns.
   - **Ground-truth pointers** — files that ARE the API (e.g.
     `convex/_generated/api.d.ts`); stale training data lies.
   - **Invariants** — hard rules specific to this repo (functions,
     env vars, schema constraints, auth flows).
   - **Gate contract** — cite the load-bearing gate from the repo
     brief; enumerate pre-commit hooks, what humans do, what's
     enforced where.
   - **Known-debt map** — concrete file/line pointers. Every P0
     debt item gets a filed issue ID, not `(unfiled)`. If the repo
     brief surfaced a P0 with no tracker ID, file it (`gh issue
     create` or `backlog.d/NNN-*.md`) before writing this section.
     Debt-map entries like `INCIDENT-*.md` filenames are pointers,
     not IDs — attach a tracker ID.
   - **Harness index** — table: installed skill → what it does
     *here* (not the generic description). Agents in a sibling
     table, not a prose sentence.

8. **Write per-harness settings.** Each harness has its own
   settings format and path; emit one variant per harness:
   - `.claude/settings.local.json` (JSON, Claude Code)
   - `.codex/config.toml` (TOML, Codex)
   - `.pi/settings.json` (JSON, Pi)

   Permissions allowlist (and any other per-harness toggles)
   derive from the tools actually in use. Merge additively with
   any existing file — don't nuke user-added entries. Emit all
   three so the harness can be swapped without re-tailoring.

## Invariants

- Never write outside the current repo. No `$SPELLBOOK` mutation,
  no `~/.claude` / `~/.codex` / `~/.pi` mutation.
- **Workflow skills split into two tiers.** (Universal skills —
  `groom`, `office-hours`, `ceo-review`, `reflect` — are *also*
  always-present via step 6's universal category; they install
  verbatim, not tailored. Functionally always-present.)
  - **Always install** (orchestrators, foundational loop skills,
    and judgment-only skills): `deliver`, `shape`, `implement`,
    `code-review`, `ci`, `refactor`, `flywheel`, `settle`, `ship`,
    `yeet`, `diagnose`, `research`. **Never skipped, under any
    justification.** A repo without a CI pipeline *today* still gets
    `/ci` — the skill drives local gates and establishes the shipping
    contract. Spellbook is the source of `/flywheel`; any repo that
    articulates a `/deliver` → `/flywheel` loop must ship the
    orchestrator. `/ship` is the closure stage (archive, squash,
    reflect, harness routing); `/settle` leaves branches
    merge-ready and `/ship` lands them — the pair is indivisible.
    `/diagnose` is the merged investigate/audit/debug skill
    (reserved-name collisions retired `/investigate` and `/debug`);
    every repo has bugs to investigate. `/research` is always
    tailored, not copied — its tool preferences, domain sources, and
    prior-artifact pointers are repo-specific even though the
    protocol is universal. An exact-copy install is a valid tailoring
    outcome only for a repo that is itself the canonical source;
    silent skip is a regression.
  - **Infrastructure-tied, skip only with named absence.** `deploy`
    (no deploy target named in `vercel.json` / `fly.*.toml` /
    `Dockerfile*` / `.github/workflows/*deploy*`), `monitor` (no signal
    surfaces — Sentry, health endpoints, observability config),
    `qa` (no browser/E2E surface), `demo` (no demo scripts /
    evidence capture tooling). Skipping requires naming the concrete
    missing file; "didn't seem relevant" does not count. **Confusing
    an orchestrator's missing leaf step with the orchestrator itself
    is the trap:** no `/deploy` target does not justify skipping
    `/flywheel`; no `/qa` surface does not justify skipping
    `/code-review`.
- **Domain skills default to exclude.** Invent only when you can
  name the concrete repo characteristic demanding it. "We might want
  X" is not a name.
- **No `references/<repo-name>.md` sidecar files.** If a skill has
  repo-specific content, it belongs in the SKILL.md body. A sidecar
  named after the repo is the sewn-on-sleeve anti-pattern — the
  generic jacket with an appendix. Forbidden.

  *Permitted:* stack-specific references under their own topic
  (`references/elixir-observability.md`, `references/convex-
  patterns.md`, `references/otp-supervision.md`). These carry
  reusable content that's too deep for SKILL.md progressive
  disclosure — not a repo appendix. If the name could apply to
  another repo on the same stack, it's fine. If the name is this
  repo, rewrite it into SKILL.md.
- **Self-audit before declaring done.** Six checks:
  1. **Workflow rewrites:** `diff` each installed workflow SKILL.md
     against the spellbook source. Byte-identical = rewriter
     dropped the ball. Go back and redo.
  2. **Always-install coverage:** every skill in the always-install
     tier (`deliver`, `shape`, `implement`, `code-review`, `ci`,
     `refactor`, `flywheel`, `settle`, `ship`, `yeet`, `diagnose`,
     `research`) resolves to a directory under the shared skill
     root. Zero missing. If one is absent, the run failed —
     reinstall before declaring done.
  3. **Excluded workflows:** only skills from the infrastructure-tied
     tier may be skipped, and each skip names the concrete missing
     file (no `vercel.json`, no `fly.*.toml`, no `Dockerfile*`, no
     `.github/workflows/*deploy*`, no browser/E2E config — concrete
     absence, not "didn't seem relevant"). An always-install skill
     appearing in the skipped list is a critical regression.
  4. **Agent installation:** grep every installed skill for
     `subagent_type:` references. Every referenced agent must resolve
     to a file in the repo's installed agent directory (usually
     `.claude/agents/`). A `/code-review` that dispatches
     `ousterhout` + `carmack` + `grug` against nonexistent agent
     files is a silent regression — the skill fails at call time.
  5. **Shared scripts present:** `scripts/lib/backlog.sh` and
     `scripts/lib/verdicts.sh` exist at the repo root and match
     spellbook content. `/ship` and `/groom tidy` source
     `backlog.sh`; `/ship` and `/settle` source `verdicts.sh`. A
     missing or diverged library is a silent-sourcing failure at
     call time. Also grep installed skills for retired
     third-party tracker names — zero hits. Any residual reference
     to a retired tracker is a stale-rewrite regression; the
     canonical tracker set is `backlog.d/` plus GitHub issues.
  6. **AGENTS.md debt map:** zero `(unfiled)` entries. Every P0 has
     a filed tracker ID.

  Silent skip is the failure mode that ships B+ output when A is
  the bar.
- **Keep deterministic checks objective.** Self-audit is for
  presence/absence regressions, exact-copy detection, missing
  agents/scripts, and debt-map hygiene. Do not invent semantic
  scorecards, file-size thresholds, or "rewrite depth" heuristics.
  Planner → executor → critic owns semantic quality.
- Preserve self-containment. When you copy or rewrite a skill, its
  `references/` and `scripts/` stay with it.
- **Cross-harness install.** Spellbook-distributed skills live in a
  shared repo-local skill root (`.agent/skills/` or
  `.agents/skills/`). Harness-specific skill dirs such as
  `.claude/skills/` are symlink bridges back to that shared root,
  not duplicate copies. A repo installed Claude-only is harness-
  locked by construction. AGENTS.md at the repo root is already
  harness-neutral. Per-harness settings files (`.claude/settings.
  local.json`, `.codex/config.toml`, `.pi/settings.json`) are still
  emitted per-harness because their formats differ. Agents may stay
  in a harness-native agent directory until the repo has a documented
  shared-agent convention.
- **Non-destructive by default.** Never delete content in the shared
  skill root or any harness dir that lacks a `.spellbook` marker
  with `installed-by: tailor`. If reconciliation wants to remove
  something unmarked, ask the user first. Tailor owns `AGENTS.md`
  (overwrite is fine; pre-existing AGENTS.md without a prior
  tailor run should prompt confirmation) and
  `.spellbook/repo-brief.md` (always overwrite).
- **Settings merge, not overwrite.** When writing any harness
  settings file, merge with the existing file additively —
  user-added permissions entries survive. Only the entries this
  run derived from actual tool usage are your contribution.

## What "tailored" means

At the SKILL.md level: every example is a repo-specific example.
Every command names the actual command the user runs here. Every
gotcha points to a real file in this repo. The skill reads like it
was written *for this codebase* — because it was.

**Bad** (generic + appended notes):

```
## Inner loop
Run your project's test command.

## Repo notes (this-repo)
Tests are run via `pnpm test --run <path>`.
```

**Good** (rewritten):

```
## Inner loop
Run `pnpm test --run <path>` (happy-dom, fast). For pre-push, use
`pnpm ci:prepush` — the Dagger pipeline runs Vitest + Playwright
+ gitleaks, same contract as the hosted CI gate.
```

The generic jacket + notes is fast. It's also wrong — the agent
reading the generic body first then reconciling with an appendix
runs a parallax failure. Write the skill for this repo in the first
place.

## References

- `references/focus-postmortem.md` — critic's rejection checklist.

See also: `/seed` for the dumb-copy variant when you want something
working fast and will curate by hand later.
