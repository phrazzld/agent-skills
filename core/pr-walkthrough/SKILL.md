---
name: pr-walkthrough
description: |
  Create the mandatory walkthrough package for a pull request. Designs the script,
  chooses the renderer (browser, terminal, diagram, or Remotion), captures before/after
  evidence, and links one persistent verification check to the story being told.
  Use when: opening a PR, preparing reviewer evidence, recording a demo, or proving why
  a branch should merge. Keywords: walkthrough, demo video, QA walkthrough, before/after,
  reviewer evidence, PR artifact.
disable-model-invocation: true
argument-hint: "[PR-number-or-branch]"
---

# /pr-walkthrough

Generate the truth artifact for a PR.

## Objective

For every PR, produce one walkthrough package:

- walkthrough spec
- walkthrough artifact
- evidence bundle
- persistent verification link

The walkthrough is mandatory for all PRs. The renderer changes by PR type. The contract does not.

## Deliverables

Every run must leave behind:

1. A script that explains:
   - what was wrong or missing before
   - what changed on this branch
   - what is true after
   - why the change matters
   - what test now protects it
2. A primary artifact:
   - browser recording
   - terminal walkthrough
   - Remotion-rendered narrated video
   - mixed media walkthrough
3. Evidence references for each major claim
4. A PR body `## Walkthrough` section linking the artifact and the protecting check

## Workflow

### 1. Read the merge case

Read the issue, diff, draft PR body, changed tests, and current QA evidence.

Do not script from the diff alone. The walkthrough must explain significance, not just motion.

### 2. Pick the renderer

Use the renderer selection in `references/walkthrough-contract.md`.
If multiple surfaces matter, use a mixed walkthrough.
If a polished Remotion cut adds value, treat it as a non-blocking pass after the deterministic evidence flow is already strong.

### 3. Write the walkthrough spec

Use the contract in `references/walkthrough-contract.md`.
Use its default script beats as the canonical sequence.
Every scene must map to observable evidence.

### 4. Capture evidence first

Before recording the final walkthrough:

- collect before/after screenshots, clips, command output, or diagrams
- capture the happy path
- capture one key edge, failure, or invariant when it materially affects confidence
- identify the single automated check that best protects this change

The walkthrough artifact is not enough on its own. The evidence must stand on its own if the video is skipped.

### 5. Produce the artifact

Preferred order:

1. deterministic browser or terminal walkthrough
2. optional polished Remotion cut with narration or music

Never block a PR on a cinematic pass if the deterministic walkthrough is already strong and truthful.

### 6. Tie it to persistent verification

Every walkthrough must name the test, smoke check, or CI job that now protects the path it demonstrates.

If no durable automated check exists:

- add one when feasible
- otherwise call out the gap explicitly and make fixing it the next quality task

### 7. Update the PR body

Add a `## Walkthrough` section that includes:

- renderer used
- artifact link
- core claim the walkthrough proves
- before/after scope covered
- persistent check protecting the path
- residual gap, if any

## Rules

- All PRs get a walkthrough. No exceptions.
- The artifact must strengthen reviewer confidence, not just advertise polish.
- Prefer deterministic evidence over high-production ambiguity.
- Remotion is encouraged for high-value communication, not as a substitute for proof.
- If the PR changes nothing user-visible, narrate invariants, architecture, and verification instead.

## References

- `references/walkthrough-contract.md` - renderer selection, script rubric, and PR section template
