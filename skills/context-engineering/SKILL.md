---
name: context-engineering
description: |
  Context lifecycle for AI agents: write, select, compress, isolate. Design
  high-signal context windows, instruction hierarchies, and memory strategies.
  Use when designing agent prompts, debugging context quality, optimizing
  token budgets, or reviewing CLAUDE.md / AGENTS.md files.
argument-hint: "[focus: instructions | lifecycle | anti-patterns | altitude]"
---

# Context Engineering

Context engineering is the discipline of designing the complete information
environment an LLM operates within. Prompts are a subset — context includes
system instructions, tool results, conversation history, retrieved documents,
scratchpads, and memory artifacts.

## Core Framework: Write / Select / Compress / Isolate

| Phase | Question | Key Technique |
|-------|----------|---------------|
| **Write** | What context needs to exist? | Scratchpads, external memory, todo files, structured artifacts |
| **Select** | What context enters the window? | Just-in-time loading, hybrid retrieval, progressive file discovery |
| **Compress** | How do we fit more signal? | Compaction, preserve decisions, discard redundant output |
| **Isolate** | How do we prevent contamination? | Sub-agents with bounded returns, clean contexts, sandboxed state |

## Instruction Design (Quick Reference)

**Role + Objective + Latitude** — the minimum viable instruction:
```
You're a senior engineer reviewing this PR.    # Role
Find bugs, security issues, and code smells.   # Objective
Be direct. If it's fine, say so briefly.       # Latitude
```

**The Test:** "Would I give these instructions to a senior engineer?"
If you'd be embarrassed to hand a colleague a 700-line runbook, don't give it to the LLM.

**Three-instruction agent bootstrap** (~20% benchmark lift):
1. **Persistence** — keep trying, don't give up after first failure
2. **Tool-calling** — use tools to gather information before answering
3. **Planning** — make a plan before acting, revise when blocked

## When to Load References

| Signal | Reference |
|--------|-----------|
| Writing prompts, CLAUDE.md, AGENTS.md, system instructions | `references/instruction-design.md` |
| Designing memory, retrieval, token budgets, caching | `references/context-lifecycle.md` |
| Debugging degraded agent performance, context quality | `references/context-anti-patterns.md` |
| Choosing specificity level, autonomy boundaries | `references/altitude-calibration.md` |
| In-code annotations for agents (@deprecated, @agent-pitfall, @migration) | `references/agent-annotations.md` |

## Output Contract

When invoked for context review or design:

1. **Diagnosis** — what's wrong with current context (or "clean" if nothing)
2. **Context Delta** — specific additions/removals/restructuring
3. **Instruction Delta** — prompt rewrites with before/after
4. **First-Pass Reliability Risks** — what might fail on first attempt
5. **Eval Assertions** — suggested test cases for the context change

## Absorbed Skills

- `llm-communication` → `references/instruction-design.md`
