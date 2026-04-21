# Receipt Contract (spellbook)

`/deliver` communicates with its caller — human or `/flywheel` outer
loop — exclusively via exit code and `receipt.json`. No stdout
parsing, no heuristic sniffing.

## Path

- Default:
  `<worktree-root>/.spellbook/deliver/<ulid>/receipt.json`
- Override: `--state-dir <path>`; `/flywheel` uses
  `backlog.d/_cycles/<ulid>/evidence/deliver/`.

The entire `.spellbook/` tree is gitignored; the pre-commit hook
additionally refuses force-adds of `receipt.json`.

## Schema

```json
{
  "schema_version": 1,
  "ulid": "01JXXX...",
  "item_id": "023-review-score-feedback-loop",
  "branch": "feat/023-review-score-feedback-loop",
  "base_sha": "c945f5f...",
  "head_sha": "def456...",
  "status": "merge_ready | clean_loop_exhausted | phase_failed | aborted",
  "phases": [
    {"name": "shape",     "status": "ok"},
    {"name": "implement", "status": "ok"},
    {"name": "review",    "status": "dirty", "iteration": 3, "blocking_count": 2, "verdict_ref": "refs/verdicts/feat/023-review-score-feedback-loop"},
    {"name": "ci",        "status": "ok", "gates_run": 12, "self_heals": 1},
    {"name": "refactor",  "status": "ok"}
  ],
  "evidence": {
    "review_dir": "<state-dir>/review/",
    "ci_dir": "<state-dir>/ci/",
    "review_scores_line": ".groom/review-scores.ndjson:L<N>",
    "verdict_ref": "refs/verdicts/feat/023-review-score-feedback-loop"
  },
  "remaining_work": ["review: 2 blocking findings in ci/src/spellbook_ci/main.py"],
  "recommended_next": "fix-and-resume | abandon | human-review",
  "cost_usd": 2.80
}
```

Note: no `qa_dir` field. There is no `/qa` phase in the spellbook
clean loop.

## Exit Codes

| Code | Meaning | Receipt `status` |
|---|---|---|
| 0 | Merge-ready | `merge_ready` |
| 10 | Phase handler hard-failed (Dagger engine down, missing tool, crash) | `phase_failed` |
| 20 | Clean loop exhausted (3 iterations, still dirty) | `clean_loop_exhausted` |
| 30 | User/SIGINT abort | `aborted` |
| 40 | Invalid args / missing dependency skill | `phase_failed` |
| 41 | Double-invoke: item already delivered (state exists, `merge_ready`) | `phase_failed` |

## State Lifecycle

```
  ┌────────┐   phase ok    ┌────────────┐
  │ shape  │──────────────▶│ implement  │──────────▶ (clean loop)
  └────────┘               └────────────┘                │
       │                        │                        │
       │ phase fail             │ phase fail             ▼
       ▼                        ▼                   all green
  exit 10                  exit 10                  exit 0 (merge_ready)
                                                         │
                                 clean loop, cap hit     │
                                 exit 20                 │
                                                         ▼
                                                   receipt.json
```

`status` transitions are monotonic — once `merge_ready` is written,
the state is frozen. Re-invoking on the same item returns exit 41.

## Caller Consumption

- **Human:** `cat <state-dir>/receipt.json | jq` — read `status`,
  `remaining_work`, `recommended_next`. If ready, optionally push
  and run `scripts/land.sh` (which enforces `refs/verdicts/<branch>`
  + `dagger call check --source=.` via `.githooks/pre-merge-commit`).
- **`/flywheel` outer loop:** reads `receipt.json`, emits one
  `deliver.done` event. Exit 0 → proceed to its own deploy/monitor
  phases (spellbook currently has no deploy target, so `/flywheel`'s
  deploy is a no-op per the repo brief). Non-zero → halt cycle with
  `phase.failed` event.
