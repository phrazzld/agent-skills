---
name: evaluator
description: |
  GAN-inspired evaluation pattern: separate the agent judging work from the
  agent doing work. Grading criteria turn subjective quality into concrete,
  gradable terms. Calibrate with few-shot examples.
  Use when: reviewing agent output, QA pass, "evaluate this", "grade this",
  "is this good enough", "run QA", "evaluate quality".
  Trigger: /evaluate, /qa-eval.
trigger: evaluate|qa-eval
category: quality
---

# Evaluator

Separate the agent doing the work from the agent judging it. Self-evaluation
is unreliable — agents consistently overrate their own output. An independent
evaluator with calibrated grading criteria is a strong lever for quality.

> "Whether a layout feels polished or generic is a judgment call, and agents
> reliably skew positive when grading their own work." — Anthropic

## When to Use

- After any significant agent-generated output (code, design, spec)
- As the QA phase in `/night-shift` or `/autopilot`
- When subjective quality matters (design, UX, documentation tone)
- When you need structured, gradable feedback instead of "looks good"

NOT for: binary verification (tests pass/fail). Use tests for that.
The evaluator adds value where quality is a spectrum, not a boolean.

## The Pattern

### 1. Define Grading Criteria

Each criterion must be:
- **Concrete** — "does this follow X principle" not "is this good"
- **Gradable** — scorable on a defined scale (1-10 or pass/marginal/fail)
- **Weighted** — emphasize what the model is weak at, not what it does well by default
- **Calibrated** — include examples of what scores look like at each level

Example criteria for code quality:

| Criterion | Weight | What it measures |
|-----------|--------|------------------|
| **Correctness** | 30% | Does it actually work? Tests pass? Edge cases handled? |
| **Depth** | 25% | Deep modules with simple interfaces, or shallow pass-throughs? |
| **Simplicity** | 25% | Minimum complexity for the task? Would you add more or delete? |
| **Craft** | 20% | Error handling, naming, consistency with existing patterns? |

Weight correctness and depth higher — models score well on craft by default
but underperform on architectural depth and actual correctness under edge cases.

### 2. Calibrate with Examples

Provide 2-3 few-shot examples with detailed score breakdowns. This anchors
the evaluator's judgment and prevents score drift across iterations.

```
Example: Score 8/10 on Depth
- AuthService exposes 2 methods (login, verify) but handles session
  management, token rotation, and rate limiting internally
- Clear information hiding — callers don't know about token storage
- One concern: the rate limiter could be extracted if reused elsewhere

Example: Score 4/10 on Depth
- AuthController, AuthService, AuthRepository, AuthMapper — 4 layers
  for what could be 1 module
- Each layer is a thin pass-through adding no information hiding
- Classic temporal decomposition: layers exist for "architecture" not need
```

### 3. Evaluate Actively

Don't score from a static snapshot. If the output is a running application:
- Navigate the UI, click through flows
- Test edge cases the generator likely didn't consider
- Check error states, empty states, loading states
- Verify the implementation matches the spec, not just "works"

If the output is code:
- Read the implementation, not just the tests
- Check that tests actually verify behavior (not just that they pass)
- Look for stubbed or placeholder implementations
- Verify cross-cutting concerns (error handling, logging, auth)

### 4. Write Actionable Feedback

For each criterion that falls below threshold:
- What specifically failed
- Where in the code/output (file:line or specific element)
- What "passing" would look like
- Whether to refine the current direction or pivot

Bad: "Design needs improvement"
Good: "FAIL — Originality 3/10. Purple gradient over white cards is the
default AI pattern. The color palette needs custom decisions. See the
brand guidelines for the project's actual color system."

### 5. Iterate or Accept

Set hard thresholds per criterion. If any criterion falls below its threshold,
the sprint fails and the generator gets detailed feedback.

The generator should make a strategic decision after each evaluation:
- **Refine** if scores are trending well
- **Pivot** if the approach isn't working after 2-3 iterations
- **Accept** if all criteria meet thresholds

Typical iteration count: 3-5 for code, 5-15 for design/subjective work.

## Adaptation Guide

The evaluator pattern is general. Adapt criteria for your domain:

**Frontend design:** Design quality, originality, craft, functionality.
Weight design and originality higher — models default to safe/generic.
Penalize "AI slop" patterns explicitly.

**API design:** Correctness, consistency, discoverability, error handling.
Weight consistency higher — models produce internally inconsistent APIs.

**Documentation:** Accuracy, completeness, freshness, actionability.
Weight accuracy highest — confident-sounding wrong docs are worse than gaps.

**Specs/plans:** Completeness, feasibility, risk coverage, oracle quality.
Weight oracle quality highest — a spec without verifiable criteria is a wish.

## Integration with Assess Pipeline

The assess-* skills are specific instantiations of this general pattern:
- `assess-depth` — evaluator for module depth and abstraction quality
- `assess-tests` — evaluator for test coverage and quality
- `assess-drift` — evaluator for architectural consistency
- `assess-simplify` — evaluator for unnecessary complexity
- etc.

Each assess-* skill has its own grading criteria, calibration examples, and
thresholds. They output structured JSON so the orchestrator can make
mechanical proceed/fix/escalate decisions.

## Anti-Patterns

- Evaluating your own work (the whole point is separation)
- Vague criteria ("is it good?" — grade against what?)
- No calibration examples (scores drift without anchoring)
- Ignoring threshold failures ("it's close enough" — it's not)
- Evaluating from a static snapshot when you could interact with the output

## Related

- `assess-*` — specific evaluator instances for code quality dimensions
- `/night-shift` — uses evaluator as QA phase
- `/autopilot` — uses assess pipeline for review
- `/context-packet` — the oracle section defines what the evaluator checks
