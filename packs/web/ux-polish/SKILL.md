---
name: ux-polish
description: |
  Find and ship the smallest UX improvement that meaningfully reduces friction in a working product.
  Use when a flow basically works but feels rough: unclear affordances, weak feedback, awkward spacing,
  fragile empty/loading/error states, poor focus order, or mobile hit-target issues. Not for rebrands,
  broad redesigns, or architecture refactors. Keywords: /ux-polish, polish this flow, tighten UX,
  small UX win, reduce friction, micro-interaction, empty state, loading state, error state.
disable-model-invocation: true
argument-hint: "[route, flow, or component]"
---

# /ux-polish

Make one narrow UX improvement users will actually notice.

## Role

Product-minded frontend editor. Find the smallest change that removes real user friction without turning the task into a redesign.

## Objective

For the whole repo or `$ARGUMENTS`, answer four questions with evidence:

1. Which user journey or surface is under review?
2. What specific friction is most likely costing clarity, trust, speed, or completion?
3. Which narrowly scoped polish pass removes that friction without reopening system design?
4. How will you prove the experience is better after the change?

Then implement the winning polish pass, verify it visually and behaviorally, and ship it.

## Guardrails

- Work inside one route, flow, or tightly related interaction surface
- Prefer one coherent polish pass over a bag of unrelated nits
- Bias toward clarity, feedback, accessibility, and ergonomic wins users feel immediately
- If the best fix requires new IA, new flows, or a broader aesthetic system change, stop and hand off to `../design/SKILL.md`
- Invoke `../ui-skills/SKILL.md` before touching UI code; if its preferred delegation path is unavailable, apply the same constraints manually and say so

## Workflow

1. **Establish the surface** — Read the nearest `AGENTS.md`, `CLAUDE.md`, and `README`, then inspect the route, component, copy, and current states for the target flow. Capture the exact entrypoint, happy path, and failure, empty, and loading states.
2. **Name the friction** — Describe the highest-leverage problem in plain language: what confuses users, slows them down, or makes the UI feel less trustworthy. Ignore ornamental tweaks that do not change user outcomes.
3. **Score candidates** — Read `references/polish-rubric.md`. Generate several micro-polish options, then rank them by user impact, scope fit, reversibility, accessibility, and proof path.
4. **Choose one polish pass** — Pick the single best improvement or one tiny cluster that solves the same root problem. State what is in scope, what is out of scope, and what behavior must stay unchanged.
5. **Implement with constraints** — Apply `ui-skills` rules: accessible primitives, local feedback, no decorative animation, no gratuitous gradients, proper touch targets, balanced typography, and safe viewport usage. Use `../design/SKILL.md` only for targeted taste checks or when design debt clearly blocks the polish.
6. **Review like a designer** — Run the `ui-skills` expert-panel review on the affected surface. If the average is below 90, refine and re-review before continuing.
7. **Verify what users see** — Run `../visual-qa/SKILL.md` for the affected route or component surface. Fix all P0 and P1 issues. Also verify the functional state that changed: keyboard path, empty/error/loading handling, or mobile tap target behavior.
8. **Ship the small win** — Update docs only if behavior or expectations changed. If the repo is already in a PR workflow, invoke `../pr/SKILL.md`; otherwise report the change, evidence, and the next highest-leverage polish item left behind.

## Good Targets

- Empty states with no clear next action
- Error or validation feedback that is missing, vague, or far from the action
- Loading states that feel jumpy, blank, or misleading
- Ambiguous buttons, labels, CTA copy, or hierarchy
- Small mobile ergonomics issues: hit targets, density, or safe-area problems
- Focus, keyboard, or screen-reader polish that removes friction without re-architecting the flow

## Out of Scope

- Rebrands, visual overhauls, or net-new design systems
- Information architecture changes spanning multiple flows
- Large refactors better handled by `/simplify`
- New feature work disguised as polish
- Animation or ornament added without clear UX benefit

## Output

Default deliverable:

- Surface and user journey audited
- Candidate polish options with rubric scores
- Chosen polish pass and scope boundary
- Verification evidence: expert-panel result plus visual and behavioral checks
- Remaining follow-up polish ideas, if any

## References

- `references/polish-rubric.md`
