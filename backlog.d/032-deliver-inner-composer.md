# `/deliver` — inner composer (rename of `/autopilot`)

Priority: high
Status: pending
Estimate: L (~3 dev-days)

## Rename

Current `/autopilot` → `/deliver`. The skill takes one backlog item and
produces merge-ready code. It does not ship, does not deploy — it delivers
a reviewed, CI-green, QA-passed, refactored diff. "Delivered" ≡ ready for
human merge + downstream `/autopilot` (outer loop) to deploy.

The `/autopilot` name moves to the outer loop (see 028). One swap, two
skills with honest names.

## Goal

- One skill takes a ticket all the way to merge-ready code
- Composed from atomic phase skills; no inlined phase logic
- Stop condition: diff is clean (review + ci + qa all green) OR fails loudly
- No deploy, no monitor, no reflect — those belong to `/autopilot` (outer)

## Composition

```
/deliver [backlog-item|issue-id]
    │
    ▼
  pick (if no arg)
    │
    ▼
  /shape            → context packet
    │
    ▼
  /implement        → TDD build (see 033)
    │
    ▼
┌── CLEAN LOOP ────────────────────────────────┐
│  /code-review    → critic + bench            │
│  /ci             → dagger audit + run (034)  │
│  /refactor       → diff-aware simplify       │
│  /qa             → browser-driven exploratory│
│  capture evidence → see Evidence Storage     │
└──────────────────────────────────────────────┘
    │ loop until all green, max 3 iterations
    ▼
  merge-ready (stops here — no deploy, no merge)
```

Each phase is its own skill. `/deliver` is a thin composer: dispatch,
synthesize, make proceed/fix/escalate decisions.

## What Moves Out

Today's `/autopilot` inlines a lot of build logic. Extract:

| Inlined today | Becomes |
|---|---|
| TDD build loop | `/implement` (033) |
| CI invocation | `/ci` (034 — redesigns `/settle`) |
| Ad-hoc evidence capture | Formal step, see Evidence Storage below |
| Ship/merge logic | Removed — humans merge; `/autopilot` (outer) deploys |

## Atomic Phase Skills Required

| Skill | Status | Ticket |
|---|---|---|
| `/shape` | ✓ exists | — |
| `/implement` | ❌ new | 033 |
| `/code-review` | ✓ exists | static bench-map in 030 |
| `/ci` | ❌ new (from `/settle` redesign) | 034 |
| `/refactor` | ✓ exists | — |
| `/qa` | ✓ exists | tailoring deferred |

## Evidence Storage (open question)

Durable artifact storage for QA evidence + demo GIFs + review transcripts.
Two paths in tension:

1. **Git-native** (`024-offline-evidence-storage.md`): `.evidence/` dir
   keyed by branch, committed to repo. Offline-first, auditable.
2. **Out-of-band** (per user conversation 2026-04-15): not version
   controlled, possibly GitHub draft release or external artifact store.

Resolve before `/deliver` lands. Options to research:
- GitHub draft releases (current `/demo` approach)
- S3 / R2 / Tigris with signed URLs
- Git LFS for binaries only
- Hybrid: small artifacts committed, large (video) uploaded

`/research thinktank` on "durable agent evidence storage for dev loops"
before deciding. Block `/deliver` rework on resolution.

## `/deliver` vs current `/autopilot`

| Concern | `/autopilot` today | `/deliver` proposed |
|---|---|---|
| Scope | Pick → ship | Pick → merge-ready |
| Phases inlined | shape, build, review, ship | None — composes atomic skills |
| Stop condition | Shipped PR | Diff is clean |
| Evidence handling | Ad-hoc | Formal step |
| Callers | Human | Human OR `/autopilot` (outer) |

## Phase Plan

1. **Split out atomic skills** — land 033 (`/implement`), 034 (`/ci`) first. `/deliver` can't rename until its dependencies exist.
2. **Resolve evidence storage** — research + decision. Update 024 or supersede it.
3. **Rename `/autopilot` → `/deliver`** — mechanical. Update all triggers, description, CLAUDE.md references, bootstrap hook symlinks.
4. **Rewrite SKILL.md as composer** — strip inlined phase logic; delegate to atomic skills. Target: <300 lines (from ~700 today).
5. **Update `/harness` eval** — regression test that the recomposed `/deliver` ships the same quality as the inlined `/autopilot` on a fixed backlog item.

## Oracle

- [ ] `skills/deliver/SKILL.md` exists; `skills/autopilot/SKILL.md` gone (inner meaning)
- [ ] `/deliver` runs on a real ticket and produces merge-ready code without inlining phase logic
- [ ] All phase handlers (`/shape`, `/implement`, `/code-review`, `/ci`, `/refactor`, `/qa`) invoked via skill composition
- [ ] `/deliver` stops at merge-ready — does not push merge, does not deploy
- [ ] Evidence captured to decided storage layer at each phase
- [ ] Clean-loop termination: max 3 iterations, fails loudly on still-dirty diff
- [ ] `/harness eval` shows no quality regression vs pre-rename `/autopilot`

## Non-Goals

- Deploying code — `/autopilot` outer loop owns that
- Multi-ticket operation — one ticket per invocation
- Unattended mode — interactive by default; outer loop runs `/deliver` unattended via its own contract
- Repo-specific tailoring — deferred (tailor rework pending)

## Related

- Blocks: 028 (`/autopilot` outer loop needs `/deliver` as a black-box step)
- Depends on: 033 (`/implement`), 034 (`/ci`), evidence-storage decision (024 or successor)
- Sibling: 030 (static bench-map — improves `/code-review` subphase)
- Supersedes: parts of `/settle` that overlap with `/ci`
