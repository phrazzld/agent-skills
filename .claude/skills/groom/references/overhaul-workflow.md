# Backlog Overhaul Workflow

## Inputs

- current product focus or `project.md`
- open issues, labels, milestones, and project views
- recent user pain, bugs, or usage evidence
- implementation retros or failed attempts

## Phase 1: Audit

Collect:
- open issue count
- issue distribution by priority, type, horizon, and domain
- duplicates and near-duplicates
- missing milestones or weak labels
- oversized issues
- stale now/next items

## Phase 2: Theme

Group issues by product intent, not by title wording.
Ask:
- what are the real user-facing problems?
- which issues are foundations vs leaf polish?
- where is the roadmap fragmented across many shallow tickets?

## Phase 3: Reduce

Default moves:
- merge duplicates into a canonical issue
- close superseded items
- move nit-level concerns under a deeper issue
- split only when a child issue can execute independently

## Phase 4: Rewrite

For each surviving issue:
- tighten title
- clarify problem and desired outcome
- add direct context and likely touchpoints
- rewrite acceptance criteria in observable form
- add verification and boundaries
- align labels, milestone, and dependencies

## Phase 5: Rebuild hierarchy

Create or update:
- epics for multi-issue outcomes
- sub-issues for independent execution slices
- dependencies for sequencing

Do not use an epic when one good issue will do.

## Phase 6: Publish

After edits:
- post a short note when closing or superseding an issue
- link the canonical replacement
- keep the roadmap legible from the issue list view alone

## Heuristics

- one issue should usually map to one coherent PR
- prefer fewer better issues over more weaker issues
- active horizon should stay intentionally small
- “later” should be curated, not a graveyard

## Deliverable

A successful overhaul leaves:
- a readable roadmap
- minimal duplication
- explicit sequencing
- agent-executable issue bodies
- a smaller active set than before
