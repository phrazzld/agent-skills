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

## Modes

| Mode | Intent |
|------|--------|
| **distill** (default) | End-of-session retrospective → codified artifacts |
| **calibrate** | Mid-session harness postmortem — agent made a wrong decision, fix the harness BEFORE fixing the code |
| **tune-repo** | Refresh context artifacts, update AGENTS.md if drift detected |

## Workflow: Distill

1. **Gather evidence** — `git diff --stat`, `git log --oneline -10`, conversation context
2. **Categorize** — went well, friction, bugs, missing artifacts, gaps
3. **Codify** — apply hierarchy (highest leverage wins):
   ```
   Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
   ```
4. **Execute** — write the artifacts (hooks, rules, docs)
5. **Report** — what was codified, what was skipped (with justification)

Default: codify. Exception: justify not codifying.

## Workflow: Calibrate

When the agent makes a wrong decision mid-session:

1. **What went wrong?** — Describe the incorrect decision
2. **Why?** — Root cause in the harness (missing context, wrong instruction, stale rule)
3. **Fix the harness** — Update the source of the problem:
   - Wrong AGENTS.md instruction → fix AGENTS.md
   - Missing hook → add hook
   - Stale skill reference → update skill
   - Missing test → add test
4. **Then fix the code** — The code fix should be trivial now

The harness fix is the real deliverable, not the code fix.

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
| missing_skill | Had to improvise a reusable workflow | Create skill |
| missing_tool | No available tool provided capability | Hook or MCP |
| repeated_failure | Same error class across sessions | Lint rule or guardrail |
| wrong_info | Acted on stale AGENTS.md or reference | Update source doc |
| permission_friction | Correct action blocked | Hook or settings |

## Retro Storage

Issue-scoped feedback: `{repo}/.groom/retro/<issue>.md`
One file per issue. Feeds `/groom`'s planning loop.

## Anti-Patterns

- Reflecting without producing artifacts
- Over-codifying obvious patterns
- Creating docs nobody reads (prefer hooks that enforce)
- Fixing only the code without fixing the harness (calibrate mode)
