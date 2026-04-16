---
name: flywheel
description: |
  Outer-loop delivery orchestrator. Composes cycles of /deliver → /deploy →
  /monitor → /diagnose → /reflect, mutates the backlog, and emits harness
  suggestions to a branch. Inner loop is /deliver (one ticket → merge-ready,
  a black box here). Outer loop is this: continuous, unattended, budgeted.
  Every run ends with a tight shipping brief plus a full /reflect session.
  Use when: continuous delivery, "flywheel", "run the outer loop",
  "next N items", "overnight queue", "outer loop", "cycle".
  Trigger: /flywheel.
argument-hint: "[--max-cycles N] [--budget $N] [--unattended] [--dry-run]"
---

# /flywheel

Outer-loop delivery orchestrator. `/deliver` takes one item to merge-ready
and exits (inner loop). `/flywheel` composes cycles of `/deliver` +
`/deploy` + `/monitor` + `/diagnose` + `/reflect` and runs N of them.

Two skills, two stop conditions, one composition contract:
- `/deliver` (inner) — single-shot, interactive, ends at merge-ready.
- `/flywheel` (outer) — continuous, unattended, ends on predicate/budget.

OpenHands inner-loop vs outer-loop distinction is load-bearing. Do not
grow one into the other.

## Execution Stance

You are the executive orchestrator.
- Keep work selection, stop judgment, and cycle close/abandon on the lead model.
- Delegate each phase to its named skill; never inline phase logic here.
- Treat `/deliver` as an opaque merge-readiness step. Consume exit code +
  receipt; escalate disagreement.
- Treat the event log as the source of truth — every phase boundary writes
  an event via `flywheel.sh emit`.

## Real Mode — Cycle Orchestration

The MODEL drives the outer loop by invoking script subcommands. The script
provides state primitives; the model provides judgment.

```
1. Mint cycle:
   cycle_id=$(bash skills/flywheel/scripts/flywheel.sh new-cycle --budget $BUDGET)

2. Pick item:
   item=$(bash skills/flywheel/scripts/flywheel.sh pick $cycle_id)
   If EMPTY → close noop, exit 0.

3. Invoke /deliver $item --state-dir backlog.d/_cycles/$cycle_id/evidence/deliver/
   - On exit 0: read receipt.json; emit deliver.done with cost_usd, branch, head_sha.
   - On non-zero: emit phase.failed, close aborted, STOP this cycle.
   bash skills/flywheel/scripts/flywheel.sh emit $cycle_id deliver.done \
     deliver builder '{"cost_usd":<x>,"branch":"<b>","head_sha":"<s>"}'

4. Invoke /deploy; parse receipt; emit:
   bash skills/flywheel/scripts/flywheel.sh emit $cycle_id deploy.done \
     deploy deployer '<receipt_json>'

5. Invoke /monitor; consume its one terminal event.
   - monitor.done → proceed to step 7.
   - monitor.alert → go to step 6.
   bash skills/flywheel/scripts/flywheel.sh emit $cycle_id monitor.done \
     monitor monitor '<payload>'

6. (If alert) Invoke /diagnose; emit:
   bash skills/flywheel/scripts/flywheel.sh emit $cycle_id triage.done \
     triage diagnostician '<payload>'

7. Invoke /reflect cycle $cycle_id; emit:
   bash skills/flywheel/scripts/flywheel.sh emit $cycle_id reflect.done \
     reflect reflector '<payload_with_new_items>'

8. Update bucket (shipped or failed):
   bash skills/flywheel/scripts/flywheel.sh update-bucket $cycle_id shipped

9. Suggest harness changes:
   bash skills/flywheel/scripts/flywheel.sh update-harness $cycle_id

10. Close cycle:
    bash skills/flywheel/scripts/flywheel.sh close $cycle_id closed

11. If --max-cycles > 1 and budget remains and no stop predicate triggered:
    GOTO 1.
```

After cycle(s), emit operator-facing shipping brief + full /reflect session
(see Closeout Contract).

## Flags

| Flag | Purpose |
|------|---------|
| `--max-cycles N` | Hard count of cycles (default 1) |
| `--budget $N` | Cumulative model cost ceiling |
| `--unattended` | No-TTY mode; requires `--budget` |
| `--dry-run` | Walk phases, write 8-event trail, invoke nothing |
| `--until <pred>` | Stop predicate — Phase 2b (exits 2) |
| `--resume <ulid>` | Resume paused cycle — Phase 2b (exits 2) |
| `--abandon <ulid>` | Mark abandoned — Phase 2b (exits 2) |

Unattended without `--budget` exits 2: `flywheel: unattended mode requires
--budget <usd>`. Default interactive cap is $5 USD.

## Subcommands

| Subcommand | Purpose |
|------------|---------|
| `new-cycle [--budget $X] [--unattended]` | Acquire lock, mint ULID, write manifest, emit cycle.opened. stdout: `<ulid>` |
| `pick <cycle_id>` | Deterministic eligibility filter + scoring. stdout: `<item_id>` or `EMPTY` |
| `emit <cycle_id> <kind> <phase> <agent> <payload>` | Validated event write; sums cost_usd; triggers budget.exhausted at 95% |
| `close <cycle_id> <status> [<reason>]` | Emit cycle.closed, update manifest, release lock |
| `update-bucket <cycle_id> <ship_status>` | Backlog mutation (move on shipped, stamp on failed). Idempotent |
| `update-harness <cycle_id>` | Emit harness.suggested (Phase 2b: branch mechanics) |
| `budget <cycle_id>` | stdout: manifest budget block as JSON |
| `status [<cycle_id>]` | Human-readable cycle state |
| `run [flags]` | Drive the outer loop (--dry-run or real). Accepts --max-cycles |

## Artifacts Per Cycle

```
backlog.d/_cycles/<ulid>/
├── cycle.jsonl        # append-only typed events (the event log)
├── evidence/          # QA artifacts, review transcripts, diffs
│   └── deliver/       # /deliver state dir when invoked by /flywheel
└── manifest.json      # full cycle state with budget accounting
```

## Event Schema

Closed enum — 12 kinds. Unknown kinds fail at emit time.

| Kind | When |
|------|------|
| `cycle.opened` | Cycle starts (new-cycle) |
| `deliver.done` | /deliver exits 0 |
| `deploy.done` | /deploy completes |
| `monitor.done` | /monitor: clean |
| `monitor.alert` | /monitor: regression detected |
| `triage.done` | /diagnose completes |
| `reflect.done` | /reflect cycle completes |
| `bucket.updated` | update-bucket mutates backlog |
| `harness.suggested` | update-harness emits suggestion |
| `phase.failed` | Any phase returns non-zero |
| `budget.exhausted` | spent_usd >= cap_usd * 0.95 |
| `cycle.closed` | Cycle ends (any status) |

Inner-pipeline events (`shape.done`, `build.done`, etc.) live inside
`/deliver` — `/flywheel` sees one `deliver.done` per cycle.

## Closeout Contract

Every `/flywheel` run ends with:
1. A tight shipping brief (what changed, why, value, verified, residual risk).
2. A full `/reflect` session.

For multi-cycle runs: one brief per cycle, then one aggregate summary.
`/reflect` is mandatory; do not collapse it into the brief.

## Lock Semantics

`.spellbook/flywheel.lock` holds `{pid, cycle_id, started_at}`. Stale locks
(owner pid dead) are stolen atomically. SIGINT → exit 130. SIGTERM → exit 143.

## Gotchas

- **Never run two /flywheel in the same worktree.** Lock enforces it.
- **Inner loop is a black box.** Consume exit code + receipt only.
- **emit validates kinds.** Do not invent kinds inline; update EVENT_KINDS
  in `scripts/lib/events.sh` and every consumer.
- **budget.exhausted fires at 95%.** Finish current phase first. The 5%
  headroom absorbs metering lag.
- **update-bucket is idempotent.** Guards every mutation with cycle_id grep.
  Re-running is safe; it detects the marker and no-ops.
- **harness.suggested writes to a branch only** (never main). Phase 2b wires
  the branch mechanics; Phase 2a emits a placeholder event.
- **Never auto-merge.** `/flywheel` never opens, approves, or merges a PR.
- **Paths anchor to REPO_ROOT.** flywheel.sh cds to the repo root on startup.
  Override FLYWHEEL_LOCK_PATH with an absolute path.

## References

See `backlog.d/028-flywheel-outer-loop-orchestrator.md` for:
- Full eligibility filter and scoring formula (`pick`)
- Manifest schema and budget accounting
- Resume & abandon semantics (Phase 2b)
- Durability guarantees (D1–D5)
- update-bucket mutation grammar
- update-harness branch mechanics (Phase 2b)
- Stopping predicates (`--until`)
- Worktree behavior
