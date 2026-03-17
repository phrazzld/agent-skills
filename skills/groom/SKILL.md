---
name: groom
description: |
  Interactive backlog grooming, backlog doctrine, and automated cleanup.
  Explore, brainstorm, research, synthesize into prioritized GitHub issues.
  Backlog strategy, ordering, pruning, agent-ready issue writing, overhaul.
  Use when: backlog session, issue grooming, sprint planning, backlog cleanup,
  backlog overhaul, rewriting tickets, reducing issue sprawl, agent-executable issues.
  Trigger: /groom, /backlog, /tidy, "groom the backlog", "clean up issues",
  "overhaul the backlog", "rewrite tickets", "agent-ready issues".
disable-model-invocation: true
---

# /groom

Orchestrate backlog management. Explore the product landscape with the user,
research best practices, validate with multi-model consensus, then synthesize
into a small, prioritized, agent-executable roadmap.

## Absorbed Skills

- `agent-backlog` — backlog doctrine, GitHub issue mechanics, agent-ready issue writing, overhaul workflow

## Philosophy

**Exploration before synthesis.** Understand deeply, discuss with user, THEN create issues.

**Research-first.** Every theme gets web research, cross-repo investigation, and codebase
deep-dive before scoping decisions are made.

**Multi-model validation.** Strategic directions pass through `/research thinktank` before locking.

**Quality gate on output.** Every created issue must score >= 70 on `/issue lint`.

**Write-through by default.** If grooming produces a clear backlog delta, apply it in GitHub
in the same turn. Do not stop at recommendations unless the user explicitly asks for draft-only output.

**Orchestrator pattern.** /groom invokes skills and agents, doesn't reimplement logic.

**Opinionated recommendations.** Don't just present options. Recommend and justify.

**Intent-first backlog.** Every issue must carry a clear Intent Contract that downstream
build/PR workflows can reference.

**Backlog is strategy, not storage.** GitHub issues are the active plan — 20-30 max,
every one groomed to score >= 70, every one execution-ready or clearly blocked.
Ideas beyond the active window live in `.groom/BACKLOG.md`.

**Two-tier system.** GitHub = commitments. `.groom/BACKLOG.md` = ideas, someday/maybes,
deferred themes, research prompts. Groom sessions read BACKLOG.md for promotion
candidates and write back demoted ideas. See `references/backlog-doctrine.md`.

**100% groomed or it doesn't belong.** If an issue can't pass `/issue lint` >= 70,
it's either not ready (fix it) or not real (move to BACKLOG.md or close).

**Slash before adding.** When the backlog exceeds 30 open issues, default to
merge/close/demote-to-BACKLOG.md until it's back under the cap.

**One roadmap, not many.** The backlog should read like the project's current plan,
not an archive of every bug, nit, brainstorm, review comment, or screenshot.

**Code is a liability.** Every line fights for its life. Prefer deletion over addition.

**Never afraid to break compatibility** for a more elegant design.

**Never afraid of esoteric technology** if it's the best fit.

**Never afraid to throw away code** that's too much complexity for too little value.

**Architecture before issues.** Don't create issues that deepen a broken architecture.

**Reference architecture first.** Always search for existing implementations before designing from scratch.

**Platform-native first.** Before keeping any integration issue, verify the target platform doesn't already offer the capability natively.

**Model diversity for architecture.** Use thinktank + CLI agents for diverse perspectives on design decisions.

## Org-Wide Standards

All issues MUST comply with `groom/references/org-standards.md`.
Load that file before creating any issues.

## Workflow

Run `/groom` in six phases:

1. **Ground** — load or update `project.md`, load `.groom/BACKLOG.md`, check repo context freshness, run `sync.sh detect .` to ensure relevant domain packs are loaded, read retro, capture user pain, audit backlog health (enforce 20-30 cap), compute health metrics
2. **Architecture Critique** — four parallel tracks:
   - **A. Reference search** — `/research web-search` for existing implementations
   - **B. Domain skills** — invoke relevant domain skills for current-state audit
   - **C. Thinktank** — `/research thinktank` on the architecture question in deep mode.
     Feed it: current architecture, pain points, project vision, constraints.
     This is mandatory, not optional — multi-model consensus catches blind spots.
   - **D. Triad review** — spawn `ousterhout`, `carmack`, `grug` agents in parallel
     on the current architecture. Each answers: "What's the single biggest
     structural problem? What would you change first?"

   For greenfield modules, load `references/toolchain-preferences.md` before
   evaluating technology options. See `references/architecture-fitness.md`.

2.5. **Present Options** — synthesize tracks A-D into 2-3 architectural options
   (incremental to radical), including triad and thinktank findings.
   Ask user what range of change is acceptable.
3. **Research** — web, cross-repo, and codebase research, scoped to the direction chosen in 2.5. Use `/research web-search` with Exa for reference architecture discovery.
4. **Exploration** — pitch options, recommend one, discuss. Lock direction.
5. **Synthesis** — reduce GitHub backlog to cap (demote to BACKLOG.md, close, merge), then promote from BACKLOG.md or create for missing gaps. Every surviving issue must score >= 70.
6. **Artifact** — save a dated grooming plan, update `.groom/BACKLOG.md`, visual summary when useful

Synthesis default:
- issue edits, issue creation, issue closure, and label/milestone cleanup are part of the normal `/groom` deliverable
- if an audit or discussion yields actionable backlog changes, execute those GitHub writes without waiting for a follow-up ask
- fetch back written issues and verify labels, milestones, and body formatting after each write
- use `github-cli-hygiene` for all GitHub body writes

## References

### Workflow
- `references/interactive-workflow.md` — full Phase 1-4 flow (includes architecture critique phases)
- `references/architecture-fitness.md` — health metrics, domain skill routing, reference search prompts, thinktank templates
- `references/synthesis-workflow.md` — backlog reduction, issue creation, summaries, plan artifact, visual output

### Standards
- `references/org-standards.md` — required issue format, labels, milestones, readiness scoring
- `references/project-md-format.md` — `project.md` format
- `references/project-baseline.md` — baseline project standards

### Technology
- `references/toolchain-preferences.md` — default tech stack, toolchain decisions, Elixir/OTP routing

### Backlog Doctrine (absorbed from agent-backlog)
- `references/backlog-doctrine.md` — two-tier system (GitHub active + BACKLOG.md icebox), ordering, cap enforcement, cadence, smells
- `references/github-issues.md` — platform primitives, hierarchy, intake, planning
- `references/agent-issue-writing.md` — writing agent-executable issue bodies, type-specific guidance
- `references/overhaul-workflow.md` — full backlog rebuild: audit, theme, reduce, rewrite, hierarchy

### Modes
- `references/backlog-health.md` — health dashboard procedure
- `references/tidy-procedure.md` — automated cleanup procedure

Default stance:
- explore before scoping
- reduce before adding (demote to BACKLOG.md, don't just close)
- keep one canonical issue where several shallow issues would otherwise survive
- promote from BACKLOG.md before inventing new issues
- create new issues only for genuine roadmap gaps
- end every session with GitHub backlog at 20-30 issues, 100% groomed

## Modes

### Interactive (default)
Full grooming session with exploration, research, and synthesis. Phases 1-6 above.

### Health Dashboard (`/groom --health`)
Quick read-only backlog assessment. Runs Phase 1 Step 5 only.
See `references/backlog-health.md`.

### Tidy (`/groom --tidy`)
Non-interactive automated cleanup. Lints, enriches, deduplicates, closes stale, migrates labels.
See `references/tidy-procedure.md`.

### Overhaul (`/groom --overhaul`)
Full backlog rebuild: audit, theme, reduce, rewrite, hierarchy, publish.
Non-interactive end-to-end restructuring when the backlog has drifted beyond tidy's reach.
See `references/overhaul-workflow.md`.

## Routing (from backlog doctrine)

When invoked for specific backlog concerns outside a full groom session:

- General backlog strategy, ordering, pruning, refinement:
  Read `references/backlog-doctrine.md`
- GitHub Issues, labels, milestones, sub-issues, dependencies, Projects:
  Read `references/github-issues.md`
- Writing or rewriting agent-ready issue bodies, acceptance criteria, boundaries:
  Read `references/agent-issue-writing.md`

## Related Skills

### Plumbing (Phase 2 + 5)
- `/audit [domain|--all]` — Unified domain auditor
- `/issue lint` — Score issues against org-standards
- `/issue enrich` — Fill gaps with sub-agent research
- `/issue decompose` — Split oversized issues
- `/retro` — Implementation feedback capture

### Planning & Design
| I want to... | Skill |
|--------------|-------|
| Full planning for one idea | `/shape` |
| Multi-model validation | `/research thinktank` |

### Standalone Domain Work
```bash
/audit quality        # Audit only
/audit quality --fix  # Audit + fix
/triage              # Fix highest priority production issue
```
