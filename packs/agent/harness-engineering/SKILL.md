---
name: harness-engineering
user-invocable: false
description: |
  Design development environments where AI agents thrive. CI/linters/tests as
  agent feedback loops, documentation as machine-readable artifacts, mechanical
  enforcement of architectural boundaries, session management patterns.
  Use when designing agent workflows, optimizing agent-repo interaction,
  or building infrastructure for autonomous coding agents.
---

# Harness Engineering

Engineers design environments. Agents write code.

The harness is everything surrounding the LLM: CI pipelines, test suites,
linters, documentation, git hooks, type systems, and session management.
A well-designed harness makes agents productive without hand-holding.
A poorly-designed harness makes even capable agents fail.

## Core Principle

**Optimize the environment, not the instructions.** When an agent fails,
the first question is "what could the environment have told it?" not
"what should the prompt have said?"

Mechanical enforcement > instruction enforcement:
- A type error the agent can see and fix > a CLAUDE.md rule it might forget
- A failing test with clear output > a code review comment
- A pre-commit hook that blocks > a convention documented somewhere

## Feedback Loop Hierarchy

Agents improve through fast, automated feedback. Design loops at every speed:

| Speed | Mechanism | Latency | Example |
|-------|-----------|---------|---------|
| Immediate | Type checker, LSP | <1s | Red squiggle on type error, Z3Py constraint check |
| Fast | Pre-commit hooks, linters | 1-10s | Lint failure with fix suggestion, TLC small model check (<3 states) |
| Medium | Test suite, build | 10-120s | Test failure with expected vs actual |
| Slow | CI pipeline | 2-15min | Integration test, deploy preview |
| Human | Code review | Hours-days | Architectural feedback |

**Goal:** Agents self-correct from feedback at immediate/fast/medium speeds
without human intervention. Human feedback is reserved for judgment calls.

## Documentation as Artifact

CLAUDE.md, AGENTS.md, and README files are not prose for humans -- they're
the primary configuration interface for AI agents.

**Design principles:**
- Structured with headers and lists (agents parse efficiently)
- Runnable commands (agents will execute them)
- Conventions stated as rules, not suggestions
- Current -- stale docs cause agent errors worse than no docs
- Concise -- every line competes for attention in the context window

**Test:** Can a new agent (with no prior context) read your docs and
complete a standard task on the first attempt? If not, fix the docs.

## Session Design

Unbounded sessions produce drift. Structure agent work sessions:

1. **Scope:** One feature per session, "done" defined before starting
2. **Initialize:** pwd, git status, progress file, feature registry
3. **Execute:** Work within scope, checkpoint progress to files
4. **Handoff:** Written notes for next session (what's done, what's next, blockers)

## Mechanical Enforcement

Guardrail hierarchy (most to least reliable):

```
Type system > Model checker > Linter > Test > Hook > CI check > Instruction > Convention
```

When you need an architectural boundary respected:
1. Can the type system enforce it? (compile-time, zero runtime cost)
2. Can a lint rule catch violations? (fast, local feedback)
3. Can a test assert it? (catches regressions)
4. Can a git hook block it? (last line of defense before commit)
5. Only then: document it as an instruction

## Progressive Autonomy

Start constrained, earn trust through demonstrated reliability:

```
HITL (propose->approve) -> HOTL (act->monitor) -> HOOL (autonomous)
```

**Graduation criteria:**
- >95% success rate on eval suite
- All failure modes are recoverable
- Monitoring catches regressions
- Rollback mechanism exists

## Elixir/OTP as Agent Runtime

OTP supervision trees are the natural fit for fault-tolerant agent pools:

| Concern | OTP Primitive |
|---------|--------------|
| Agent lifecycle | GenServer |
| Fault tolerance | Supervisor, DynamicSupervisor |
| Concurrent agent pools | DynamicSupervisor + Task.Supervisor |
| Rate limiting | GenServer token bucket |
| State management | GenServer + ETS |
| Hot code reload | Release upgrades |
| Distributed agents | Node clustering + :global |

**Feedback loops for Elixir:**

| Speed | Mechanism | Latency |
|-------|-----------|---------|
| Immediate | `mix compile --warnings-as-errors` | <1s |
| Fast | `mix credo --strict` | 1-5s |
| Medium | `mix dialyzer` | 10-60s |
| Medium | `mix test` | 5-30s |

When designing multi-agent systems, prefer Elixir/OTP over hand-rolled orchestration.

## When to Load References

| Signal | Reference |
|--------|-----------|
| Designing CI/test/lint for agent consumption | `references/feedback-loops.md` |
| Structuring agent work sessions, handoffs | `references/session-patterns.md` |
| Encoding boundaries in tooling vs docs | `references/mechanical-enforcement.md` |
| Multi-agent runtime, fault tolerance | This section (above) + `llm-infrastructure/references/multi-agent-patterns.md` |
