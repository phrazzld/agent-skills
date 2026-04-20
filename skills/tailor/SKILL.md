---
name: tailor
description: |
  Tailor this repository's harness. Explore the repo, read prior
  session history, browse the spellbook catalog, and install a
  per-repo set of skills and agents in .claude/. Workflow skills get
  rewritten with this repo's commands and conventions embedded
  throughout — not a generic body with a repo-notes appendix.
  Use when: "tailor this repo", "configure the agent for this codebase",
  "set up a harness", "what skills apply here". Trigger: /tailor.
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

   **Also inventory any existing harness.** If `.claude/skills/` or
   `.claude/agents/` already has content, classify each entry:
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

   **Planner must also propose ≥1 candidate domain invention per
   round**, with the concrete repo characteristic that would justify
   it (e.g., "`/convex-migrate` — this repo has live-traffic Convex
   schema evolution with `v.optional` upgrade paths in
   `convex/schema.ts`"). The critic evaluates via criterion 4. Landing
   on "none justified" is a valid outcome — the point is to force the
   thinking, not the output. Repos with load-bearing domain needs
   shouldn't slip through because the picker never considered them.

   One round. Stop on critic-clear.

6. **Install.** First reconcile, then write.

   **Reconcile.** For each tailor-owned item inventoried in step 1
   (has `.spellbook` marker with `installed-by: tailor`):
   - Still in the new pick → replace with fresh rewrite.
   - Not in the new pick → remove the skill/agent directory. This
     is how `/tailor` self-heals canary-class fossils where the
     prior pick no longer matches the repo's current needs.

   For items without a `.spellbook` marker (unknown origin): do not
   touch without user confirmation. If a skill you're about to
   install collides with an unmarked existing skill of the same
   name, surface the conflict: "existing `.claude/skills/qa/` has
   no tailor marker — is it scaffolded, human-authored, or prior-
   era /tailor output? [preserve / replace / diff]".

   **Write `.spellbook` markers.** Every skill and agent installed
   or updated by this run gets a marker file at
   `<skill-or-agent>/.spellbook` with:

   ```yaml
   source: <primitive-name>
   installed: <ISO-8601 timestamp>
   installed-by: tailor
   tailor-version: <git commit SHA of spellbook/skills/tailor>
   category: universal | workflow | domain-invented
   ```

   Markers are how re-runs tell your output apart from human-
   authored content.

   Three categories, different install rules:

   - **Universal skills** — `research`, `groom`, `office-hours`,
     `ceo-review`, `reflect`, and similar that carry no repo-specific
     judgment. Copy their directories verbatim. Tailoring them would
     be artificial.
   - **Workflow skills** — `deliver`, `shape`, `implement`,
     `code-review`, `ci`, `refactor`, `qa`, `flywheel`, `deploy`,
     `monitor`, `diagnose`, `settle`, `yeet`. **Rewrite each SKILL.md
     with this repo's commands, gates, conventions, and file paths
     embedded throughout.** Use the spellbook version as structural
     reference; fill every example, every command, every gotcha with
     repo-specific content. Preserve `references/` and `scripts/`
     from the source — they travel with the skill.

     **Dispatch one rewriter subagent per workflow skill, in
     parallel.** Monolithic rewriting of 10+ skills in one context
     causes attention decay — the model pattern-matches "just copy
     this one too" and ships byte-identical output. Each rewriter
     receives: (a) the repo brief from step 4 (shared spine —
     cite these anchors, don't invent parallel vocabulary),
     (b) the spellbook source, (c) a domain-specific reading
     assignment (`/ci` reads `.github/workflows/` + dagger config;
     `/diagnose` reads evidence logs + postmortems; `/deliver`
     reads `backlog.d/` + recent merged PRs), (d) the mandate
     above.

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
     from the repo brief? Any contradiction against repo brief or
     sibling skills → reject; (3) **completeness** — byte-identical
     to spellbook source → reject. Critic sends specific rewriters
     back with specific objections. Iterate until coherent. Up to
     3 rounds; critic judges convergence.
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
     create` or `git-bug bug new` or `backlog.d/NNN-*.md`) before
     writing this section. Debt-map entries like `INCIDENT-*.md`
     filenames are pointers, not IDs — attach a tracker ID.
   - **Harness index** — table: installed skill → what it does
     *here* (not the generic description). Agents in a sibling
     table, not a prose sentence.

8. **Write `.claude/settings.local.json`.** Permissions allowlist
   derived from the tools actually in use.

## Invariants

- Never write outside the current repo. No `$SPELLBOOK` mutation,
  no `~/.claude` / `~/.codex` / `~/.pi` mutation.
- **Workflow skills default to include.** Only exclude if the repo
  genuinely lacks the infrastructure the skill operates on (no CI
  config → skip `/ci`; no deploy target → skip `/deploy`; no active
  backlog → skip `/groom`). A repo with real CI, tests, deploy, and
  backlog needs most of the workflow set — that's the inner/outer
  loop of shipping.
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
- **Self-audit before declaring done.** Four checks:
  1. **Workflow rewrites:** `diff` each installed workflow SKILL.md
     against the spellbook source. Byte-identical = rewriter
     dropped the ball. Go back and redo.
  2. **Excluded workflows:** name the concrete missing infrastructure
     for each skipped skill (no `vercel.json`, no `fly.*.toml`, no
     `convex/`, no `Dockerfile`, no `.github/workflows/*deploy*` —
     concrete absence, not "didn't seem relevant").
  3. **Agent installation:** grep every installed skill for
     `subagent_type:` references. Every referenced agent must resolve
     to a file in `.claude/agents/`. A `/code-review` that dispatches
     `ousterhout` + `carmack` + `grug` against nonexistent agent
     files is a silent regression — the skill fails at call time.
  4. **AGENTS.md debt map:** zero `(unfiled)` entries. Every P0 has
     a filed tracker ID.

  Silent skip is the failure mode that ships B+ output when A is
  the bar.
- Preserve self-containment. When you copy or rewrite a skill, its
  `references/` and `scripts/` stay with it.
- **Non-destructive by default.** Never delete `.claude/` content
  that lacks a `.spellbook` marker with `installed-by: tailor`. If
  reconciliation wants to remove something unmarked, ask the user
  first. Tailor owns `AGENTS.md` (overwrite is fine; pre-existing
  AGENTS.md without a prior tailor run should prompt confirmation)
  and `.spellbook/repo-brief.md` (always overwrite).
- **Settings merge, not overwrite.** When writing
  `.claude/settings.local.json`, merge with the existing file
  additively — user-added permissions entries survive. Only the
  entries this run derived from actual tool usage are your
  contribution.

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
