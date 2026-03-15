# Apalache: Symbolic Model Checking

When TLC hits state explosion, Apalache uses SMT solving for bounded model checking.

## When to Use Apalache Over TLC

| Situation | Tool |
|-----------|------|
| Small state space (<10M states) | TLC (exhaustive) |
| Large state space, bounded depth | Apalache (symbolic) |
| Infinite-state systems | Apalache (with bounds) |
| Quick smoke test | TLC with small constants |
| Proof of bounded correctness | Apalache |

## Type Annotations

Apalache requires type annotations (TLC doesn't):

```tla
VARIABLES
  \* @type: Str;
  state,
  \* @type: Int;
  retries,
  \* @type: Bool;
  refunded
```

## Running Apalache

```bash
# Type check first
apalache-mc typecheck spec.tla

# Bounded model check (10 steps)
apalache-mc check --length=10 --config=spec.cfg spec.tla

# Check specific invariant
apalache-mc check --length=10 --inv=NoDoubleCharge spec.tla
```

## SMT Pipeline

```
TLA+ spec → Apalache → SMT formulas → Z3 → SAT/UNSAT
```

Apalache translates TLA+ to SMT automatically. You get the best of both:
- TLA+ readability and state machine modeling
- Z3 symbolic solving power

## Practical Workflow

1. Write spec in TLA+/PlusCal (same as for TLC)
2. Add type annotations for Apalache
3. Test with TLC first (small constants, fast feedback)
4. Switch to Apalache when TLC is too slow or state space is too large
5. Use `--length=N` to bound exploration depth
