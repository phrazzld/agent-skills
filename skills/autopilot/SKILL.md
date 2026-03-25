---
name: autopilot
description: |
  Full delivery pipeline: plan→build→review→ship.
  Reads highest-priority backlog item, shapes it, builds it via TDD,
  runs parallel code review, iterates until clean, ships.
  Use when: shipping features, building issues, "autopilot", "build this",
  "ship this", "implement", "full pipeline".
  Trigger: /autopilot, /build, /ship.
argument-hint: "[backlog-item|issue-id]"
---

# /autopilot

Full delivery pipeline. From backlog item to shipped code in one command.

## Architecture: Planner → Builder → Critic

Autopilot orchestrates three sub-agent archetypes:

1. **Planner** — decomposes work, writes specs via `/shape`
2. **Builder** — implements via TDD, commits atomically
3. **Critic** — evaluates output via `/code-review`, fails or approves

You (the top-level agent) are the orchestrator. You dispatch to sub-agents,
synthesize their output, and make proceed/fix/escalate decisions.

## Workflow

1. **Pick work** — Read `backlog.d/` for highest-priority ready item.
   Or accept explicit argument (issue ID, backlog file, raw description).

2. **Shape** — Launch planner sub-agent to run `/shape` on the item.
   Output: context packet with goal, non-goals, constraints, oracle,
   implementation sequence. If the item is already well-specced, skip.

3. **Build (TDD)** — Launch builder sub-agent(s) with the spec.
   - RED: write failing tests from oracle criteria
   - GREEN: implement until tests pass
   - REFACTOR: simplify
   - Commit atomically after each logical chunk
   - If work is parallelizable, launch multiple builders with disjoint file ownership

4. **Review** — Trigger `/code-review` on the built code.
   Launches parallel reviewer team (critic + philosophy agents).
   If blocking issues found → dispatch builder to fix → re-review.
   Loop until clean.

5. **Ship** — Once review passes:
   - Squash or create semantic commits
   - Open PR if collaborating (include context packet in body)
   - Or commit directly to main if solo project
   - Run quality gates (lint, typecheck, test) before push

6. **Retro** (optional) — If the build surfaced learnings, run `/reflect`.

## Executive / Worker Split

Keep the strongest model on orchestration:
- Work selection and scope decisions
- Spec approval and tradeoff calls
- Review synthesis and ship/don't-ship judgment

Delegate to workers:
- Implementation chunks with disjoint file ownership
- Test writing and repair
- Mechanical refactors and cleanup

## Quality Gates

- All tests pass before shipping
- All lints pass
- Code review clean (no blocking issues)
- Oracle criteria from context packet verified
- Never force push. Never push to main without confirmation.

## Night-Shift Mode

When invoked with `--overnight` or for autonomous multi-hour sessions:
- Require a complete context packet (oracle is non-negotiable)
- Decompose into sprints, each independently verifiable
- Write handoff artifacts between sprints (what's done, what's next)
- Context resets between sprints if context window is filling
- Full QA pass at end before shipping

## Gotchas

- **Skipping shape:** Building without a context packet produces plausible garbage. If the item lacks an oracle, run /shape first. Always.
- **Builder scope creep:** Builders add features not in the spec. The spec is the constraint — raise blockers, don't silently expand.
- **Review theater:** Running /code-review on your own unchanged code. Review the delta, not the whole file.
- **Overnight without oracle:** Night-shift mode without verifiable criteria = autonomous slop production. Oracle is non-negotiable.
- **Parallelizing coupled work:** Multiple builders on files that import each other. Parallelize only when file ownership is disjoint.
- **Force-pushing:** Never. No exceptions. Create new commits.
- **Shipping with red tests:** "They were red before" is not an excuse. Fix what you touch.

## Stopping Conditions

Stop only if: build fails after multiple attempts, requires external action,
or oracle criteria are unverifiable.

NOT stopping conditions: item seems big, approach unclear, missing description.
YOU make items ready — planner shapes, builder implements.
