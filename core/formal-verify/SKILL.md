---
name: formal-verify
description: |
  Formal verification of system designs using TLA+, Z3, and Apalache.
  Finds bugs in design BEFORE implementation. Agent feedback loop:
  spec → model check → counterexample → fix → repeat.
  Use for state machines, protocols, multi-agent coordination, payment flows.
  Use when: design has >3 states, concurrent actors, or failure/retry logic.
argument-hint: "[tlaplus|z3|apalache|loop] <description>"
---

# /formal-verify

Prove correctness before writing code. Model checker overrides confident prose.

## Use When

- Design has >3 states or state transitions
- Multiple concurrent actors (agents, services, users)
- Failure/retry logic (payments, webhooks, queues)
- Temporal properties: "never", "always", "eventually" in requirements
- Multi-agent coordination or orchestration protocols
- Any system where a bug in the protocol costs more than a bug in code

## Prerequisites

Graceful degradation — any subset works:

| Tool | Install | Provides |
|------|---------|----------|
| TLC | `brew install tlaplus` | Model checking TLA+/PlusCal specs |
| Z3 | `pip install z3-solver` | Constraint solving, satisfiability |
| Apalache | `brew install apalache` | Symbolic bounded model checking |

If none installed, the skill still produces specs — manual verification or CI can run them.

## Routing

| Intent | Reference |
|--------|-----------|
| Write TLA+/PlusCal spec from requirements | `references/tlaplus-spec.md` |
| Z3 constraint solving, counterexamples | `references/z3-verify.md` |
| Symbolic model checking with Apalache | `references/apalache.md` |
| Full spec→check→fix feedback loop | `references/agent-loop.md` |
| Domain-specific state machine skeletons | `references/state-machine.md` |

If first argument matches a reference name, load it directly.
Default: `references/agent-loop.md` (the full feedback loop).

## The Core Insight

**Model checkers are hallucination kryptonite.** An LLM can confidently assert
a protocol is correct. A model checker will find the counterexample in seconds.

The agent loop:
1. Extract state machine from requirements/ACs
2. Write formal spec (TLA+/PlusCal or Z3Py)
3. Run model checker
4. If counterexample found → fix the DESIGN, not the spec
5. Repeat until all invariants hold
6. THEN implement in code

## Quick Start

```bash
# TLA+ spec from acceptance criteria
/formal-verify tlaplus "payment state machine with retry and refund"

# Z3 constraint check
/formal-verify z3 "rate limiting invariants for multi-tenant API"

# Full feedback loop
/formal-verify loop "agent orchestration with supervisor restart"

# Domain skeleton
/formal-verify state-machine "webhook delivery with exponential backoff"
```

## Integration Points

- `/groom` Phase 2: Flag formal verification candidates during architecture critique
- `/shape` Phase 3: Optionally run `/formal-verify loop` for state machine designs
- `/autopilot` Step 6: Consider formal verification before build for concurrent protocols
- `/verify-ac`: Check temporal ACs against existing `.tla` specs
- `/harness-engineering`: TLC/Z3 as feedback loop mechanisms
