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
Plain prose does not satisfy the contract. Every walkthrough must contain observable evidence from real execution.
The walkthrough exists to prove the merge claim to a skeptical reviewer. It is evidence, not decoration.

## Deliverables

Every run must leave behind:

1. A script that explains:
   - what was wrong or missing before
   - what changed on this branch
   - what is true after
   - why the change matters
   - what test now protects it
2. A primary artifact:
   - screenshot bundle
   - browser recording
   - terminal walkthrough
   - Remotion-rendered narrated video
   - mixed media walkthrough
3. Evidence references for each major claim
4. A PR body `## Walkthrough` section linking the artifact and the protecting check
5. A top-level `## Reviewer Evidence` block that gets reviewers to the proof in one click

At least one artifact must come from real branch execution.
A markdown note with no capture, no command output, no screenshot, and no recording is a walkthrough failure.

If a repo-hosted artifact is needed, it must use a PR- or branch-unique path. Shared filenames are forbidden.

## Workflow

### 1. Read the merge case

Read the issue, diff, draft PR body, changed tests, and current QA evidence.

Do not script from the diff alone. The walkthrough must explain significance, not just motion.

### 2. Pick the renderer

Use the renderer selection in `references/walkthrough-contract.md`.
If multiple surfaces matter, use a mixed walkthrough.
If a polished Remotion cut adds value, treat it as a non-blocking pass after the deterministic evidence flow is already strong.
If the claim involves motion, state transitions, or user interaction, a screencast or browser recording is mandatory.
If the claim is internal or architectural, a terminal capture of the proving commands or runtime behavior is mandatory; diagrams support the proof but do not replace execution evidence.
If the PR says behavior is unchanged, the app still works, or a user flow still functions after an internal refactor, terminal evidence alone is not enough. Record a real end-to-end happy path in the app and pair it with the terminal/runtime proof.

### 3. Write the walkthrough spec

Use the contract in `references/walkthrough-contract.md`.
Use its default script beats as the canonical sequence.
Every scene must map to observable evidence.

### 4. Capture evidence first

Before recording the final walkthrough:

- collect before/after screenshots, clips, command output, or diagrams
- capture the happy path
- if the PR claims behavioral parity, capture that happy path in the real app, not only in logs or tests
- capture one key edge, failure, or invariant when it materially affects confidence
- identify the single automated check that best protects this change
- identify the minimum regression suite that proves the branch did not break adjacent behavior
- verify the capture path is rendering the real app shell and styles before you trust any screenshot or recording

The walkthrough artifact is not enough on its own. The evidence must stand on its own if the video is skipped.
But the inverse is also true: a text-only summary is not enough if the PR claim depends on observable behavior.

### 5. Produce the artifact

Preferred order:

1. screenshot bundle when the claim is static and there is no meaningful action to demonstrate
2. deterministic browser or terminal walkthrough when an action, transition, or workflow matters
3. mixed walkthrough when the change is internal but the merge claim includes user-visible behavioral parity
4. optional polished Remotion cut with narration or music

Store scratch and canonical media in `/tmp` or another ignored ephemeral location by default. Only commit artifacts when the repo explicitly wants tracked evidence or when no other durable delivery works.

Never block a PR on a cinematic pass if the deterministic walkthrough is already strong and truthful.
Never record a motionless video just because "video" sounds richer than screenshots.
If you choose video, the recording must show the actual action being performed and the resulting state change or interaction.
When the claim is "still works" after a refactor, the deterministic walkthrough is not strong enough unless the artifact also shows the real flow still working.

### 6. Tie it to persistent verification

Every walkthrough must name the test, smoke check, or CI job that now protects the path it demonstrates.

If no durable automated check exists:

- add one when feasible
- otherwise call out the gap explicitly and make fixing it the next quality task
- and do not pretend the walkthrough alone proves regression safety

### 7. Update the PR body

Add a top-level `## Reviewer Evidence` section before the narrative when the PR has user-visible evidence.

For private repositories:

- do not use `raw.githubusercontent.com/...` image links in PR bodies or comments
- do not use bare repo-relative asset paths like `walkthrough/screenshots/foo.png`
- prefer GitHub-uploaded attachments for screenshots and video when you can upload through the web UI or browser automation
- otherwise use GitHub's documented private-repo-safe pattern: `../blob/<ref>/path/to/image.png?raw=true`
- for repo-hosted video fallback, use an explicit direct-download link such as `../blob/<ref>/path/to/video.mp4?raw=1`
- if the branch has multiple committed artifacts, use a PR- or branch-scoped entrypoint such as `walkthrough/pr-<N>/reviewer-evidence.md` or `walkthrough/<branch-slug>/reviewer-evidence.md`
- never use a repo-global shared filename like `walkthrough/reviewer-evidence.md`

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
- A text walkthrough with no observable artifact is invalid.
- Claims about real behavior must be backed by real execution captures, not inferred from reading code.
- An unstyled screenshot from a renderer harness is a capture failure until proven otherwise, not valid product evidence.
- For user-visible flows, default to screencast plus screenshots unless the proof is truly static.
- For non-UI work, default to terminal capture plus diagrams unless a stronger renderer is warranted.
- For internal refactors that claim no functional regression, default to mixed evidence: a short real-app screencast of the critical happy path plus terminal/runtime proof.
- If nothing moves, use screenshots instead of video.
- If something important does move, record the real action and its result. Do not ship idle footage that is visually indistinguishable from a screenshot.
- Remotion is encouraged for high-value communication, not as a substitute for proof.
- If the PR changes nothing user-visible, narrate invariants, architecture, and verification instead.
- If the PR claims a user-visible path still works, the artifact must show that path working. Terminal logs, tests, and diagrams support that claim but do not substitute for it.
- In private repos, attachment URLs or GitHub-relative blob links are part of the artifact quality bar. Broken media links are a walkthrough failure.
- Shared repo artifact paths are a workflow bug. Evidence must be ephemeral by default or uniquely scoped when committed.

## References

- `references/walkthrough-contract.md` - renderer selection, script rubric, and PR section template
