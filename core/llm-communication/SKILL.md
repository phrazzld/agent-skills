---
name: llm-communication
description: "Write effective LLM prompts, commands, and agent instructions. Goal-oriented over step-prescriptive. Role + Objective + Latitude pattern. Use when writing prompts, designing agents, building Pi commands, or reviewing LLM instructions."
---

# Talking to LLMs

This skill helps you write effective prompts, commands, and agent instructions.

## Core Principle

LLMs are intelligent agents, not script executors. Talk to them like senior engineers.

## Anti-Patterns

### Over-Prescriptive Instructions

Bad:
```
Step 1: Run X
Step 2: Parse Y
Step 3: For each result, do Z
...700 more lines
```

This is brittle and removes model adaptability.

### Excessive Hand-Holding

Bad:
```
If user says X do Y.
If user says Z do W.
```

You cannot enumerate every case. Trust generalization.

### Defensive Over-Specification

Bad:
```
IMPORTANT: Do NOT do X.
WARNING: Never do Y.
CRITICAL: Always remember Z.
```

If you need many warnings, the instruction is likely poorly framed.

## Good Patterns

### State the Goal, Not the Steps

Good:
```
Investigate production errors across available observability.
Correlate with recent changes. Find root cause. Propose fix.
```

### Provide Context, Not Micromanagement

Good:
```
You're a senior SRE investigating an incident.
User reports breakage around 14:57.
```

### Trust Recovery

Good:
```
Use judgment. If one approach fails, try another.
```

### Role + Objective + Latitude

1. **Role**
2. **Objective**
3. **Latitude**

Example:
```
You're a senior engineer reviewing this PR.
Find bugs, security issues, and code smells.
Be direct. If it's fine, say so briefly.
```

## The Test

Before finalizing instructions, ask:

> “Would I give these instructions to a senior engineer?”

If not, simplify and raise abstraction.
