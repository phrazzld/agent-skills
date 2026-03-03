---
name: crypto-gains
disable-model-invocation: true
description: |
  Calculate capital gains with FIFO, wash sale detection, term classification, and Form 8949 outputs.
user-invocable: true
---

# /crypto-gains

Calculate capital gains with IRS-compliant rules.

## Steps

1. Load lots from `normalized/cost-basis.json` and transactions from `normalized/transactions.json`.
2. Build sell list and allocate FIFO lots per asset.
3. Classify each gain as short-term or long-term by holding period.
4. Detect wash sales within 30 days for securities. Mark crypto as not applicable per current policy.
5. Write gains to `normalized/capital-gains.json` and updated lots to `normalized/cost-basis-updated.json`.
6. Generate Form 8949 outputs and summaries.

## Examples

```bash
# Build FIFO gains and updated lots
pnpm gains
```

```bash
# Generate Form 8949 and tax summaries
pnpm report
```

## References

- `normalized/transactions.json`
- `normalized/cost-basis.json`
- `normalized/capital-gains.json`
- `normalized/cost-basis-updated.json`
- `reports/tax-ready/form-8949-c.csv`
- `reports/tax-ready/turbotax-import.csv`
- `reports/tax-ready/schedule-d-summary.md`
- `scripts/calculate-gains.ts`
- `scripts/generate-report.ts`
