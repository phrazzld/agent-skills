# /reflect cycle — outer-loop cycle critique

The learning engine of the outer loop. Read one cycle's artifacts, produce
a typed findings file, mutate the backlog with evidence, and push harness
suggestions to a branch. Consumed by `/iterate` and by future harness
auto-tune work (GEPA / backlog item 031).

## When to Use This Mode

- `/iterate` (or `/autopilot` outer loop) finishes a cycle and dispatches
  `/reflect cycle <cycle-ulid>` automatically.
- A human re-runs reflect on a past cycle to extract deferred learnings:
  `/reflect cycle 01HQABC...`.

Not for live session retros (use `distill`) or mid-session course
correction (use `calibrate`).

## Input

```
backlog.d/_cycles/<ulid>/
├── cycle.jsonl        # append-only typed events
├── evidence/          # QA artifacts, review transcripts, diffs
└── manifest.json      # {item_id, branch, claim, started, closed, status}
```

Plus ambient harness pointers:
- `CLAUDE.md`, `AGENTS.md`, `harnesses/shared/AGENTS.md`
- Active skills/agents referenced in event log (`agent` field per event)
- `backlog.d/` (mutation target) and `backlog.d/_done/` (read-only context)

If the cycle dir is missing, has fewer than 3 events, or has a corrupt
`cycle.jsonl`, abort with a `phase.failed` event — do not invent findings.

## Output

Three artifacts, in this order:

1. `backlog.d/_cycles/<ulid>/reflect.signals.json` — typed findings (schema below)
2. Git commits on the current branch mutating `backlog.d/` (one commit per
   mutation class: `reflect(<cycle-id>): consolidate N items`, etc.)
3. Branch `reflect/<cycle-id>` with harness-edit commits, pushed to origin
   if a remote exists. Never merged automatically.

Terminates by appending a `reflect.done` event to `cycle.jsonl` with a `refs`
array pointing at `reflect.signals.json` and the harness branch name (or
null if no branch was produced).

## `reflect.signals.json` Schema

Stable contract — future consumers (GEPA optimizer, dashboards) depend on
field names. Add fields, don't rename them.

```json
{
  "schema_version": 1,
  "cycle_id": "01HQ...",
  "generated_at": "2026-04-15T00:00:00Z",
  "summary": "One-paragraph plain-English cycle critique.",
  "findings": [
    {
      "id": "F1",
      "kind": "wasted_effort",
      "severity": "medium",
      "evidence_refs": ["cycle.jsonl:42-48", "evidence/review_iter_2.md"],
      "summary": "Spec changed mid-cycle; half the build was scrapped.",
      "recommended_action": "Add contract-freeze step to /shape.",
      "target": {
        "kind": "skill",
        "path": "skills/shape/SKILL.md",
        "section": "Contract"
      },
      "feedback": "Shape must emit an immutable contract block; build phase must hash-check it before starting.",
      "mutation": {
        "kind": "new_backlog_item",
        "path": "backlog.d/NNN-shape-contract-freeze.md",
        "title": "Add contract-freeze step to /shape"
      }
    }
  ],
  "bucket_mutations": [
    {"op": "create", "path": "backlog.d/NNN-...", "evidence_refs": ["F1"]},
    {"op": "consolidate", "into": "backlog.d/014-...", "from": ["backlog.d/022-...", "backlog.d/028-..."], "evidence_refs": ["F3"]},
    {"op": "delete", "path": "backlog.d/007-...", "evidence_refs": ["F4"]},
    {"op": "reprioritize", "path": "backlog.d/011-...", "from": "medium", "to": "high", "evidence_refs": ["F2"]}
  ],
  "harness_suggestions": {
    "branch": "reflect/01HQ...",
    "edits": [
      {"target": {"kind": "skill", "path": "skills/shape/SKILL.md"}, "rationale": "F1"},
      {"target": {"kind": "AGENTS.md", "path": "harnesses/shared/AGENTS.md", "section": "Doctrine"}, "rationale": "F5"}
    ]
  }
}
```

**Finding enums.**
- `kind`: `wasted_effort` | `rabbit_hole` | `missing_skill` | `harness_gap` | `spec_drift` | `operator_gap` | `tooling_gap`
- `severity`: `low` | `medium` | `high`
- `target.kind`: `skill` | `agent` | `hook` | `AGENTS.md` | `backlog` | `operator` | `none`
- `mutation.kind`: `new_backlog_item` | `edit_backlog_item` | `consolidate` | `delete` | `reprioritize` | `none`

**Invariants.**
- Every finding has ≥1 `evidence_refs` entry pointing into the cycle dir.
- Every `bucket_mutations` entry cross-references a finding `id`.
- `harness_suggestions.branch` is null iff `edits` is empty.

## Bucket Mutation Authority

Reflect is the **only** skill licensed to rewrite `backlog.d/` beyond a single
item. Authority and its boundaries:

| Op | Allowed | Forbidden |
|----|---------|-----------|
| `create` | New items under `backlog.d/NNN-slug.md` with next free index | Creating in `_done/`, `_cycles/`, or any subdir not documented in `/groom` |
| `edit` | Tighten goals, add evidence refs, update status of items not in a live cycle | Editing items owned by another live cycle (check `backlog.d/_cycles/*/manifest.json`) |
| `consolidate` | Merge 2+ overlapping items into the eldest; delete the rest; cite both sources in the survivor | Merging across unrelated themes just to shrink the count |
| `delete` | Remove items rendered obsolete by cycle evidence (shipped elsewhere, invalidated by a design change) | Deleting because "nobody's working on it" or "looks stale" — that is `/groom`'s job |
| `reprioritize` | Raise/lower priority when cycle evidence shows impact shift | Reprioritizing on taste alone |

**Never touch:**
- `backlog.d/_done/` — archival is `/groom`'s job
- `backlog.d/_cycles/` (except writing this cycle's `reflect.signals.json`)
- Items owned by another live cycle (per its manifest)

**Commit discipline.** One git commit per mutation class, message format:
`reflect(<cycle-id>): <op> <target> — <finding-id>`. Commits land on the
branch `/iterate` is already on — reflect does not create a branch for
bucket work.

## Harness Suggestion Protocol

Harness edits are load-bearing: a bad skill rewrite breaks every future
cycle. Therefore reflect never edits skills/agents/hooks/AGENTS.md in place.

**Branch naming.** `reflect/<cycle-id>` (e.g., `reflect/01HQABC...`). Always
branched from the cycle's starting ref (`manifest.json#started_at_ref`),
never from the mutated feature branch.

**Scope of allowed edits.**
- `skills/*/SKILL.md` and `skills/*/references/*.md`
- `agents/*.md`
- `harnesses/**/AGENTS.md`
- `harnesses/**/hooks/*` — edit only; never add a new hook without a
  corresponding `harness_gap` finding of severity ≥ medium
- Top-level `CLAUDE.md` — only when a finding cites missing project-wide guidance

**Forbidden on the branch.**
- Product code outside `skills/`, `agents/`, `harnesses/`
- Deletions of any skill or agent (requires `/harness` human review)
- Bootstrap / registry / CI config

**Push rules.**
- Push to `origin` if it exists; otherwise leave local.
- Never force-push.
- Never open a PR — humans choose when to review. Log the branch name in
  `reflect.signals.json#harness_suggestions.branch` and as a `refs` entry
  on the `reflect.done` event.

## Judgment — When Does Something Rise to a Branch?

Harness suggestions are expensive (humans must review). Downgrade to a
finding-only note if any of these are true:

- Single anecdote, no pattern across phases or prior cycles
- Recommendation is "add more detail" without a concrete delta
- Fix lives in project code, not the harness (file it as a backlog item)
- Would require a new skill — those go through `/harness`, not reflect

Promote to a branch edit when:

- Same failure appears ≥2 cycles (cite prior `reflect.signals.json`)
- Cycle evidence shows a skill's documented contract was followed and still
  produced wrong output — the contract is wrong
- A procedural rule already memorialized in AGENTS.md was bypassed because
  the rule was ambiguous (not because the agent ignored it)

Edge case: a finding warrants *both* a memory note (operator coaching) and
a branch edit. Emit both — don't collapse.

## Consolidate vs Split — Backlog Mutation Judgment

**Consolidate when** two items share the same root cause and same target
artifact. Survivor keeps the oldest ID (stable refs), absorbs evidence from
the others, cites all sources.

**Split when** one item has accreted two distinct goals during the cycle
(evidence: review transcripts bouncing between concerns). Create the second
item, cross-link, leave the original narrowed.

**Delete only when** cycle evidence proves the item is obsolete. "Looks
old" is not evidence. If in doubt, `reprioritize` to `low` and leave a
note instead.

## Gotchas

- **Hallucinated findings.** If you cannot cite a line range in `cycle.jsonl`
  or a file under `evidence/`, drop the finding. No speculation.
- **Self-reflection.** Do not produce findings about reflect itself — out
  of scope. File as a backlog item if the gap is real.
- **Mid-cycle harness drift.** Never edit a skill that the current cycle's
  events show was used — wait for the cycle to close fully.
- **Re-running reflect on the same cycle.** Idempotent: new findings append
  to `reflect.signals.json` under a new `run_id`; bucket mutations already
  applied are skipped by diffing against git history.
- **Missing remote.** If `git remote` is empty, harness branch stays local
  and `reflect.signals.json#harness_suggestions.branch` still records the
  local ref — downstream readers assume local-only when no push record exists.
- **Branch lifetime.** `reflect/<cycle-id>` branches live until a human
  merges or deletes them. Reflect does not garbage-collect them.
