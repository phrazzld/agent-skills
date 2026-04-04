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

**Agent dispatch:** Use **planner** (Plan type) for shaping, **builder**
(general-purpose) for implementation, **critic** + philosophy bench (Explore
type, parallel) for review. Use ad-hoc Explore subagents for codebase research.
Don't rigidly bind every step — let task complexity guide how many agents and
which types.

## Workflow

### 1. Pick work

Read `backlog.d/` for highest-priority ready item, or accept explicit argument.
Also check `git-bug bug status:open sort:edit-desc --format json` for git-bug issues
(if `git-bug` is installed). `backlog.d/` = shaped work; git-bug = raw issues/bugs.

**Immediately** acquire an atomic claim: `source scripts/lib/claims.sh && claim_acquire <item-id>`.
If the claim fails (non-zero exit), another agent is working this item — skip to the next.
Then update the item's status to `in-progress` and commit the change.
Claim-then-commit ordering prevents two agents from both committing status changes.

### 2. Shape

Spawn a **planner** sub-agent. Give it the backlog item and ask it to produce
a context packet: goal, non-goals, constraints, repo anchors, oracle,
implementation sequence. The planner reads the codebase and researches
prior art — you review and approve the spec before building.

If the item already has a complete context packet (goal + oracle + sequence), skip.

### 3. Contract

Before building, negotiate what "done" looks like concretely.

The **builder** proposes executable acceptance criteria: specific tests to write,
commands to run, observable outcomes. The **critic** reviews the proposal — are
the criteria testable? Do they cover the oracle from the context packet?
Iterate until both agree. This prevents the builder from declaring victory
prematurely and the critic from moving goalposts during review.

The contract is a short list of commands that must all exit 0, plus any
observable outcomes for /qa to verify. See `skills/shape/references/executable-oracles.md`.

If the context packet already has executable oracle commands (not just prose
checkboxes), the contract is already done — skip.

### 4. Build

Spawn **builder** sub-agent(s) with the approved context packet and contract.

For single-chunk work, spawn one builder with the full spec.

For parallelizable work, spawn multiple builders simultaneously — each in its
own worktree, each with disjoint file ownership and a subset of the oracle
criteria. Tell each builder exactly which files it owns and which criteria
it's responsible for.

**TDD is mandatory in builder prompts.** When dispatching a builder, include:
"You MUST write a failing test before writing production code. The only exceptions:
config files, generated code, UI layout. RED → GREEN → REFACTOR → COMMIT."

### 5. Review

Invoke `/code-review`. This spawns the full reviewer bench in parallel
(critic + ousterhout + carmack + grug + beck). If blocking issues are found,
spawn a builder sub-agent to fix each concern, then re-review. Loop max 3.

### 6. QA

Invoke `/qa` on the running application. Pass the affected routes/features
and the oracle criteria from the context packet.

- **User-facing components:** `/qa` exercises the app with browser tools,
  captures evidence, classifies findings.
- **No user-facing components:** Skip (pure refactor, library, config work).
- **No scaffolded `/qa` skill?** Run `/qa scaffold` first. The global
  fallback is intentionally thin — effective QA needs project-local context.

If `/qa` finds P0/P1 issues, spawn a builder sub-agent to fix, then re-run `/qa`.
Document P2 issues in the PR body.

### 7. Demo Artifacts

Invoke `/demo` on the QA evidence. Every shipped unit of work produces evidence.

- **Web UI:** `/demo --format gif` for walkthrough GIF
- **CLI:** `/demo --format gif` for terminal session GIF
- **API:** Screenshot or captured output (may not need `/demo`)
- **Library/refactor:** Before/after test output diff
- **No scaffolded `/demo` skill?** Run `/demo scaffold` first.

Then `/demo upload` to attach evidence to the PR via draft GitHub release.

If you can't demonstrate it worked, you can't prove it worked.

### 8. Observability

Instrument new code paths for production monitoring. Every significant change gets
a monitor — detect everything, notify selectively (the Ramp pattern).

- **Canary integration:** If the project uses Canary, register monitors for new
  code paths (error rates, latency, health probes).
- **Sentry:** Verify error boundaries exist for new code paths. Check that
  exceptions will surface, not silently swallow.
- **PostHog:** Verify analytics events fire for new user flows.
- **Logging:** Ensure new code paths have the signal that would tell you something
  is wrong in production. Not verbose — targeted.

### 9. Ship

Once review, QA, demo, and observability all pass:
- **Evidence check:** Before opening the PR, verify evidence artifacts exist. If no screenshots/GIFs/terminal captures are present, invoke `/demo` first. No evidence = no PR.
- Run `dagger call check` (if configured) — all local CI gates must pass before push
- Squash or create semantic commits
- Open PR if collaborating (context packet + demo artifacts in body)
- Or commit directly if solo project
- Update the backlog item: status → `done`, check off oracle criteria, add a
  "What Was Built" section with implementation notes and any workarounds discovered.
  This context is essential for future agents working on related items.
- Release the claim: `source scripts/lib/claims.sh && claim_release <item-id>`

### 10. Retro (optional)

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
- **Skipping QA:** "Tests pass" is not QA. Drive the running app and verify it works for real.
- **Skipping demo artifacts:** No GIF/screenshot = no proof it works. If you can't demo it, you can't ship it.
- **Silent failure paths:** New code that catches exceptions and returns fallbacks is hiding bugs. Fail loud, monitor everything.
- **Forgetting to update the backlog item:** The backlog item is a living document. Mark status changes, check off oracles, add "What Was Built" and "Workarounds" sections. The next agent working a related item will thank you.
- **Skipping local CI:** If `dagger.json` exists, run `dagger call check` before push. Don't rely on remote CI to catch what you can catch locally in seconds.
- **Merging PRs:** Never call `gh pr merge`. Your job ends at merge-ready: PR open, CI green, review clean, evidence attached. The human decides when to merge.

## Stopping Conditions

Stop only if: build fails after multiple attempts, requires external action,
or oracle criteria are unverifiable. **Always release the claim on stop:**
`source scripts/lib/claims.sh && claim_release <item-id>`.

NOT stopping conditions: item seems big, approach unclear, missing description.
YOU make items ready — planner shapes, builder implements.
