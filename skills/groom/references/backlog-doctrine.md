# Backlog Doctrine

## Three-Tier Backlog

| Tier | Location | Purpose | Cap |
|------|----------|---------|-----|
| **Shaped work** | `backlog.d/` | Ready-to-build items with goal + oracle + sequence | 10-15 |
| **Raw issues** | git-bug (`git-bug bug`) | Bugs, findings, requests — not yet shaped | 20-30 |
| **Icebox** | `.groom/BACKLOG.md` | Everything else worth remembering | Unlimited |

GitHub Issues is an **optional sync target** (currently empty across all repos).
`git-bug push origin` creates issues there for human visibility when desired.
Agents read/write issues via git-bug CLI; `backlog.d/` is the canonical backlog.

If `git-bug` is not installed, fall back to `backlog.d/` files as the active issue tier.

Ideas flow between tiers during `/groom` sessions:
- **Shape:** git-bug issue → `backlog.d/` file (issue gets goal + oracle → ready to build)
- **File:** finding → git-bug issue (raw bug or idea gets tracked)
- **Promote:** BACKLOG.md → git-bug issue (idea becomes active)
- **Demote:** git-bug issue → BACKLOG.md (issue loses priority, close with link)
- **Archive:** BACKLOG.md → strikethrough (idea is done, obsolete, or absorbed)
- **Discard:** any tier → gone (no remaining value)

## What the active backlog is for

The active backlog (`backlog.d/` + git-bug) is the current plan, not storage for every idea.
A good backlog is ordered, transparent, and actively maintained. It should make the next
decisions obvious.

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
