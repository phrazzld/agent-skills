---
name: finances-snapshot
disable-model-invocation: true
description: |
  Capture current financial state into the append-only ledger at ~/Documents/finances/.
  Updates prices (BTC, gold, silver), reads current balance sheet CSVs, and appends
  a timestamped snapshot to data/snapshots.jsonl and data/liabilities.jsonl.
  Use when: updating financial records, after exporting new balance sheets, weekly or
  monthly financial check-ins, tracking net worth. Keywords: net worth, balance sheet,
  snapshot, financial update, update finances, capture finances, record net worth.
user-invocable: true
---

# finances-snapshot

Capture current financial state and update prices.

## Steps

1. Fetch latest prices:
   ```bash
   cd ~/Documents/finances && uv run python scripts/fetch_prices.py
   ```
2. If balance sheet CSVs are stale: ask user to export fresh ones from Copilot Money and drop them in ~/Documents/finances/
3. Capture snapshot:
   ```bash
   uv run python scripts/snapshot.py
   ```

## What Gets Updated

- `data/prices/btc.jsonl` — latest BTC price from CoinGecko
- `data/prices/gold.jsonl` — gold spot via yfinance (GC=F)
- `data/prices/silver.jsonl` — silver spot via yfinance (SI=F)
- `data/snapshots.jsonl` — new net worth entry (assets, liabilities, BTC, breakdown)
- `data/liabilities.jsonl` — current liability balances with APRs

## Idempotent

Running twice on the same day is safe — snapshot.py skips if today already exists.
