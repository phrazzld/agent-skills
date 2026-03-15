# Walkthrough Contract

The walkthrough proves the merge claim with the smallest truthful artifact a skeptical reviewer can trust.

## Five Questions

1. What was wrong, missing, risky, or expensive before this branch?
2. What changed?
3. What is observably better or safer now?
4. What evidence proves that claim?
5. What persistent check protects the path going forward?

## Evaluation Rubric

| Dimension | Question |
|-----------|----------|
| Significance | Does it explain why the change matters now? |
| Baseline | Does it show the real before state? |
| Delta | Does it make the branch delta legible? |
| Proof | Does each major claim map to a capture? |
| Behavioral proof | If the PR claims the app still works, does it show the app working? |
| Protection | Does it link to a durable automated check? |
| Residual risk | Does it say what is still not proven? |

## Renderer Selection

| Situation | Capture method |
|-----------|---------------|
| Frontend UX with interaction | Browser GIF via `gif_creator` + before/after screenshots |
| Static UI delta | Screenshot bundle |
| CLI or developer workflow | Terminal output capture |
| Backend or API change | Terminal output + request/response traces |
| Infra, CI, architecture | Terminal output + optional diagrams |
| Internal refactor with parity claim | App GIF (happy path) + terminal proof |

## Motion Rule

- GIF/video only when motion is part of the proof
- If the truth is visible in a still frame, screenshot
- A recording of a motionless screen is a failed artifact

## Behavioral Parity Rule

- "No regression" / "still works" = behavioral claim = needs behavioral proof
- Terminal evidence alone is insufficient for parity claims on user-visible surfaces
- Record the real happy path in the app

## Evidence Quality Bar

- A text memo is support material, not the artifact
- The artifact must show real execution on the branch under review
- If no durable artifact can be produced, surface the blocker — don't ship without proof
