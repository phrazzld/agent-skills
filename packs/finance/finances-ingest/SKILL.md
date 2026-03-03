---
name: finances-ingest
disable-model-invocation: true
description: |
  Parse new financial exports into the append-only ledger at ~/Documents/finances/.
  Handles: BofA CSV, Strike annual statement, River activity CSV, Robinhood CSV,
  Copilot Money transactions export. Deduplicates automatically (safe to re-run).
  Updates source_coverage.json with date ranges and account coverage.
  Use when: new export files are available, adding new transaction history, updating
  financial records from bank/broker/crypto exports. Keywords: ingest, import, parse,
  new transactions, add transactions, financial data, export, csv import, bank statement.
user-invocable: true
---

# finances-ingest

Parse new source files into the normalized transaction ledger.

## Quick Start

1. Drop new export files into `~/Documents/finances/source/` subdirectory:
   - Bank exports → `source/bank/`
   - Crypto exports → `source/crypto/`
   - Brokerage exports → `source/brokerage/`
   - Or sync from Moneta: `uv run python scripts/sync_moneta.py`
2. Run ingest:
   ```bash
   cd ~/Documents/finances && uv run python scripts/ingest.py
   ```

## Supported Sources

| Source | File pattern | Target |
|--------|-------------|--------|
| BofA | `source/bank/bofa*.csv` | `data/transactions/bofa.jsonl` |
| Strike | `source/crypto/strike*.csv` | `data/transactions/strike.jsonl` |
| River | `source/crypto/river*.csv` | `data/transactions/river.jsonl` |
| Robinhood | `source/brokerage/robinhood*.csv` | `data/transactions/robinhood.jsonl` |

Note: Copilot transactions are ingested via `scripts/backfill.py` (one-time) or by
dropping new exports in the root of ~/Documents/finances/.

## Deduplication Rules

- Transaction IDs: `sha256(source+date+amount+description)[:16]` — deterministic
- Re-ingesting the same file is always safe — duplicates are counted and skipped
- Copilot is the primary source for banking (BofA checking, Apple Card, Apple Cash,
  Apple Savings). The raw BofA CSV is supplemental detail — don't double-count spend.

## Flags

```bash
uv run python scripts/ingest.py --dry-run        # Count without writing
uv run python scripts/ingest.py --source bofa    # Single source only
```

## After Ingest

Run `/finances-report` to see updated analytics with the new data.
