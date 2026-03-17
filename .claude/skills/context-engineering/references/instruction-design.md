# Instruction Design

How to write instructions that LLMs execute reliably on first pass.

## Core Principle

LLMs are intelligent agents, not script executors. Instructions should read
like a brief to a senior engineer — goal-oriented, not step-prescriptive.

## Role + Objective + Latitude Pattern

Every instruction set needs three components:

```
Role:      Who the agent is (sets behavioral frame)
Objective: What success looks like (measurable, specific)
Latitude:  How much freedom to exercise judgment
```

**Minimal example:**
```
You're a code reviewer.                        # Role
Find logic errors, security issues, and        # Objective
performance problems in this diff.
Skip style nits. Be terse. If it's fine,       # Latitude
say "LGTM" and stop.
```

## Three-Instruction Agent Bootstrap

Research across Anthropic and OpenAI shows ~20% benchmark lift from three
meta-instructions added to any agent's system prompt:

1. **Persistence**: "If your first approach fails, try alternative methods
   before concluding the task is impossible."
2. **Tool-calling**: "Use your tools to gather information. Don't guess —
   look it up, read the file, run the test."
3. **Planning**: "Before acting, outline your approach. When blocked, stop
   and re-plan rather than retrying the same failing strategy."

These are metacognitive scaffolding — they don't tell the agent *what* to do,
they tell it *how to think about* what to do.

## CLAUDE.md / AGENTS.md Design

These files ARE context engineering. They're the primary system prompt for
coding agents.

**Structure principles:**
- Lead with identity and purpose (who is this agent, what repo is this)
- Commands and workflows next (what can I do)
- Conventions and constraints last (how should I do it)
- Use canonical examples over exhaustive rules
- "The LLM sees one context window" (Metabase) — everything competes for attention

**Instructions at moment of relevance:**
Don't front-load every instruction in the system prompt. Put instructions in
tool descriptions, reference files, and tool results so they arrive just-in-time
when the agent actually needs them.

```
❌ System prompt: "When creating PRs, always include a test plan section..."
   (irrelevant 95% of the time, wastes context)

✅ PR template tool result includes: "Include a test plan section..."
   (arrives exactly when the agent is creating a PR)
```

## Anti-Patterns

### Over-Prescriptive Instructions
```
❌ "Step 1: Open the file. Step 2: Find the function. Step 3: Check if..."
✅ "Investigate the authentication flow. Find and fix the root cause."
```
Step-by-step runbooks remove adaptability. The LLM can't recover from
unexpected states if every step is prescribed.

### Excessive Hand-Holding
```
❌ "If the file exists, read it. If it doesn't exist, check if..."
✅ "Read the configuration. Handle missing files gracefully."
```
Exhaustive if/else trees signal distrust and consume context for edge
cases the model handles naturally.

### Defensive Over-Specification
```
❌ "IMPORTANT: You MUST always... CRITICAL: Never... WARNING: Be careful..."
✅ State the constraint once, clearly, without emotional emphasis.
```
Ten IMPORTANT/WARNING/CRITICAL notes create noise. The model treats
everything as important, so nothing is. Reserve emphasis for genuine
safety constraints.

### Kitchen Sink System Prompts
```
❌ 2000-line CLAUDE.md covering every possible scenario
✅ 200-line CLAUDE.md with pointers to reference files loaded on-demand
```
Progressive disclosure: description → SKILL.md body → references.
Budget is finite. Front-load identity and routing; defer details.

## Calibration Questions

Before shipping any instruction set, ask:
1. Would I give these instructions to a senior engineer? (Role + Latitude)
2. Can the agent succeed on the first attempt? (Completeness)
3. Is every instruction load-bearing? (Signal density)
4. Are instructions at the right moment? (Just-in-time)
5. Does the output contract specify what "done" looks like? (Measurability)
