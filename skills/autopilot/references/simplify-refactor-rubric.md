# Refactor Rubric

Generate multiple candidates before choosing a refactor.

Default set:
- one conservative simplification
- one boundary-reset or module-consolidation option
- one aggressive "if rebuilding today" option

Large repos often need 5+ candidates.

## Ousterhout Checks

Prefer options that:

- create deeper modules with smaller visible interfaces
- hide implementation detail instead of spreading it across callers
- remove pass-through layers and temporal coupling
- replace special cases with one clear invariant
- delete code and concepts instead of relocating them
- reduce the number of modules touched by common changes
- reduce prerequisite knowledge required to use the module
- make future changes cheaper, not just this patch smaller

## Code Pattern Checks

After module-level design, check code-level patterns per [code-patterns.md](./code-patterns.md):

- reduces state space (fewer arguments, narrower types, discriminated unions)
- uses asserts at boundaries instead of defensive defaults
- keeps functions skimmable without over-extraction
- makes optionals truly optional

## Single-PR Filter

A candidate is eligible only if it:

- fits inside one reviewable pull request
- has a clear behavior-preservation story
- can be tested with existing or easily added checks
- has bounded migration and rollback risk
- does not require a speculative platform rewrite

If a candidate fails this filter, keep it as future architecture, not the current PR.

## Selection Questions

For each candidate, answer:

1. What complexity disappears if this lands?
2. What interface or boundary becomes simpler?
3. What important behavior could regress?
4. What evidence would make that risk acceptable?
5. Why is this the best move now, not just the prettiest diagram?

Required evidence per candidate:

- public API or operator surface that changes, if any
- call-sites that currently require internal knowledge
- expected files touched for a routine feature change before vs after

## Lightweight Scorecard

Use a simple rubric such as `high`, `medium`, `low`:

| Candidate | Simplicity Gain | Risk | Effort | Future Leverage | PR Fit |
|-----------|-----------------|------|--------|-----------------|--------|

The winner is not the most ambitious idea. It is the option with the best ratio of:

`complexity removed / delivery risk`

## Output Contract

Use a report structure close to this:

## Current Shape

## Why It Ended Up Here

## First-Principles Alternatives

## Chosen Simplification

## Verification Plan

## PR Outcome

Adapt section names if the repo already has a house style.
