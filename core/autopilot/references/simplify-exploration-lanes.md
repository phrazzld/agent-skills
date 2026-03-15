# Exploration Lanes

Use subagents when available. If not, run the same lanes yourself in this order.

Run only the minimum lanes needed to choose one safe, high-leverage simplification.
Skip any lane that cannot change the decision. Four is the default ceiling.

## Lane 1: Codebase Cartographer

Objective: explain what the system does now.

Gather:
- entrypoints, major modules, data flow, runtime boundaries
- where core behavior actually lives
- tests that protect the important seams
- obvious duplication, pass-through layers, or split responsibilities

Return:
- current architecture summary
- deepest modules vs shallowest modules
- 2-5 simplification opportunities with file evidence

## Lane 2: Git Historian

Objective: explain how the current shape emerged.

Gather:
- recent commits in the touched area
- major refactors, migrations, rewrites, or reversals
- ADRs, issue links, release notes, and commit messages that explain intent
- signs of temporary scaffolding that became permanent

Return:
- architecture timeline
- decisions that still look load-bearing
- compatibility layers or legacy seams that may now be removable

Treat history as evidence, not authority. Keep only constraints that still map to
current product or runtime needs.

## Lane 3: Product and Docs Analyst

Objective: separate real product constraints from incidental implementation detail.

Gather:
- README, docs, specs, contracts, API surface, and operator workflows
- main user journeys or internal jobs the system must support
- explicit non-negotiables vs outdated prose

Return:
- what behavior is sacred
- what complexity is policy-driven vs accidental
- doc drift or contract ambiguity that affects refactor safety

## Lane 4: Simplifier

Objective: reason from first principles and Ousterhout-style module depth.

Ask:
- Which modules leak too much detail?
- Which abstractions are only pass-throughs?
- Which workflows are split for historical rather than present reasons?
- What could be deleted or collapsed without losing capability?

Return:
- 3-7 candidate redesign moves
- strongest conservative option
- strongest aggressive option
- the single best one-PR simplification candidate

## Synthesis

Merge the lanes into one view:

1. Current system: what exists and why
2. Candidate future shapes: several credible designs
3. Single-PR move: best simplification available now

Do not let one lane dominate without evidence from the others.
