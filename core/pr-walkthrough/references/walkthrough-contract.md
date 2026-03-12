# Walkthrough Contract

Every PR needs one walkthrough package that answers five questions:

1. What was wrong, missing, risky, or expensive before this branch?
2. What changed?
3. What is observably better or safer now?
4. What evidence proves that claim?
5. What persistent check protects the path going forward?

The package must include observable proof from real execution. Narrative alone is not enough.
Its purpose is reviewer confidence: prove the branch claim with the smallest truthful artifact that a skeptical reviewer can trust.

## Evaluation Rubric

Judge every walkthrough against this rubric:

| Dimension | Question |
|-----------|----------|
| Significance | Does it explain why the change matters now? |
| Baseline | Does it show the real before state instead of hand-waving it? |
| Delta | Does it make the branch delta legible? |
| Proof | Does each major claim map to evidence? |
| Behavioral proof | If the PR claims the app still works, does it show the app working? |
| Protection | Does it link the story to a durable automated check? |
| Residual risk | Does it say what is still not proven? |

## Renderer Selection

| Situation | Best format | Evidence to include |
|-----------|-------------|---------------------|
| Frontend UX or workflow with meaningful interaction | Browser recording | before/after screenshots, happy path, one key edge case |
| Static UI delta or non-interactive visual proof | Screenshot bundle | before/after screenshots, annotations, protecting check |
| CLI or developer workflow | Terminal walkthrough | commands, expected output, before/after behavior |
| Backend or API change | Terminal plus diagrams | request/response traces, data/state change, regression test |
| Infra, CI, architecture, refactor | Terminal walkthrough plus diagrams | old vs new flow, invariants preserved, proof commands, runtime or test output |
| Internal refactor with a behavioral-parity claim | Mixed: app screencast plus terminal walkthrough | real happy path in the app, proof commands, runtime/test output, residual gap |
| Broad launch or stakeholder update | Remotion video | narration, diagrams, screenshots, optional music/voiceover |

Use mixed media when one renderer is insufficient.

## Default Script

Use this script unless the PR needs a stronger variant:

1. **Title**
   The PR name and one-sentence merge claim.
2. **Why now**
   The pain, risk, or opportunity that justified the work.
3. **Before**
   Show the old behavior, system state, or workflow.
4. **What changed**
   Summarize the key branch delta in human terms.
5. **After**
   Show the new behavior, system state, or workflow.
6. **Verification**
   Run or cite the automated check that protects this path.
7. **Residual risk**
   State what remains unproven or intentionally deferred.
8. **Merge case**
   Close with why shipping this branch is worth it.

If the PR claims behavioral parity after a refactor, the "After" scene must include a real app flow, not only terminal output.

## Evidence Mapping

For each scene, capture at least one of:

- screenshot
- browser clip
- command output
- test result
- diagram
- data diff

If a scene has no evidence, cut or rewrite the claim.
If the whole walkthrough has no observable execution evidence, it fails review.
If the walkthrough claims the app still functions, one scene must show the real app functioning.

## Media Delivery Rules

The evidence must render or open cleanly for reviewers in the live PR.

Preferred order:

1. GitHub-uploaded attachments for screenshots and video
2. GitHub-relative blob links for private-repo screenshots: `../blob/<ref>/path/to/image.png?raw=true`
3. Explicit direct-download blob links for repo-hosted video fallback: `../blob/<ref>/path/to/video.mp4?raw=1`

When repo-hosted artifacts are unavoidable, use PR- or branch-unique paths such as `walkthrough/pr-123/...` or `walkthrough/<branch-slug>/...`.
Scratch output should live in `/tmp` or another ignored ephemeral location.

Avoid:

- `raw.githubusercontent.com/...` in private-repo PR bodies or comments
- bare repo-relative asset paths like `walkthrough/screenshots/foo.png` in PR bodies or comments
- shared filenames like `walkthrough/reviewer-evidence.md` for PR-local evidence
- plain blob links to `.mp4` files that dump reviewers into the code viewer without warning

If the branch has more than one committed artifact, add a PR- or branch-scoped reviewer-evidence entrypoint and link it from the top of the PR.

## Motion Rule

- Use video only when motion is part of the proof: a user action, animation, state transition, navigation flow, drag/drop, async update, or other observable behavior.
- If the truth can be understood from a still frame, prefer screenshots.
- A video that shows no action is a failed artifact, not a richer screenshot.
- If recording a flow, perform the real action in the recording and hold long enough to show the resulting state.
- If motion is part of the claim, screenshots alone are not enough.
- If the claim is internal, commands and their outputs must still be captured from a real run.

## Behavioral Parity Rule

- "No regression", "behavior unchanged", "still works", and similar claims are behavioral claims.
- Behavioral claims require behavioral proof.
- For internal or architectural refactors, terminal evidence is necessary but not sufficient when the PR also claims the product still functions.
- In those cases, record a short real end-to-end happy path in the app and pair it with the structural/runtime proof.
- If no practical way exists to capture that flow, stop and surface the missing harness or automation as a blocker instead of pretending the claim is proven.

## PR Body Template

Every PR should include a section like this:

```md
## Reviewer Evidence

- Start here: [PR-scoped reviewer evidence file or attachment comment]
- Direct video download: [artifact]
- Walkthrough notes: [artifact]
- Fast claim: [one sentence]

## Walkthrough

- Renderer: Screenshot bundle | Browser walkthrough | Terminal walkthrough | Remotion walkthrough | Mixed
- Artifact: [link to video or walkthrough bundle]
- Claim: [the single sentence this walkthrough proves]
- Before / After scope: [what surfaces are covered]
- Persistent verification: `[exact test, smoke check, or CI job]`
- Residual gap: [what still is not automated or not shown]
```

## Persistent Check Rule

The walkthrough should produce or reinforce one durable protection:

- E2E test for user flow changes
- integration or contract test for API/backend changes
- smoke test or CI assertion for infra/tooling changes
- regression test for bug fixes

If the walkthrough reveals a path that matters and nothing protects it, that is a quality finding.

## Evidence Quality Bar

- A text memo is support material, not the artifact.
- The artifact must prove the branch claim with real execution on the branch under review.
- The artifact must also show the regression guardrails that were actually run.
- If the branch claim includes functional parity, the artifact must show functional parity directly.
- If the branch changes behavior and no durable artifact can be produced, stop and surface the blocker instead of shipping.
