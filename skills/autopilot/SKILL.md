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

You are the orchestrator. Dispatch to sub-agents, synthesize their output,
make proceed/fix/escalate decisions. Never delegate the ship/don't-ship call.

## Workflow

### 1. Pick work

Read `backlog.d/` for highest-priority ready item, or accept explicit argument.

### 2. Shape

Spawn a **planner** sub-agent. Give it the backlog item and ask it to produce
a context packet: goal, non-goals, constraints, repo anchors, oracle,
implementation sequence. The planner reads the codebase and researches
prior art — you review and approve the spec before building.

If the item already has a complete context packet (goal + oracle + sequence), skip.

### 3. Build

Spawn **builder** sub-agent(s) with the approved context packet.

For single-chunk work, spawn one builder with the full spec.

For parallelizable work, spawn multiple builders simultaneously — each in its
own worktree, each with disjoint file ownership and a subset of the oracle
criteria. Tell each builder exactly which files it owns and which criteria
it's responsible for. TDD: RED → GREEN → REFACTOR → COMMIT.

### 4. Review

Invoke `/code-review`. This spawns the full reviewer bench in parallel
(critic + ousterhout + carmack + grug + beck). If blocking issues are found,
spawn a builder sub-agent to fix each concern, then re-review. Loop max 3.

### 5. Ship

Once review passes:
- Squash or create semantic commits
- Open PR if collaborating (context packet in body)
- Or commit directly if solo project
- Run quality gates (lint, typecheck, test) before push

### 6. Retro (optional)

If the build surfaced learnings, invoke `/reflect`.

## What you keep vs what you delegate

| You (orchestrator) | Sub-agents |
|--------------------|------------|
| Work selection, priority | Codebase research (planner) |
| Spec approval, scope decisions | Implementation chunks (builder) |
| Review synthesis, ship/don't-ship | Code review (critic + bench) |
| Conflict resolution between agents | Test writing and repair (builder) |
| Final commit and push | Mechanical refactors (builder) |

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
