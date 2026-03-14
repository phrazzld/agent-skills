# Z3 Constraint Verification

Using Z3Py for constraint solving and bounded verification.

## When to Use Z3 vs TLA+

| Problem Shape | Tool |
|---------------|------|
| State machine, protocol, concurrency | TLA+ |
| Constraints, invariants, satisfiability | Z3 |
| "Can these conditions all be true simultaneously?" | Z3 |
| "Does this sequence of events violate safety?" | TLA+ |
| Scheduling, resource allocation, configuration | Z3 |

## Z3Py Skeleton

```python
from z3 import *

# Declare variables
balance = Int('balance')
charge_amount = Int('charge_amount')
refund_amount = Int('refund_amount')

s = Solver()

# Constraints from requirements
s.add(balance >= 0)                    # Balance never negative
s.add(charge_amount > 0)              # Charges are positive
s.add(refund_amount <= charge_amount)  # Can't refund more than charged

# Try to violate an invariant
s.add(balance - charge_amount + refund_amount < 0)  # Can balance go negative?

result = s.check()
if result == sat:
    m = s.model()
    print(f"COUNTEREXAMPLE: balance={m[balance]}, charge={m[charge_amount]}, refund={m[refund_amount]}")
    print("Design flaw: balance can go negative under these conditions")
elif result == unsat:
    print("VERIFIED: balance cannot go negative under these constraints")
    # Get unsat core for minimal explanation
    # (requires named assertions — see below)
else:
    print("UNKNOWN: solver could not determine")
```

## Unsat Cores as Fix Guidance

When Z3 proves UNSAT (your invariant holds), the unsat core tells you
which constraints are load-bearing:

```python
s = Solver()

# Name each constraint
c1 = Bool('balance_positive')
c2 = Bool('charge_positive')
c3 = Bool('refund_bounded')

s.assert_and_track(balance >= 0, c1)
s.assert_and_track(charge_amount > 0, c2)
s.assert_and_track(refund_amount <= charge_amount, c3)

s.add(balance - charge_amount + refund_amount < 0)

if s.check() == unsat:
    core = s.unsat_core()
    print(f"These constraints prevent the violation: {core}")
    # Output: [balance_positive, refund_bounded]
    # → If you remove either constraint, the bug appears
```

## Bounded Verification

Z3 doesn't enumerate states — it solves constraints symbolically.
For state sequences, unroll the state machine:

```python
# Verify 3 steps of a protocol
for step in range(3):
    state = Int(f'state_{step}')
    s.add(state >= 0, state <= 4)
    if step > 0:
        prev = Int(f'state_{step-1}')
        # Transition constraints
        s.add(Or(
            And(prev == 0, state == 1),  # idle → processing
            And(prev == 1, state == 2),  # processing → completed
            And(prev == 1, state == 3),  # processing → failed
        ))

# Check: can we reach state 4 (invalid)?
s.add(Int('state_2') == 4)
print("Reachable" if s.check() == sat else "Unreachable")
```

## Integration with Agent Loop

1. Agent translates ACs to Z3 constraints
2. Z3 checks satisfiability
3. If SAT (counterexample exists) → agent fixes design
4. If UNSAT → invariant holds, proceed to implementation
5. Unsat core guides which constraints are essential
