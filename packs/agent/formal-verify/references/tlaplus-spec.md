# TLA+ / PlusCal Specifications

Writing formal specs from requirements and acceptance criteria.

## PlusCal First

PlusCal is pseudocode that compiles to TLA+. Start here.

```
---- MODULE PaymentFlow ----
EXTENDS TLC, Integers, Sequences

CONSTANTS MaxRetries

(*--algorithm PaymentFlow
variables
  state = "pending",
  retries = 0,
  refunded = FALSE;

process payment = "payment"
begin
  Process:
    while state \notin {"completed", "failed"} do
      either
        \* Attempt charge
        if retries < MaxRetries then
          either
            state := "completed";  \* Success
          or
            retries := retries + 1;  \* Retry
          end either;
        else
          state := "failed";  \* Max retries exceeded
        end if;
      or
        \* Refund requested
        if state = "completed" /\ ~refunded then
          refunded := TRUE;
        end if;
      end either;
    end while;
end process;

end algorithm; *)

\* Invariants
TypeOK ==
  /\ state \in {"pending", "completed", "failed"}
  /\ retries \in 0..MaxRetries
  /\ refunded \in {TRUE, FALSE}

NoRefundBeforeCompletion ==
  refunded => state = "completed"

RetriesWithinBounds ==
  retries <= MaxRetries

====
```

## AC → Invariant Translation

| Acceptance Criteria | TLA+ Invariant |
|---------------------|---------------|
| "Payment must never be charged twice" | `ChargeCount <= 1` |
| "Balance must never go negative" | `balance >= 0` |
| "Every request must eventually complete" | Liveness: `<>(state = "completed" \/ state = "failed")` |
| "Refund only after successful charge" | `refunded => state = "completed"` |
| "At most N retries" | `retries <= MaxRetries` |

## Config File Template

```
SPECIFICATION Spec
CONSTANTS MaxRetries = 3
INVARIANT TypeOK
INVARIANT NoRefundBeforeCompletion
INVARIANT RetriesWithinBounds
```

## Small Model Discipline

| Domain | Small Model | Real World |
|--------|-------------|------------|
| Actors | 2-3 | Thousands |
| States per actor | 3-5 | Many |
| Value range | {0, 1, 2} | Arbitrary |
| Queue depth | 2-3 | Unbounded |

Most concurrency bugs manifest with 2 actors and 3 states.
If TLC runs >60s, your model is too big. Shrink it.

## Running

```bash
# Translate PlusCal to TLA+
pcal spec.tla

# Run model checker
tlc spec.tla -config spec.cfg -workers auto

# Common flags
tlc spec.tla -config spec.cfg -deadlock  # check for deadlocks
tlc spec.tla -config spec.cfg -depth 30  # bound exploration depth
```
