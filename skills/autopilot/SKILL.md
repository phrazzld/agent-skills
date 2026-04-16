---
name: autopilot
description: |
  Outer-loop delivery orchestrator. Composes cycles of /deliver → /deploy →
  /monitor → /investigate → /reflect, mutates the backlog, and emits harness
  suggestions to a branch. Inner loop is /deliver (one ticket → merge-ready,
  a black box here). Outer loop is this: continuous, unattended, budgeted.
  Every run ends with a tight shipping brief plus a full /reflect session.
  Use when: continuous delivery, "autopilot", "run the outer loop",
  "next N items", "overnight queue", "outer loop", "cycle".
  Trigger: /autopilot.
argument-hint: "[--max-cycles N] [--budget $N] [--dry-run]"
---

# /autopilot

Outer-loop delivery orchestrator. `/deliver` takes one item to merge-ready
and exits (inner loop). `/autopilot` composes cycles of `/deliver` +
`/deploy` + `/monitor` + `/investigate` + `/reflect` and runs N of them
(outer loop).

Two skills, two stop conditions, one composition contract:
- `/deliver` (inner) — single-shot, interactive, ends at merge-ready.
- `/autopilot` (outer) — continuous, unattended, ends on predicate/budget.

OpenHands inner-loop vs outer-loop distinction is load-bearing. Do not
grow one into the other.

## Phase 1 Scope (current)

- Dry-run end-to-end walk of all phases
- Typed cycle events (`scripts/lib/events.sh`)
- Single-instance lock (`scripts/lib/autopilot_lock.sh`) with stale-pid steal
- **Single-cycle only.** Multi-cycle (`--max-cycles > 1`) is Phase 2; the
  current guard would release the lock between cycles and let a second
  autopilot sneak in. Passing `N != 1` exits 2 with a clear message.

**Not yet wired:** real handlers for `/deliver`, `/deploy`, `/monitor`,
`/investigate`, `/reflect`. Invoking without `--dry-run` writes a
`phase.failed` event and exits non-zero. That is intentional — Phase 1
proves the event/lock contract; Phase 2 wires the handlers.

Phase 2+ design (multi-cycle, budget accounting, resume/abandon, harness
auto-tune branch) is tracked in `backlog.d/028-iterate-outer-loop-orchestrator.md`.

## Execution Stance

You are the executive orchestrator.
- Keep work selection, stop judgment, and cycle close/abandon on the lead model.
- Delegate each phase to its named skill; never inline phase logic here.
- Treat `/deliver` as an opaque merge-readiness step. Do not re-implement
  its inner clean loop. Consume its exit code + receipt; escalate disagreement.
- Treat the event log as the source of truth — every phase boundary writes an event.

## Closeout Contract

Every `/autopilot` run ends with two operator-facing outputs, in this order:
1. A tight shipping brief.
2. A full `/reflect` session.

The shipping brief is short and punchy. It is not a file inventory, a raw
changelog, or a generic "tests passed" recap. Default shape: 1-2 short
paragraphs or 4-6 flat bullets.

The shipping brief must answer:
- What ticket was selected and what changed.
- What value the ticket adds, and why shipping it is useful and important now.
- What alternatives to the implemented design existed.
- Why the implemented design is best under the current constraints. If it is
  not clearly best, say so plainly and explain why it was still the right
  choice to ship.
- What value the change creates for developers and operators.
- What value the change creates for users or customers.
- What was verified, and what residual risk remains.

`/reflect` remains mandatory. Do not collapse reflection into the shipping
brief. The brief explains the shipped decision; `/reflect` captures the
learnings, harness changes, and follow-on mutations.

For future multi-cycle runs, emit this brief per cycle and then emit one final
aggregate summary across the whole session.

## Flags

| Flag | Purpose | Phase |
|------|---------|-------|
| `--max-cycles N` | Hard count of cycles. **Phase 1 requires N=1**; any other value exits 2 | 1 (N=1 only) |
| `--budget $N` | Cumulative model cost ceiling | Phase 2 — inert in Phase 1 (single-cycle never exhausts) |
| `--dry-run` | Walk phases, write events, invoke nothing | 1 |
| `--until <pred>` | Stop predicate ("backlog empty", "P0 closed") | 2 |
| `--resume <ulid>` | Resume a paused cycle from last completed phase | 2 |
| `--abandon <ulid>` | Mark cycle abandoned and release its lock | 2 |

`--max-cycles > 1` exits 2 with `autopilot: --max-cycles > 1 is Phase 2; not
yet implemented`. `--budget` is parsed for forward compatibility but has no
effect in Phase 1.

## Artifacts Per Cycle

```
backlog.d/_cycles/<ulid>/
├── cycle.jsonl        # append-only typed events (the event log)
├── evidence/          # QA artifacts, review transcripts, diffs, /deliver state
│   └── deliver/       # /deliver state dir when invoked by /autopilot
└── manifest.json      # {item_id, branch, started, closed, status}
```

`backlog.d/_cycles/` is intentionally preserved across the rename —
historical cycles stay readable and identifiable.

## Event Schema

Every event is one JSON line with this envelope:

```json
{
  "schema_version": 1,
  "ts": "2026-04-14T12:00:00Z",
  "cycle_id": "01HQ...",
  "kind": "cycle.opened",
  "phase": "shape",
  "agent": "planner",
  "refs": ["path/to/artifact"],
  "findings": [],
  "note": "free text"
}
```

`kind` is a closed enum — writes with unknown kinds fail at the script level.
JSONL corruption breaks `/reflect`, so writes are `flock`'d and `fsync`'d.

Current Phase 1 kinds (drawn from the pre-rename `/iterate` spec):
`cycle.opened`, `shape.done`, `build.done`, `review.iter`, `ci.done`,
`qa.done`, `deploy.done`, `reflect.done`, `harness.suggested`,
`phase.failed`, `budget.exhausted`, `cycle.closed`.

TODO(028 phase-2): drop inner-pipeline kinds (`shape.done`, `build.done`,
`review.iter`, `ci.done`, `qa.done`) once `/deliver` composition lands;
outer loop sees one `deliver.done` event per cycle. Add `deliver.done`,
`monitor.done`, `monitor.alert`, `triage.done`, `bucket.updated`.

## Control Flow

```
/autopilot [flags]
    │
    ▼
  acquire .spellbook/autopilot.lock  (fails if a live /autopilot holds it)
    │
    ▼
┌── CYCLE START ───────────────────────────────┐
│  1. pick        → deterministic selector     │  cycle.opened
│  2. deliver     → /deliver (inner loop)      │  deliver.done (Phase 2)
│  3. deploy      → /deploy                    │  deploy.done
│  4. monitor     → /monitor                   │  monitor.done | monitor.alert
│  5. triage      → /investigate (on alert)    │  triage.done
│  6. reflect     → /reflect on events         │  reflect.done
│  7. update-bucket → backlog mutation         │  bucket.updated
│  8. update-harness → harness.suggested       │  writes to PR branch only
└── CYCLE CLOSED ──────────────────────────────┘
    │
    ▼
  cycle done → release lock (Phase 1 runs exactly one cycle)
```

In Phase 1 the dry-run still walks the pre-rename 9-phase trail
(shape/build/review/ci/qa/deploy/reflect). Phase 2 collapses the inner
steps into a single `/deliver` invocation and a single `deliver.done` event.

## Invocation

```bash
# Dry-run a single cycle — writes phase events, invokes nothing.
bash skills/autopilot/scripts/autopilot.sh --dry-run

# Real mode (Phase 2+; currently writes phase.failed and exits 1)
bash skills/autopilot/scripts/autopilot.sh

# Multi-cycle is Phase 2 — this exits 2 in Phase 1.
bash skills/autopilot/scripts/autopilot.sh --max-cycles 5 --budget 20
```

## Lock Semantics

`.spellbook/autopilot.lock` holds `{pid, cycle_id, started_at}`. SIGINT, EXIT,
and TERM traps release the lock — scoped to the acquiring `cycle_id` so a
late trap from a prior cycle cannot wipe a successor's lock. Stale locks
(owner pid dead, or JSON corrupt) are stolen atomically via `O_CREAT|O_EXCL`.

Known limitations:
- **Pid recycling.** If the recorded pid is reused by an unrelated process,
  `kill -0` reports alive and acquire refuses. Manual recovery:
  `rm .spellbook/autopilot.lock`. A future revision may add `started_at`-based
  disambiguation.
- **`python-ulid` is optional.** When unavailable, the fallback emits real
  26-character Crockford base32 ULIDs (10 chars timestamp + 16 chars random),
  lexicographically sortable and interchangeable with the library output.
- **Paths anchor to REPO_ROOT.** `autopilot.sh` `cd`s to the spellbook repo
  root on startup so `backlog.d/_cycles/...` and the default lock path
  always land in the right tree even when invoked from outside the repo.
  If you override `AUTOPILOT_LOCK_PATH`, pass an absolute path.

## Stop Conditions (Phase 1)

- Cycle finishes normally → emit `cycle.closed`, release lock, exit 0
- Any phase returns non-zero → `phase.failed` event, release lock, exit 1
- SIGINT → trap releases lock, exit 130
- SIGTERM → trap releases lock, exit 143
- `--max-cycles > 1` → exit 2 before acquiring the lock (Phase 2 feature)
- Budget-exhausted mid-cycle is a Phase 2 stop condition (no-op in Phase 1)

## Gotchas

- **Never run two /autopilot in the same worktree.** The lock enforces it;
  tests verify. Two worktrees of the same repo can run concurrently —
  state anchors to REPO_ROOT of each worktree.
- **Inner loop is a black box.** `/deliver` owns shape/implement/review/
  ci/refactor/qa. Do not reach into its state or retry its internal
  clean loop from here — consume exit code + receipt, escalate disagreement.
- **Dry-run invokes nothing.** It exists to prove the event contract, not to
  rehearse phases. Do not use it as a cheap "preview".
- **Real mode has no handlers in Phase 1.** It writes `phase.failed` and
  exits 1 by design. Wiring is Phase 2.
- **Auto-scaffold is Phase 3.** If `/qa` or `/deploy` is missing when real
  mode lands, the cycle fails loudly — no silent scaffolding.
- **`harness.suggested` writes to a branch only** (never main). Phase 2
  emits the event and wires the branch write; Phase 1 dry-run does not emit
  it (would train the wrong mental model of the contract).
- **Never auto-merge.** `/autopilot` never opens, approves, or merges a PR.
  Humans merge. The harness auto-tune branch (Phase 3) requires CODEOWNERS
  review by design.
- **Closed-enum kinds.** Adding a new kind requires updating `EVENT_KINDS`
  in `events.sh` and every consumer — don't invent kinds inline.
