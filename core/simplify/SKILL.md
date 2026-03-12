---
name: simplify
description: |
  Find and ship the highest-leverage simplification a codebase can absorb in one pull request.
  Use when simplifying architecture, deleting layers, reviewing a repo from first principles,
  asking "what would we build today?", or looking for the cleanest Ousterhout-style refactor.
  Keywords: /simplify, simplify this repo, first-principles redesign, strategic refactor,
  module depth, information hiding, reduce complexity, clean architecture, single-PR refactor.
disable-model-invocation: true
argument-hint: "[optional focus area]"
---

# /simplify

Take one concrete step toward the system you would design today, not the system history handed you.

## Role

Staff engineer and architecture editor. Understand why the system exists, imagine the clean rebuild,
then ship the single best simplification that fits in one PR.

## Objective

For the whole repo or `$ARGUMENTS`, answer four questions with evidence:

1. What does this system actually do?
2. Why is it shaped this way?
3. If rebuilding today, what are the cleanest plausible designs?
4. Which one refactor removes the most complexity per unit of risk right now?

Then implement that refactor, verify behavior, and open or update a draft PR via `../pr/SKILL.md`.
Local code changes plus a summary are not a completed `/simplify` run.

## Latitude

- Launch parallel subagents when the harness supports them; otherwise run the same lanes sequentially
- Read code, docs, tests, ADRs, and bounded git history before proposing changes
- Prefer deletion, consolidation, and stronger module boundaries over new abstractions
- Use an `ousterhout` reviewer/persona if available; otherwise apply the same checks manually
- Treat the PR lane as part of the task, not optional follow-up work
- If `../pr/SKILL.md` blocks on missing evidence, duplicate PRs, auth, or another concrete prerequisite, resolve it when feasible; otherwise report that explicit blocker instead of silently stopping short of the PR step
- If no safe, high-impact, single-PR simplification exists, say so explicitly instead of inventing churn

## Workflow

1. **Establish current truth** — Read the nearest `AGENTS.md`, `CLAUDE.md`, `README`, architecture docs, and the critical runtime/test modules. Inspect recent git history, big refactors, and ADRs to learn how the current shape emerged.
2. **Split exploration into lanes** — Read `references/exploration-lanes.md`. Run only the minimum lanes needed to decide one safe, high-leverage simplification. Skip any lane that cannot change the decision.
3. **Rebuild from first principles** — Generate several credible "build it today" designs, not just one. Force structural alternatives: deeper modules, fewer services, collapsed workflows, deleted compatibility layers, or cleaner seams.
4. **Evaluate trade-offs** — Read `references/refactor-rubric.md`. Score the options on module depth, information hiding, operational simplicity, migration cost, behavior risk, and single-PR feasibility.
5. **Choose one refactor** — Pick the change that maximizes complexity removed per unit of risk and fits in one pull request. Name what will be deleted, what will be consolidated, and what behavior must remain unchanged.
6. **Implement with proof** — Before edits, write down the module invariants and external contract that must remain stable. Add or adjust tests against that contract where behavior risk is non-trivial. Make the refactor. Update docs if architecture or workflow meaningfully changes. Verify with the tightest commands that cover the affected surface.
7. **Ship** — After boundary simplification and verification are complete, invoke `../pr/SKILL.md` and follow its workflow all the way through opening or updating the PR. Do not stop after local verification or a narrative summary. The PR should explain the current shape, the first-principles alternatives considered, why this refactor won, and the follow-up work left behind.
8. **Codify leftovers** — If the best future architecture cannot fit in one PR, create focused follow-up issues or record the roadmap in the PR body.

## Output

Default deliverable:

- Current system model
- First-principles design options
- Trade-off evaluation
- Chosen single-PR simplification
- Verification evidence
- PR URL, or the explicit blocker returned by `../pr/SKILL.md`

## References

- `references/exploration-lanes.md`
- `references/refactor-rubric.md`
