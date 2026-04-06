---
name: reflect
description: |
  Session retrospective, learning extraction, harness postmortem, codification.
  Distill learnings into hooks/rules/skills. Fix the system, not the instance.
  Use when: "done", "wrap up", "what did we learn", "retro", "reflect",
  "calibrate", "why did you do that", "fix your instructions".
  Trigger: /reflect, /retro, /calibrate.
argument-hint: "[distill|calibrate|tune-repo] [context]"
---

# /reflect

Structured reflection producing concrete artifacts. Every finding either becomes
a codified artifact or gets explicitly justified as not worth codifying.

Absorbs `/calibrate` — mid-session harness postmortem is now a mode of reflect.

## Execution Stance

You are the executive orchestrator.
- Keep severity ranking, codification target selection, and final recommendations on the lead model.
- Delegate evidence collection and drift scanning to focused subagents.
- Run evidence-gathering subagents in parallel by default.

## Modes

| Mode | Intent |
|------|--------|
| **distill** (default) | End-of-session retrospective → codified artifacts |
| **calibrate** | Mid-session harness postmortem — agent made a wrong decision, fix the harness BEFORE fixing the code |
| **tune-repo** | Refresh context artifacts, update AGENTS.md if drift detected |

## Workflow: Distill

### 1. Gather evidence (parallel sub-agents)

Spawn three sub-agents simultaneously:

**Agent A — Conversation archaeology.** Scan the full conversation for:
- **User corrections**: Any time the user said "no", "actually", "you should be able to",
  "that's not what I meant", or redirected your approach. Each correction is a
  harness failure — the system should have prevented the wrong approach.
- **Available-but-unused information**: Files, env vars, configs, tools that existed
  and would have prevented friction, but the agent didn't know about or didn't use.
  (e.g., test credentials in `.env`, existing skills that weren't invoked)
- **Skill invocation log**: Read `~/.claude/skill-invocations.jsonl`, filter to
  current `session_id`. Report: which skills fired and how many times each.
  Cross-reference against session activity -- if debugging happened but
  /investigate never fired, or code was reviewed without /code-review, note the
  gap. Feed these observations into the Swiss Cheese triage as layer 2 (Skills)
  findings: "skill that didn't fire" or "skill fired but too late".
- **Accepted shortcuts**: Assumptions stated as fact without verification.
  (e.g., "structurally identical", "should work the same way", "low risk")
- **Multi-attempt sequences**: Anything that took >1 try — auth failures, tool
  workarounds, browser quirks. Each retry is evidence of a missing guardrail or
  missing documentation.
- **Scope of user waiting**: Points where the user waited for work that produced
  no value (false starts, dead ends, investigating non-bugs).

**Agent B — Code changes.** Review git diff and recent log. What changed, what
areas, what patterns. Standard code-level analysis.

**Agent C — Harness drift.** Scan CLAUDE.md, AGENTS.md, active skills, and
referenced docs for instructions that conflict with what actually happened
this session. Flag stale or wrong guidance.

### 2. Triage by the Swiss Cheese layers

Walk findings **top-down through the control layers**. Most agent errors pass
through holes in ALL upper layers before reaching the agent's reasoning.
Fixing only the bottom layer is symptom patching.

| Layer | What to check | Finding type |
|-------|--------------|--------------|
| **Instructions** (CLAUDE.md, AGENTS.md) | Missing guidance, stale rules, conflicting directives | Highest priority |
| **Skills** | Missing skill, wrong skill description, skill that didn't fire | High |
| **Hooks/guardrails** | Missing pre-commit check, no validation hook | High |
| **Tools/environment** | Missing MCP, broken tool, undocumented env setup | Medium |
| **Agent reasoning** | Wrong decision with correct context available | Lowest — only after all above ruled out |

**The Norman Principle**: If the agent made a bad decision, ask "How did it
make sense for the agent to do that given what it saw?" (Infinite Hows, not
5 Whys.) This exposes missing context, not agent blame.

### 3. Categorize and rank

Rank ALL findings — from conversation archaeology AND code changes — by this
severity order:

1. **Harness induction errors** — the system's own instructions caused the failure
2. **Missing control layers** — a hook/test/gate would have prevented this class of error
3. **Available-but-undiscovered information** — the answer existed but wasn't found
4. **Stale context** — AGENTS.md/skills contained wrong information
5. **Tooling gaps** — right tool unavailable, broken, or not used
6. **Workflow dead ends** — time spent on approaches that produced no value
7. **Code-level findings** — technical patterns, specific to this task

**Workflow findings outrank code findings.** A missing "how to run QA against
the authenticated web app" in CLAUDE.md is higher-leverage than a grep script
for nested HTML elements, because it prevents a class of failures across all
future tasks, not just one.

### 4. Codify — apply hierarchy (highest leverage wins)

```
Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
```

For each finding, target the highest-leverage mechanism. But also apply the
**blast radius test**: will this fix prevent the issue for all future tasks
in this repo, or just similar tasks? Broader blast radius = higher priority.

### 5. Pre-mortem the next task

After codification, ask: "Given what we learned, what failure mode would this
same harness produce on the NEXT task?" This catches blind spots that backward
analysis misses.

### 6. Report

```
## Workflow Failures (from conversation archaeology)
- [correction/dead-end] → [harness gap] → [fix applied]

## Code-Level Findings
- [pattern] → [codification target] → [fix applied]

## Not Codified
- [finding]: [specific justification]

## Pre-Mortem
- [predicted failure mode for next task] → [preventive fix if warranted]
```

Default: codify. Exception: justify not codifying.

## Workflow: Calibrate

When the agent makes a wrong decision mid-session:

**The Norman Principle applies here.** The agent didn't fail — the harness did.
"I knew better" is not a valid analysis. If the system let the agent make the
error, the system is badly designed. If the system's own instructions induced
the error, it's really badly designed.

1. **What went wrong?** — Describe the incorrect decision
2. **How did it make sense?** — Not "why" (converges on blame) but "how" (reveals
   systemic conditions). Given what the agent saw, what made this the rational choice?
3. **Walk the Swiss Cheese layers** — Which layers had holes?
   - Instructions missing/wrong? → fix CLAUDE.md/AGENTS.md
   - Skill missing/didn't fire? → fix skill description or create skill
   - Hook missing? → add hook
   - Tool broken/missing? → fix tool or add MCP
   - Environment undocumented? → document in CLAUDE.md
4. **Induction check** — Did the harness *cause* the error? Conflicting instructions,
   stale context, misleading skill descriptions? Induction errors are highest-priority.
5. **Fix the harness** — Then fix the code (the code fix should be trivial now)

The harness fix is the real deliverable, not the code fix.

## Workflow: Tune-Repo

Refresh context artifacts for a target repo. Run proactively or after
noticing drift between docs and code.

1. **Scan** — Read AGENTS.md, CLAUDE.md, and any skill references. Compare
   against actual codebase state (do referenced files/functions still exist?).
2. **Flag drift** — List stale entries, broken references, missing sections.
3. **Check essentials** — Does AGENTS.md/CLAUDE.md include:
   - Local dev setup (ports, env vars, auth credentials for testing)?
   - QA workflow (how to run the app and verify changes in a browser)?
   - Cross-repo patterns (if multi-repo, how do repos relate)?
   - After Compaction recovery instruction?
4. **Fix** — Update stale content. Delete what's wrong. Add what's missing.
5. **Report** — What was updated, what was deleted, what was added.

## Codification Hierarchy

When encoding knowledge, always target the highest-leverage mechanism:

| Level | Mechanism | Reliability |
|-------|-----------|-------------|
| 1 | Type system | Compile-time guarantee |
| 2 | Lint rule | Blocks on violation |
| 3 | Hook | Runs on every tool use |
| 4 | Test | Catches regressions |
| 5 | CI gate | Blocks merges |
| 6 | Skill/reference | Agent reads on demand |
| 7 | AGENTS.md | Agent reads at session start |
| 8 | Memory | Last resort, least reliable |

## Gap Types

When a session reveals something MISSING:

| Gap | Signal | Fix |
|-----|--------|-----|
| missing_workflow_doc | Had to discover how to run/test/auth by trial and error | CLAUDE.md section |
| missing_skill | Had to improvise a reusable workflow | Create skill |
| missing_tool | No available tool provided capability | Hook or MCP |
| repeated_failure | Same error class across sessions | Lint rule or guardrail |
| wrong_info | Acted on stale AGENTS.md or reference | Update source doc |
| permission_friction | Correct action blocked | Hook or settings |
| undiscovered_info | Available information not found or used | CLAUDE.md pointer |

## Retro Storage

Issue-scoped feedback: `{repo}/.groom/retro/<issue>.md`
One file per issue. Feeds `/groom`'s planning loop.

## Gotchas

- **Code findings crowding out workflow findings**: The git diff is concrete;
  workflow failures are diffuse. Conversation archaeology surfaces the diffuse
  ones. If your retro is all code patterns and zero workflow fixes, you
  reflected on the wrong layer.
- **Reflecting without artifacts**: If reflect doesn't produce a commit (hook,
  rule, skill update, AGENTS.md edit), it was a waste.
- **Codifying at the wrong level**: Writing a CLAUDE.md line when a hook would
  be more reliable. Use the hierarchy.
- **Fixing only the code**: When calibrate mode triggers, the harness fix IS
  the deliverable. The code fix should be trivial after.
- **Stale context is worse than no context**: A wrong instruction in AGENTS.md
  causes more harm than a gap. When in doubt, delete stale content.
- **Over-codifying obvious patterns**: If the model handles it natively, don't
  write a skill for it.
- **Accepting "low risk" as "no risk"**: If you accepted an assumption without
  verification ("structurally identical", "should be fine"), that's a finding.
  The harness should have prompted verification.
