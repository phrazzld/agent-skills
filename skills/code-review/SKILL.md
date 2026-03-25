---
name: code-review
description: |
  Parallel multi-agent code review. Launch reviewer team, synthesize findings,
  auto-fix blocking issues, loop until clean.
  Use when: "review this", "code review", "is this ready to ship",
  "check this code", "review my changes".
  Trigger: /code-review, /review, /critique.
argument-hint: "[branch|diff|files]"
---

# /code-review

Launch a parallel team of reviewers. Synthesize findings. Fix blocking issues
automatically. Loop until clean or escalate to human.

## Architecture

Five sub-agents in parallel, each with a distinct lens:

- **critic** — generalist evaluator, grades against criteria below
- **ousterhout** — deep modules, information hiding, interface simplicity
- **carmack** — pragmatic shippability, over-engineering detection
- **grug** — complexity hunting, layer counting
- **beck** — TDD quality, one behavior per test, red-green-refactor

Optional external reviewers: Think Tank CLI, Cerberus CLI.

## Workflow

### 1. Gather the diff

Get the diff via `git diff main...HEAD` or the specified scope.

### 2. Launch all reviewers in parallel

Spawn all five sub-agents simultaneously in a single message. Give each the
full diff and relevant codebase context. Each reviewer should return:
- **Ship / Don't Ship** verdict
- Top 3 concerns (file:line + specific fix)
- One sentence: best thing about this code

If the harness limits concurrency, run the critic first, then the four
philosophy agents in parallel, or run all sequentially as a fallback.

### 3. Synthesize

Collect all verdicts. Deduplicate overlapping concerns. Rank by severity.

### 4. Gate

- **All Ship** → approve, proceed to merge
- **Any Don't Ship** → spawn a builder sub-agent for each blocking concern,
  giving it the specific file:line and fix instruction. Builder fixes, runs
  tests. Then re-review (return to step 2). Max 3 iterations.

### 5. Escalate

If still blocked after 3 iterations, report all findings to the user.
The issue needs human judgment.

## Grading Criteria

The critic applies structured grading (adapt per project):

| Criterion | Weight | Measures |
|-----------|--------|----------|
| **Correctness** | 30% | Tests pass? Edge cases? Does it actually work? |
| **Depth** | 25% | Deep modules with simple interfaces, or shallow pass-throughs? |
| **Simplicity** | 25% | Minimum complexity? Would you add or delete? |
| **Craft** | 20% | Error handling, naming, consistency with codebase |

Weight correctness and depth higher — models score well on craft by default
but underperform on architectural depth and actual correctness.

## Simplification Pass

After review passes, if diff > 200 LOC net:
- Look for code that can be deleted
- Collapse unnecessary abstractions
- Simplify complex conditionals
- Remove compatibility shims with no real users

## Output

```markdown
## Code Review Summary

**Verdict:** Ship / Don't Ship / Escalated

### Findings
| Severity | File:Line | Issue | Fix |
|----------|-----------|-------|-----|
| blocking | src/auth.ts:42 | Leaky abstraction | Extract to module |

### Reviewer Consensus
- critic: Ship
- ousterhout: Ship
- carmack: Don't Ship — over-engineered auth layer
- grug: Ship
- beck: Ship

### Iterations: 2 (fixed auth layer on iteration 2)
```

## Gotchas

- **Self-review leniency:** Models consistently overrate their own work. The critic must be a separate sub-agent, not the builder evaluating itself.
- **Reviewing the whole codebase:** Review the diff, not the repo. `git diff main...HEAD` is the scope.
- **Vague feedback:** "Needs improvement" is useless. Every concern must have file:line + specific fix.
- **Infinite loop:** Cap at 3 review iterations. If still blocked, escalate — the issue needs human judgment.
- **Skipping the bench:** Running only the critic misses structural issues. The philosophy agents add perspectives the critic doesn't cover.
- **Treating all concerns equally:** Blocking issues (correctness, security) gate shipping. Style preferences don't.
