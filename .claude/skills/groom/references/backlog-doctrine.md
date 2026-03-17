# Backlog Doctrine

## Two-Tier Backlog

GitHub issues are the **active plan** — the work you're committing to execute.
`.groom/BACKLOG.md` is the **idea icebox** — everything else worth remembering.

| Tier | Location | Cap | Grooming Standard |
|------|----------|-----|-------------------|
| Active | GitHub Issues | 20-30 | 100% score >= 70, all labeled, all execution-ready |
| Icebox | `.groom/BACKLOG.md` | Unlimited | Categorized, dated, pruned each groom session |

Ideas flow between tiers during `/groom` sessions:
- **Promote:** BACKLOG.md → GitHub issue (idea becomes priority)
- **Demote:** GitHub issue → BACKLOG.md (issue loses priority, close with link)
- **Archive:** BACKLOG.md → strikethrough (idea is done, obsolete, or absorbed)
- **Discard:** either tier → gone (idea has no remaining value)

## What the active backlog is for

The GitHub backlog is the current plan, not storage for every idea. A good backlog
is ordered, transparent, and actively maintained. It should make the next decisions obvious.

## Core rules

- **Hard cap: 20-30 open issues.** Over cap triggers reduction, not addition.
- **100% groomed.** Every issue scores >= 70 on `/issue lint` or gets fixed/demoted.
- Reduce before adding.
- Prefer one canonical issue per outcome.
- Split discovery from delivery.
- Order work by user value, risk reduction, learning, and enablement.
- Keep active work narrow. High WIP destroys prioritization.
- Ideas that aren't execution-ready live in `.groom/BACKLOG.md`, not GitHub.

## Healthy item shapes

### Epic

Use for a multi-issue initiative with a clear product outcome. The epic should explain why the
theme matters, what success looks like, and which child issues carry execution.

### Feature

Use for a user-visible capability or operator-facing behavior change. The feature should be
valuable on its own and not just a mechanical subtask.

### Bug

Use when the current behavior is wrong. State the failure, repro, expected behavior, and user or
business impact.

### Task / Refactor / Research

Use only when the work is not a feature or bug. Keep these issue types outcome-linked:
- `task`: enabling work with a clear downstream payoff
- `refactor`: complexity reduction with preserved behavior
- `research`: a decision-seeking investigation with a deliverable

## Ordering guidance

Move items up when they:
- unblock or de-risk other work
- fix trust, correctness, or safety failures
- improve a critical user path
- create leverage across multiple future issues

Move items down when they:
- are polish without evidence
- duplicate a broader surviving issue
- depend on undefined architecture
- represent “maybe someday” ideas with no current owner

## Cadence

- Triage new intake quickly into keep, merge, demote, or close.
- Re-read the active backlog regularly enough to remove stale assumptions.
- Run pruning passes, not just addition passes.
- Update the canonical issue body when the plan changes. Do not bury the truth in comments.
- Review `.groom/BACKLOG.md` every groom session — promote, archive, or leave.

## Smells

- 5 tickets that all mean the same thing
- “Polish” issues that should be sub-points in a deeper issue
- implementation tasks with no user or system outcome
- giant omnibus tickets with unclear done criteria
- issues that require tribal knowledge to start
- “investigate” tickets with no decision target
- >30 open issues (backlog is storage, not strategy)
- issues scoring < 70 sitting open for weeks (ungroomed noise)
- BACKLOG.md not updated in 3+ groom sessions (icebox is rotting)

## Definition of ready

Before an issue is execution-ready, verify:
- the problem is specific
- the outcome is explicit
- dependencies are visible
- scope boundaries are present
- verification is executable
- the issue can be completed in one coherent pass or should be split

## AI-agent adaptation

See `agent-issue-writing.md` for agent-specific issue shaping.

## Sources

- https://scrumguides.org/scrum-guide
- https://www.atlassian.com/agile/project-management/backlog-refinement-meeting
- https://www.atlassian.com/agile/project-management/product-backlog
