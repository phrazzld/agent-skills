# Walkthrough Contract

Every PR needs one walkthrough package that answers five questions:

1. What was wrong, missing, risky, or expensive before this branch?
2. What changed?
3. What is observably better or safer now?
4. What evidence proves that claim?
5. What persistent check protects the path going forward?

## Evaluation Rubric

Judge every walkthrough against this rubric:

| Dimension | Question |
|-----------|----------|
| Significance | Does it explain why the change matters now? |
| Baseline | Does it show the real before state instead of hand-waving it? |
| Delta | Does it make the branch delta legible? |
| Proof | Does each major claim map to evidence? |
| Protection | Does it link the story to a durable automated check? |
| Residual risk | Does it say what is still not proven? |

## Renderer Selection

| Situation | Best format | Evidence to include |
|-----------|-------------|---------------------|
| Frontend UX or workflow with meaningful interaction | Browser recording | before/after screenshots, happy path, one key edge case |
| Static UI delta or non-interactive visual proof | Screenshot bundle | before/after screenshots, annotations, protecting check |
| CLI or developer workflow | Terminal walkthrough | commands, expected output, before/after behavior |
| Backend or API change | Terminal plus diagrams | request/response traces, data/state change, regression test |
| Infra, CI, architecture, refactor | Diagram-led walkthrough | old vs new flow, invariants preserved, proof commands |
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

## Evidence Mapping

For each scene, capture at least one of:

- screenshot
- browser clip
- command output
- test result
- diagram
- data diff

If a scene has no evidence, cut or rewrite the claim.

## Motion Rule

- Use video only when motion is part of the proof: a user action, animation, state transition, navigation flow, drag/drop, async update, or other observable behavior.
- If the truth can be understood from a still frame, prefer screenshots.
- A video that shows no action is a failed artifact, not a richer screenshot.
- If recording a flow, perform the real action in the recording and hold long enough to show the resulting state.

## PR Body Template

Every PR should include a section like this:

```md
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
