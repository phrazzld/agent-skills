# PR Walkthrough: Review Reconciliation Redesign

## Claim

This branch closes the false-"PR Unblocked" gap by making `pr-fix` inventory-driven, settlement-gated, and explicit about handoff boundaries in `pr` and `autopilot`.

## Renderer

Diagram-led walkthrough with proof commands.

## Why Now

The old `pr-fix` shape let a PR look clean while old actionable review comments were still unresolved. That is a real workflow failure, not wording polish.

## Before

```mermaid
graph TD
  A["Green checks / mergeable"] --> B["Spot-check counts"]
  B --> C["Resolve some threads"]
  C --> D["Post PR Unblocked"]
  D --> E["Older actionable comments can still be open"]
```

The failure mode was count-driven reconciliation. A temporary clean-looking surface could mask unresolved older review items.

## What Changed

```mermaid
graph TD
  A["Read PR state"] --> B["Build deterministic review inventory"]
  B --> C["Create actionable ledger"]
  C --> D["Fix / defer / reject every item"]
  D --> E["Reply directly per item"]
  E --> F["Resolve actionable threads"]
  F --> G["Wait for async review automation to settle"]
  G --> H["Rerun inventory"]
  H --> I["Only then signal unblocked"]
```

The redesign moved the critical rule into the skill contract:
- inventory beats counts
- reply per actionable item
- rerun inventory after async reviewers settle
- `pr` and `autopilot` cannot imply review-clean status without `/pr-fix`

## After

```mermaid
stateDiagram-v2
  [*] --> OpenPR
  OpenPR --> Reconciling: review findings arrive
  Reconciling --> Waiting: replies posted + threads resolved
  Waiting --> Reconciling: new async findings appear
  Waiting --> ReviewClean: settled inventory is clean
  ReviewClean --> [*]
```

The important change is not just "do more review." It is "do not signal success until the live PR inventory stays closed after settlement."

## Evidence

### Structural validation

```bash
python3 core/skill-builder/scripts/validate_skill.py core/pr-fix
python3 core/skill-builder/scripts/validate_skill.py core/pr
python3 core/skill-builder/scripts/validate_skill.py core/autopilot
```

Observed result:
- `pr-fix`: valid, no warnings
- `pr`: valid, no warnings
- `autopilot`: valid, existing pre-branch warning about long body remains

### Live failure-mode probe

```bash
python3 core/pr-fix/scripts/review_inventory.py 533 --repo misty-step/bitterblossom
```

Observed result:
- unresolved threads: `6`
- top-level review comments: `19`
- bot issue comments: `4`
- checks: `21`

This is the key proof. The new inventory script exposes the exact missed state that previously slipped through.

## Persistent Verification

Current durable checks:
- `python3 core/skill-builder/scripts/validate_skill.py core/pr-fix`
- `python3 core/skill-builder/scripts/validate_skill.py core/pr`
- `python3 core/skill-builder/scripts/validate_skill.py core/autopilot`

These protect packaging and structural integrity of the skill changes.

## Residual Gap

There is still no fully automated regression harness that simulates delayed bot comments and proves the settlement gate behavior end-to-end. The branch improves the prompt contract and adds deterministic inventory tooling, but that live-review workflow is not yet mechanically tested.
