# Agent Feedback Loop

The spec→check→fix cycle that makes formal verification practical for AI agents.

## Why This Works for Agents

LLMs are excellent at translating requirements into formal specs.
LLMs are terrible at reasoning about all possible interleavings.
Model checkers are excellent at exhaustive state exploration.

Combine them: LLM writes spec, model checker validates, LLM fixes.

## The Loop

```
Requirements/ACs
      ↓
Extract State Machine
      ↓
Write Formal Spec (TLA+/PlusCal or Z3Py)
      ↓
Run Model Checker (TLC, Z3, or Apalache)
      ↓
  ┌── Pass → All invariants hold → Implement in code
  └── Fail → Counterexample trace
              ↓
        Analyze: Is the bug in the spec or the design?
              ↓
        Fix the DESIGN (not just the spec)
              ↓
        Update spec → Re-run checker → Loop
```

## Step 1: Extract State Machine

From requirements or ACs, identify:
- **States**: What are the possible states? (e.g., pending, processing, completed, failed)
- **Transitions**: What events cause state changes?
- **Actors**: Who/what can trigger transitions? (concurrent?)
- **Invariants**: What must ALWAYS be true? What must NEVER happen?
- **Liveness**: What must EVENTUALLY happen?

## Step 2: Write Spec

Default to PlusCal (translates to TLA+ automatically, more readable).
Use Z3Py when the problem is constraint-based rather than state-based.

Keep models SMALL:
- 2-3 actors, not 100
- 3-5 states per actor
- Small value domains (amounts: {0, 1, 2}, not arbitrary integers)

Small models find most bugs. State explosion kills verification.

## Step 3: Run and Interpret

```bash
# TLC (TLA+ model checker)
tlc spec.tla -config spec.cfg 2>&1 | head -50

# Z3Py
python3 verify.py

# Apalache (symbolic, handles larger state spaces)
apalache-mc check --config=spec.cfg spec.tla
```

### Reading Counterexamples

TLC counterexamples show a sequence of states violating an invariant.
Read them as "here's exactly how your design breaks":

```
State 1: actor1 = "idle", actor2 = "idle", balance = 100
State 2: actor1 = "withdrawing", balance = 100  (actor1 starts withdrawal)
State 3: actor2 = "withdrawing", balance = 100  (actor2 starts withdrawal — CONCURRENT!)
State 4: actor1 = "done", balance = 0           (actor1 completes)
State 5: actor2 = "done", balance = -100         (INVARIANT VIOLATED: balance >= 0)
```

## Step 4: Fix the Design

The counterexample reveals a design flaw, not a coding bug.
Common fixes:
- Add synchronization (lock, compare-and-swap, optimistic concurrency)
- Reorder operations (check-then-act → atomic operation)
- Add preconditions (guard transitions)
- Change the protocol (different state machine)

## When to Stop

- All safety invariants pass (no counterexamples)
- Liveness properties verified (no deadlocks)
- Model covers the interesting state space (review with domain expert)
- You understand WHY it's correct, not just that TLC says so

## Anti-Patterns

- Writing specs that match the code instead of the requirements
- Making the model too large (state explosion, hours of checking)
- Fixing the spec to pass instead of fixing the design
- Skipping the "extract state machine" step (jumping to TLA+ without understanding)
- Using formal verification for CRUD (overkill — save for concurrent/distributed)
