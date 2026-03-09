---
name: groom
description: |
  Interactive backlog grooming with health dashboard and automated cleanup.
  Explore, brainstorm, discuss, synthesize into prioritized GitHub issues.
  Use when: backlog session, issue grooming, sprint planning, backlog cleanup.
  Trigger: /groom, /backlog, /tidy, "groom the backlog", "clean up issues".
disable-model-invocation: true
---

# /groom

Orchestrate interactive backlog grooming. Explore the product landscape with the user,
research current best practices, validate with multi-model consensus, then synthesize
into prioritized, agent-executable issues.

## Philosophy

**Exploration before synthesis.** Understand deeply, discuss with user, THEN create issues.

**Research-first.** Every theme gets web research, cross-repo investigation, and codebase
deep-dive before scoping decisions are made.

**Multi-model validation.** Strategic directions pass through `/thinktank` before locking.

**Quality gate on output.** Every created issue must score >= 70 on `/issue lint`.

**Orchestrator pattern.** /groom invokes skills and agents, doesn't reimplement logic.

**Opinionated recommendations.** Don't just present options. Recommend and justify.

**Intent-first backlog.** Every issue must carry a clear Intent Contract that downstream
build/PR workflows can reference.

**Backlog is strategy, not storage.** Keep the backlog small, current, and legible.
Rough target: a couple dozen active issues, not 100+.

**Slash before adding.** When the backlog sprawls, default to merge/close/defer/rewrite
until the remaining set reflects the highest-priority themes.

**One roadmap, not many.** The backlog should read like the project's current plan,
not an archive of every bug, nit, brainstorm, review comment, or screenshot.

**Use judgment, not quotas.** The point is coherence and execution bandwidth, not
hitting an exact issue count.

## Org-Wide Standards

All issues MUST comply with `groom/references/org-standards.md`.
Load that file before creating any issues.

## Workflow

Run `/groom` in six phases:

1. **Context** — load or update `project.md`, check repo context freshness, read retro, capture user pain, audit backlog health
2. **Discovery** — launch parallel lanes and synthesize 3-5 strategic themes
3. **Research** — do web, cross-repo, and codebase research before scoping
4. **Exploration** — pitch options, recommend one, discuss, validate, then lock direction
5. **Synthesis** — reduce the backlog first, then create only missing strategic issues
6. **Artifact** — save a dated grooming plan and visual summary when useful

Use these references:
- `references/interactive-workflow.md` — full Phase 1-4 flow
- `references/synthesis-workflow.md` — backlog reduction, issue creation, summaries, plan artifact, visual output
- `references/org-standards.md` — required issue format, labels, milestones, readiness scoring
- `references/project-md-format.md` — `project.md` format
- `references/project-baseline.md` — baseline project standards

Default stance:
- explore before scoping
- reduce before adding
- keep one canonical issue where several shallow issues would otherwise survive
- create new issues only for genuine roadmap gaps

## Modes

### Interactive (default)
Full grooming session with exploration, research, and synthesis. Phases 1-6 above.

### Health Dashboard (`/groom --health`)
Quick read-only backlog assessment. Runs Phase 1 Step 5 only.
See `references/backlog-health.md` for the full dashboard procedure.

### Tidy (`/groom --tidy`)
Non-interactive automated cleanup. Lints, enriches, deduplicates, closes stale, migrates labels.
See `references/tidy-procedure.md` for the full procedure.

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
| Multi-model validation | `/thinktank` |

### Standalone Domain Work
```bash
/audit quality        # Audit only
/audit quality --fix  # Audit + fix
/triage              # Fix highest priority production issue
```

Visual output guidance lives in `references/synthesis-workflow.md`.
