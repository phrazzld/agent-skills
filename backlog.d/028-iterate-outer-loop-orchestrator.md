# `/iterate` — outer-loop workflow orchestrator

Priority: high
Status: in-progress (Phase 1)
Estimate: L (MVP ~5 dev-days)
Aliases: `/cycle`

## Goal

Close the delivery loop. `/autopilot` ships one item and exits. `/iterate`
picks items, ships them, reflects, updates bucket + harness, and picks the
next. It does **not** reimplement phases — it composes existing skills as
phase handlers.

OpenHands inner-loop (IDE, ad-hoc) vs outer-loop (async delivery) distinction
is load-bearing. `/autopilot` stays inner. `/iterate` is the outer loop.

## Why Not Grow `/autopilot`

Conflating single-shot delivery with continuous operation forces autopilot
to grow retro + bucket-rewrite + budget logic it shouldn't own. Two skills,
two clear stop conditions, one composition contract.

## State Model

One cycle = one bucket item worked end-to-end. Each cycle gets a ULID:

```
backlog.d/_cycles/<ulid>/
├── cycle.jsonl        # append-only typed event log (the daybook)
├── evidence/          # QA artifacts, review transcripts, diffs
└── manifest.json      # {item_id, branch, claim, started, closed, status}
```

### Daybook Event Schema (load-bearing contract)

Prose-only append logs rot — that's what ate `/focus`. Typed envelope,
free-text note field for what we didn't anticipate:

```json
{
  "schema_version": 1,
  "ts": "2026-04-14T12:00:00Z",
  "cycle_id": "01HQ...",
  "kind": "shape.done" | "build.done" | "review.iter" | "ci.done" |
          "qa.done" | "deploy.done" | "reflect.done" | "harness.suggested" |
          "phase.failed" | "budget.exhausted" | "cycle.opened" | "cycle.closed",
  "phase": "shape",
  "agent": "planner",
  "refs": ["path/to/artifact"],
  "findings": [{...}],        // kind-specific payload
  "note": "free text"         // Pragmatic-daybook escape hatch
}
```

Consumers (reflect, bucket-scorer, harness-tuner) read typed fields.
Humans read `note`. Rotation: monthly archive to `_cycles/_archive/YYYY-MM/`;
reflect loads last 90 days.

### Locking

`.spellbook/iterate.lock` holds `{pid, cycle_id, started_at}`. One `/iterate`
per repo. SIGINT releases cleanly.

## Control Flow

```
/iterate [--until <pred>] [--max-cycles N] [--budget $X]
    │
    ▼
  acquire lock
    │
    ▼
┌── CYCLE START ──────────────────────────┐
│  1. pick        → bucket-scorer agent    │  cycle.opened
│  2. shape       → /shape (+Council P0)   │  shape.done
│  3. build       → /autopilot build step  │  build.done
│  4. review      → /code-review           │  review.iter (xN, max 3)
│     + CI        → dagger call check      │  ci.done
│  5. qa          → /qa (auto-scaffold)    │  qa.done
│  6. deploy      → /deploy (auto-scaffold)│  deploy.done
│  7. reflect     → /reflect on daybook    │  reflect.done
│  8. update-bucket → WRAP emitter         │  writes backlog.d/NNN-*.md
│  9. update-harness → harness.suggested   │  writes to PR branch only
└── CYCLE CLOSED ─────────────────────────┘
    │
    ▼
  stop? (predicate / max-cycles / budget / SIGINT)
    │
    └── no → pick again
```

### Stopping Predicates (user selects; default `--max-cycles 1`)

- `--until "backlog empty"` — no eligible items
- `--until "P0 closed"` — highest-priority item shipped
- `--max-cycles N` — hard count
- `--budget $N` — cumulative model cost (tracked in `manifest.json`)

Without `--budget`, `/iterate` refuses unattended mode.

## Components

| Component | Type | Owns |
|---|---|---|
| `skills/iterate/SKILL.md` | skill | orchestration, event writing, lock, budget, stop predicates |
| `scripts/daybook.sh` | script | `daybook_event <kind> <json>` — atomic JSONL append with fsync |
| `scripts/scorer.sh` | script | bucket scoring (priority × recency-of-retro-signal) |
| `agents/bucket-scorer.md` | agent | optional Explore agent when backlog > 20 items |
| existing `/shape`, `/autopilot`, `/code-review`, `/qa`, `/deploy`, `/reflect` | skills | phase handlers, unchanged |

### Model Council at `shape` (P0 items only)

Three drafters (Claude + Gemini + Codex) produce three context packets in
parallel; a fresh Claude instance with a chair-only prompt synthesizes.
Chair is never a drafter (Perplexity anti-self-preference pattern).
Implemented via existing `/research thinktank` — no new infra.

Gated by priority to cap cost. Not used at `reflect` (3× cost for
introspection isn't worth it in MVP).

### Static Bench Selection (not a classifier)

Replace hardcoded four-bench with path-glob rules in
`skills/code-review/references/bench-map.yaml`:

```yaml
default: [critic, ousterhout, grug]
rules:
  - paths: ["**/*.tsx", "**/*.jsx"]
    add: [a11y-auditor]
  - paths: ["migrations/**", "**/*.sql"]
    add: [beck]
```

Deterministic, greppable, eval-able. No dynamic classifier (single point
of failure without eval harness). No four new agents (securitron,
perfhawk, data-steward, infra-skeptic) in MVP — add only when retros
name a gap the current bench can't fill.

## Auto-Scaffold Contract (with `/tailor`)

`/qa` and `/deploy` check in order:
1. `.claude/.tailor/manifest.json:domains_owned` — tailor owns this domain? Use tailored artifact.
2. `ITERATE_MODE=1` env var set? Scaffold silently.
3. Else prompt user.

Single ownership file. Two disciplined consumers. No race.

## Failure Modes

| Failure | Recovery |
|---|---|
| Phase handler fails | Write `phase.failed`, stop cycle, keep lock until `/iterate --resume <ulid>` or `--abandon <ulid>` |
| Budget exceeded mid-cycle | Finish current phase, write `budget.exhausted`, stop |
| Daybook write fails | Fatal — fsync every event; corrupted JSONL breaks reflect |
| Two `/iterate` attempts | Second exits on lock |
| `/autopilot` internal fail | Bubble up; cycle fails; no auto-retry (prevents cost spiral) |

## MVP Slice (~5 dev-days)

1. **Daybook + `/iterate` skeleton** (1.5 days)
   - `skills/iterate/SKILL.md` with single-cycle mode (`--max-cycles 1` default)
   - `scripts/daybook.sh` with typed event schema
   - Event writing at each phase boundary
   - Lock file with clean SIGINT

2. **Static bench + bench-map.yaml** — **split out to 030** (1.5 days)
   - Design and oracle live in `backlog.d/030-static-bench-map.md`
   - Independently valuable; can land before or during `/iterate` MVP
   - Treat 030 as a sibling dependency, not blocking

3. **Auto-scaffold qa + deploy in ITERATE_MODE** (2 days)
   - `ITERATE_MODE=1` env check in `/qa` and new `/deploy` skill
   - Build `/deploy` router from `/qa` scaffold template
   - Manifest.json lookup for tailor-owned domains

## Oracle

- [ ] `/iterate --max-cycles 1` runs pick → shape → build → review → ci → qa → deploy → reflect → update-bucket on a real backlog item
- [ ] `backlog.d/_cycles/<ulid>/cycle.jsonl` exists with ≥8 typed events, all valid against schema
- [ ] `/iterate` refuses to run unattended without `--budget`
- [ ] Second `/iterate` invocation while first holds lock exits non-zero with clear message
- [ ] SIGINT during cycle releases lock; `--resume` continues from last completed phase
- [ ] `/code-review` bench selection driven by `bench-map.yaml`, not hardcoded
- [ ] `/qa` auto-scaffolds silently when `ITERATE_MODE=1` and `.claude/.tailor/manifest.json` doesn't own it
- [ ] `harness.suggested` events write to `harness/auto-tune` branch only, never main
- [ ] Spellbook dogfoods `/iterate` on itself (one cycle, one backlog item)

## Non-Goals (MVP)

- Dynamic philosophy bench classifier — static globs first
- Four new agents (securitron, perfhawk, data-steward, infra-skeptic) — prove gap first
- GEPA auto-tuner + `harness/auto-tune` automatic edits — defer until ≥20 cycles of signal
- Model Council at reflect phase — too expensive for MVP; shape only
- Refactor inlined between review iterations — wall-time tradeoff; revisit after data
- MAR-style multi-reflector — single reflect pass in MVP
- Merging PRs — humans merge; loop suggests only
- Unattended mode without explicit `--budget`

## Related

- Depends on: 022 (swarm review default), 025 (dagger merge gate)
- Sibling split-out: 030 (static bench-map — independently shippable)
- Unlocks: 029 (`/tailor` — uses daybook for eval signal),
  031 (harness auto-tune — parked until ≥20 cycles produce signal)
- Supersedes parts of: `/autopilot` continuous-mode speculation

## Name Collision Notes

- `/loop` blocked by Claude Code native (recurring interval skill)
- `/iterate` clean across Claude Code, Codex CLI, Gemini CLI, spellbook
- Env var: `ITERATE_MODE=1` (namespace-prone — consider `SPELLBOOK_ITERATE=1` if collision surfaces)
