# `/autopilot` — outer delivery loop (formerly `/iterate`)

Priority: high
Status: in-progress (Phase 1 shipped under old name `/iterate`)
Estimate: L (MVP ~5 dev-days; Phase 1 done, Phase 2+ ahead)

## Rename

Formerly `/iterate`. The outer loop is the *actually* autonomous skill —
multi-cycle, unattended, budgeted, cross-cycle learning. The name
`/autopilot` belongs to this, not to the inner single-ticket pipeline.

- Old `/autopilot` (single-shot ticket delivery) → renamed to `/deliver` (see 032)
- Old `/iterate` (this skill) → renamed to `/autopilot`
- Naming swap tracked in 032. This ticket refers to the new meaning throughout.

## Goal

Close the delivery loop. `/deliver` ships one item to merge-ready code and
exits. `/autopilot` picks items, delivers them, deploys, monitors, triages,
reflects, updates the backlog + harness, and picks the next. It composes
existing skills as phase handlers — it does not reimplement phases.

OpenHands inner-loop vs outer-loop distinction is load-bearing. `/deliver`
is inner (single-shot, interactive). `/autopilot` is outer (continuous,
unattended).

## Why Not Grow `/deliver`

Conflating single-shot delivery with continuous operation forces `/deliver`
to grow deploy + monitor + retro + bucket-rewrite + budget logic it
shouldn't own. Two skills, two clear stop conditions, one composition
contract.

## Composition Contract

```
/autopilot [--max-cycles N] [--budget $X] [--until <pred>]
    │
    ▼
  acquire .spellbook/autopilot.lock
    │
    ▼
┌── CYCLE START ───────────────────────────────┐
│  1. pick        → bucket-scorer / read top   │  cycle.opened
│  2. deliver     → /deliver (full inner loop) │  deliver.done (≡ merge-ready)
│  3. deploy      → /deploy                    │  deploy.done
│  4. monitor     → /monitor                   │  monitor.done | monitor.alert
│  5. triage      → /investigate (if alert)    │  triage.done
│  6. reflect     → /reflect (session+harness) │  reflect.done
│  7. update-bucket → backlog mutation         │  bucket.updated
│  8. update-harness → branch-only suggestion  │  harness.suggested
└── CYCLE CLOSED ──────────────────────────────┘
    │
    ▼
  stop? (predicate / max-cycles / budget / SIGINT) → next cycle or exit
```

`/deliver` itself loops shape → implement → code-review → ci → refactor
→ qa → evidence internally (see 032). `/autopilot` treats `/deliver` as a
black-box merge-readiness step.

## State Model

One cycle = one bucket item worked end-to-end. Each cycle gets a ULID:

```
backlog.d/_cycles/<ulid>/
├── cycle.jsonl        # typed event log (see events.sh)
├── evidence/          # QA artifacts, review transcripts, diffs
└── manifest.json      # {item_id, branch, claim, started, closed, status}
```

### Event Schema

Typed envelope in `scripts/lib/events.sh`. Closed enum of kinds; writes
with unknown kinds fail. JSONL corruption breaks `/reflect`, so writes are
`flock`'d and `fsync`'d.

Kinds: `cycle.opened`, `deliver.done`, `deploy.done`, `monitor.done`,
`monitor.alert`, `triage.done`, `reflect.done`, `bucket.updated`,
`harness.suggested`, `phase.failed`, `budget.exhausted`, `cycle.closed`.

**Note:** the per-phase kinds from the old iterate spec (`shape.done`,
`build.done`, `review.iter`, `ci.done`, `qa.done`) move inside `/deliver`
and are no longer emitted at the `/autopilot` level — `/autopilot` sees
one `deliver.done` event. Drops cross-cycle noise.

### Stopping Predicates

- `--until "backlog empty"` — no eligible items
- `--until "P0 closed"` — highest-priority item shipped
- `--max-cycles N` — hard count
- `--budget $N` — cumulative model cost (tracked in manifest.json)

Unattended mode requires `--budget`. `/autopilot` refuses without it.

## Components

| Component | Status | Owns |
|---|---|---|
| `skills/autopilot/SKILL.md` | rename from iterate | Orchestration, event writing, lock, budget, stop predicates |
| `scripts/lib/events.sh` | ✓ shipped (was daybook.sh) | `emit_event` — atomic JSONL append with fsync |
| `scripts/lib/iterate_lock.sh` | ✓ shipped | Single-instance lock (rename file to `autopilot_lock.sh`) |
| `/deliver` | 032 — rename autopilot + compose | Full inner pipeline to merge-ready |
| `/deploy` | 035 — new | Ship to environment |
| `/monitor` | 036 — new | Post-deploy signal watch + escalate |
| `/investigate` | ✓ exists | Triage on monitor.alert |
| `/reflect` | 037 — upgrade | Session + bucket + harness critique |

## Failure Modes

| Failure | Recovery |
|---|---|
| Phase handler fails | `phase.failed` event, stop cycle, keep lock until `--resume <ulid>` or `--abandon <ulid>` |
| Monitor flags anomaly | `monitor.alert` → triage → remediation or `phase.failed` |
| Budget exceeded mid-cycle | Finish current phase, `budget.exhausted`, stop |
| Event log write fails | Fatal — fsync every event; corrupted JSONL breaks reflect |
| Two `/autopilot` attempts | Second exits on lock |
| `/deliver` internal fail | Bubble up; cycle fails; no auto-retry (prevents cost spiral) |

## Phase Plan

**Phase 1 — shipped on `feat/iterate-mvp-phase1` under old name `/iterate`:**
- Dry-run walk of all phases
- Typed event log (`events.sh`, formerly `daybook.sh`)
- Single-instance lock with stale-pid steal
- Single-cycle guard (`--max-cycles > 1` exits 2)
- 27 regression tests

**Phase 2 — rename + real handlers (~3-4 dev-days):**
1. Rename `/iterate` → `/autopilot` (mechanical, after 032 renames old `/autopilot` → `/deliver`)
2. Update event kinds to new composition (drop inner-phase kinds)
3. Wire `/deliver`, `/deploy`, `/monitor`, `/investigate`, `/reflect` handlers
4. Multi-cycle control flow with stop predicates
5. Budget tracking in manifest.json

**Phase 3 — unattended ops (~2 dev-days):**
- `--resume <ulid>` / `--abandon <ulid>`
- `harness.suggested` writing to `harness/auto-tune` branch
- Spellbook dogfoods on itself

## Oracle

- [ ] `/autopilot --max-cycles 1` runs pick → deliver → deploy → monitor → reflect → bucket-update on a real backlog item
- [ ] Cycle event log contains ≥6 typed events, all valid against schema
- [ ] `/autopilot` refuses unattended without `--budget`
- [ ] Second `/autopilot` invocation while first holds lock exits non-zero
- [ ] SIGINT releases lock; `--resume` continues from last completed phase
- [ ] `/deliver` runs its own internal loop (shape/implement/review/ci/qa) and returns merge-ready state
- [ ] `monitor.alert` triggers `/investigate` automatically
- [ ] `harness.suggested` events write to `harness/auto-tune` branch only, never main
- [ ] Spellbook dogfoods on itself (one cycle, one backlog item)

## Non-Goals

- Dynamic philosophy bench classifier — static globs first (see 030)
- GEPA auto-tuner — defer until ≥20 cycles of signal (031)
- Model Council at reflect — too expensive for MVP; shape only
- MAR-style multi-reflector — single reflect pass in MVP
- Merging PRs automatically — humans merge; loop suggests only
- Unattended mode without explicit `--budget`
- Tailored per-repo skills — separate initiative (029 needs rework)

## Related

- Depends on: 022 (swarm review default), 025 (dagger merge gate), 032 (`/deliver` rename + recompose), 035 (`/deploy`), 036 (`/monitor`), 037 (`/reflect` upgrade)
- Sibling: 030 (static bench-map), 024 (evidence storage)
- Unlocks: 031 (harness auto-tune — parked until cycles produce signal)
- Supersedes: old `/autopilot` continuous-mode speculation

## Name Collision Notes

- `/autopilot` (new meaning) free once 032 renames the current skill
- Env var: `AUTOPILOT_MODE=1` (was `ITERATE_MODE=1`) — change as part of Phase 2
- Lock file: `.spellbook/autopilot.lock` (was `.spellbook/iterate.lock`)
