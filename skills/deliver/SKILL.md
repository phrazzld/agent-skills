---
name: deliver
description: |
  Inner-loop composer. Takes one backlog item to merge-ready code. Composes
  /shape → /implement → {/code-review + /ci + /refactor + /qa} (clean loop)
  and stops. Does not push, does not merge, does not deploy. Communicates
  with callers via exit code + receipt.json — no stdout parsing.
  Use when: building a shaped ticket, "deliver this", "make it merge-ready",
  driving one backlog item through review + CI + QA.
  Trigger: /deliver.
argument-hint: "[backlog-item|issue-id] [--resume <ulid>] [--abandon <ulid>] [--state-dir <path>]"
---

# /deliver

Inner-loop composer. One backlog item → merge-ready code. **Delivered ≠
shipped.** The outer loop (`/autopilot`, see 028) consumes the receipt and
decides whether to deploy. Humans merge.

## Execution Stance

You are the executive orchestrator.
- Compose atomic phase skills. Never inline phase logic.
- Dispatch → synthesize receipts → make proceed/fix/escalate calls.
- Fail loud. Never swallow a phase failure into a "best effort" pass.

## Composition

```
/deliver [backlog-item|issue-id] [--resume <ulid>] [--state-dir <path>]
    │
    ▼
  pick (if no arg) — backlog.d/ highest-priority OR git-bug
    │
    ▼
  /shape            → context packet (goal + oracle + sequence)
    │
    ▼
  /implement        → TDD build on feature branch (033)
    │
    ▼
┌── CLEAN LOOP (max 3 iterations) ─────────────┐
│  /code-review    → critic + bench             │
│  /ci             → dagger audit + run (034)   │
│  /refactor       → diff-aware simplify        │
│  /qa             → browser-driven exploratory │
│  capture evidence → see references/evidence.md│
└──────────────────────────────────────────────┘
    │ all green → merge-ready (exit 0)
    │ cap hit or hard fail → fail loud (exit 20/10)
    ▼
  receipt.json written; stop. No push, no merge, no deploy.
```

## Phase Routing

| Phase | Skill | What it owns | Skip when |
|---|---|---|---|
| shape | `/shape` | context packet, oracle, sequence | packet already has executable oracle |
| implement | `/implement` | TDD red→green→refactor, commits on feature branch | — |
| review | `/code-review` | parallel bench review, synthesized findings | — |
| ci | `/ci` | dagger audit + green pipeline | `/ci` itself decides — do not pre-filter |
| refactor | `/refactor` | diff-aware simplification | trivial diffs (<20 LOC, single file) |
| qa | `/qa` | browser-driven exploratory test, evidence | no user-facing surface (pure library/refactor) |

Each skill has its own contract and receipt. `/deliver` reads those
receipts; it never re-implements the phase.

## Cross-Cutting Invariants

- **No claims.** Dropped per operating principle. Single local workspace.
  Concurrent worktrees coordinate via state-dir isolation (see
  `references/worktree.md`).
- **Never push.** Delivery ≠ shipping. `git push` is the outer loop's call.
- **Never merge.** `gh pr merge` is a human decision.
- **Never deploy.** `/deploy` is the outer loop's concern.
- **Never commit to default.** Feature branch only; see `references/branch.md`.
- **Fail loud.** A dirty phase is a dirty phase — do not mask it, do not
  retry past the cap, do not write `status: merge_ready` when anything is
  red.
- **Evidence is out-of-band.** `/deliver` writes zero artifacts itself;
  per-phase skills emit; receipt records pointers only. See
  `references/evidence.md`.

## Contract (exit code + receipt)

`/deliver` communicates exclusively via its exit code and
`<state-dir>/receipt.json`. Callers — human or `/autopilot` outer loop —
do not parse stdout.

| Exit | Meaning | Receipt `status` |
|---|---|---|
| 0 | merge-ready | `merge_ready` |
| 10 | phase handler hard-failed (tool/infra error) | `phase_failed` |
| 20 | clean loop exhausted (3 iterations, still dirty) | `clean_loop_exhausted` |
| 30 | user/SIGINT abort | `aborted` |
| 40 | invalid args / missing dep skill | `phase_failed` |
| 41 | double-invoke on an already-delivered item | `phase_failed` |

Full receipt schema + state lifecycle: `references/receipt.md`.

## Resume & Durability

State is filesystem-backed and resumable.

- **State root:** `<worktree-root>/.spellbook/deliver/<ulid>/` (gitignored).
  Override via `--state-dir <path>` (the outer loop uses this to land state
  under its cycle's evidence tree).
- **Checkpoint:** after each phase, `state.json` rewritten atomically
  (write → fsync → rename).
- **`--resume <ulid>`:** loads `state.json`, skips completed phases,
  re-enters at `current_phase`. Phase handlers must be idempotent.
- **`--abandon <ulid>`:** removes state-dir; leaves branch as-is.
- **Double-invoke:** `/deliver <already-delivered-item>` → exit 41, not
  silent re-run.

Full protocol: `references/durability.md`.

## Gotchas (judgment, not procedure)

- **Retry vs escalate.** Dirty on iteration 1 → retry (normal). Dirty on
  iteration 3 → exit 20, write receipt, hand to human. Do not invent a 4th
  iteration. The cap is load-bearing: loops without one produce slop.
- **What counts as "dirty".** `/code-review` blocking verdict, `/ci`
  non-zero, `/qa` P0/P1. P2 QA findings are documented in the receipt and
  do NOT block. Review "nit" and "consider" are not blocking.
- **Inlining a missing phase.** `/implement` missing → exit 40. Do NOT
  fall back to your own TDD build — inlined fallbacks become permanent.
- **Silent push.** A phase skill that "helpfully" runs `git push` is a bug
  in that phase skill. Surface it; do not suppress it in the composer.
- **Re-shaping mid-delivery.** If `/implement` or `/qa` reveals the shape
  is wrong, stop the clean loop and exit with remaining_work pointing at
  re-shape. Do not spin.
- **Skipping shape.** Building without a context packet yields plausible
  garbage. If the item has no oracle, `/shape` runs first. Always.
- **Review without verdict = dirty.** If `/code-review` runs but no `refs/verdicts/<branch>` points at HEAD afterwards, treat the review phase as failed.
- **Merging.** Never. End-state is merge-ready, not merged.

## References

- `references/clean-loop.md` — iteration cap, dirty-detection per phase,
  escalation protocol
- `references/receipt.md` — full JSON schema, exit-code table, state
  lifecycle
- `references/durability.md` — state.json atomic checkpoint protocol,
  `--resume` / `--abandon` semantics, double-invoke
- `references/evidence.md` — per-phase emission paths, gitignored
  `.spellbook/deliver/` conventions
- `references/branch.md` — branch-naming, HEAD-detection, no-push rule
- `references/worktree.md` — state-root resolution, concurrent worktrees

## Non-Goals

- Deploying — `/autopilot` outer loop's concern
- Merging — humans merge
- Multi-ticket operation — one ticket per invocation
- Claim-based coordination — explicitly dropped
- Version-controlled evidence — gitignored under `.spellbook/`

## Related

- Consumer: `/autopilot` (028) — outer loop passes `--state-dir` under its
  cycle tree and reads `receipt.json`
- Phases: `/shape`, `/implement` (033), `/code-review`, `/ci` (034),
  `/refactor`, `/qa`
