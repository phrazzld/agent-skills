---
name: calibrate
description: |
  Mid-session harness postmortem. When the agent makes a wrong decision,
  diagnose WHY the harness (CLAUDE.md, skills, hooks, lints, types, tests)
  failed to prevent it — fix the harness BEFORE fixing the code.
  Use when: agent did the wrong thing, "calibrate", "why did you do that",
  "fix your instructions", "don't do that again", "harness gap",
  "agent mistake", "wrong decision", "recalibrate".
disable-model-invocation: true
argument-hint: "[what went wrong]"
---

# /calibrate

The agent made a mistake. Don't fix the code — fix WHY the agent wrote wrong code. Then fix the code.

## Core Invariant

```
DO NOT fix the original code until the harness is fixed.
```

Fixing code first means you forget to fix the harness. The whole point is amortizing the improvement so this class of mistake never recurs.

## Process

### 1. Pause

Stop current work. Capture:
- **What happened:** What did the agent do wrong?
- **What was expected:** What should it have done?
- **Impact:** How bad was the mistake? (cosmetic → data loss)

### 2. Load Context

Invoke `/forage` to load diagnostic packs:
- `/forage harness` → `packs/agent/harness-engineering/` (feedback loop hierarchy, mechanical enforcement)
- `/forage context engineering` → `packs/agent/context-engineering/` (instruction design, context lifecycle)
- `/forage llm infrastructure` → `packs/agent/llm-infrastructure/` (prompt audit, model routing, eval patterns)

Invoke `/research web-search` if the mistake involves stale API knowledge, wrong library usage, or outdated patterns.

### 3. Diagnose

Trace the decision back through the context chain. Ask each question:

| Layer | Question |
|-------|----------|
| CLAUDE.md | Did it address this? Was the instruction ambiguous? |
| Skills | Were loaded skills misleading or incomplete? |
| References | Were referenced docs stale or wrong? |
| Hooks/lints | Should a mechanical check have caught this? |
| Types | Could the type system have prevented this? |
| Tests | Would a test have caught this before it mattered? |
| Memory | Was a user preference or project context missing? |
| Model knowledge | Did the model hallucinate or use stale knowledge? |

Use harness-engineering's feedback loop hierarchy to identify which level failed.

### 4. Classify

What level SHOULD have prevented this? Ordered by reliability:

```
Type system     — compile-time, highest reliability
Lint rule       — edit-time, catches patterns
Hook            — pre-edit/pre-commit, mechanical prevention
Test            — run-time, catches behavior
CI              — push-time, catches integration
Skill/reference — wrong workflow instructions
CLAUDE.md       — missing or wrong convention
Memory          — missing user preference or project context
```

Always fix at the highest reliable level that applies. A hook beats a CLAUDE.md rule. A type beats a hook.

### 5. Fix the Harness

Apply the fix. Use context-engineering principles:
- Clear, unambiguous language
- Progressive disclosure (don't bloat top-level instructions)
- Instruction hierarchy (most critical first)
- "Use when" clauses so fixes are discoverable

Codification targets (same cascade as `/reflect`):

| Target | Location |
|--------|----------|
| Hook | `~/.claude/settings.json` + `~/.claude/hooks/` |
| Lint rule | Project lint config |
| Type | Source code type definitions |
| Test | Test suite |
| CI | CI config |
| Skill | `core/` or `packs/` SKILL.md |
| CLAUDE.md | Project or global CLAUDE.md |
| Memory | `~/.claude/projects/*/memory/*.md` |

### 6. Verify

Confirm the harness fix would have prevented the original mistake:
- Re-read the new instruction/hook/lint/type — is it unambiguous?
- Mental replay: given this fix, would the agent have made the right call?
- If mechanical (hook/lint/type/test): run it and confirm it catches the case.

### 7. Resume

NOW fix the original code, with the improved harness in place.

The code fix should be trivial now — the hard work was diagnosing and fixing the harness.

## Relationship to Other Skills

| Skill | Relationship |
|-------|-------------|
| `/reflect` | End-of-session retrospective. Calibrate is mid-session, blocks work until harness is fixed. |
| `/debug` | Diagnoses code bugs. Calibrate diagnoses agent decision-making context. |
| `/settle` | After calibrate fixes harness + code, settle can polish the PR. |
| `/forage` | Loads agent pack skills for diagnostic depth. |
| `/research` | Web search for stale knowledge gaps. |

## Anti-Patterns

- Fixing the code first ("I'll update the instructions later" — you won't)
- Adding a CLAUDE.md rule when a hook/lint/type would be more reliable
- Over-codifying: not every mistake needs a new rule — sometimes it's a one-off
- Vague instructions: "be careful with X" instead of a specific, testable rule
- Skipping verification: the fix must demonstrably prevent recurrence

## Output

```markdown
## Calibration Report

### Mistake
[What the agent did wrong]

### Root Cause
[Which harness layer failed and why]

### Fix Applied
[What was changed, at which level]

### Verification
[How we confirmed the fix prevents recurrence]

### Code Fix
[The original code fix, now applied with improved harness]
```
