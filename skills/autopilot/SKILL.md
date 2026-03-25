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

You are the orchestrator. You dispatch to sub-agents, synthesize their
output, and make proceed/fix/escalate decisions. Never delegate the
ship/don't-ship call.

## Workflow

### 1. Pick work

Read `backlog.d/` for highest-priority ready item, or accept explicit argument.

### 2. Shape (planner sub-agent)

Spawn a **planner** sub-agent to run `/shape`:

```
Agent(subagent_type: "planner", prompt: """
Shape this backlog item into a context packet:
[paste backlog item content]
Read the codebase, research prior art, produce a context packet with:
goal, non-goals, constraints, repo anchors, oracle, implementation sequence.
""")
```

If the item already has a complete context packet (goal + oracle + sequence), skip.

### 3. Build (builder sub-agents)

Spawn **builder** sub-agent(s) with the context packet. For parallelizable work,
spawn multiple builders with disjoint file ownership in separate worktrees:

```
Agent(subagent_type: "builder", isolation: "worktree", prompt: """
Implement this spec via TDD:
[paste context packet]
Focus on: [specific chunk from implementation sequence]
Files you own: [list — no overlap with other builders]
Oracle criteria for this chunk: [subset]
RED → GREEN → REFACTOR → COMMIT for each criterion.
""")
```

Single-chunk work: one builder, no worktree needed.
Multi-chunk work: one builder per chunk, each in a worktree.

### 4. Review (critic + bench sub-agents)

Invoke `/code-review`, which spawns the reviewer bench in parallel. See the
code-review skill for details. If blocking issues → dispatch builder to fix →
re-review. Loop max 3 iterations.

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
