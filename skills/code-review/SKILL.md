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

```
Orchestrator (you)
├── critic (generalist evaluator — grades against criteria)
├── ousterhout (deep modules, information hiding)
├── carmack (pragmatic shippability)
├── grug (complexity hunting)
└── beck (TDD, simple design)
```

Optional external reviewers: Think Tank CLI, Cerberus CLI, other model APIs.

## Workflow

1. **Gather diff** — `git diff main...HEAD` or specified scope
2. **Launch reviewers in parallel** — each gets the full diff + context
3. **Collect verdicts** — each reviewer returns:
   - **Ship / Don't Ship** verdict
   - Top 3 concerns (file:line + specific fix)
   - One sentence: best thing about this code
4. **Synthesize** — deduplicate findings, rank by severity
5. **Gate decision:**
   - All Ship → approve, proceed to merge
   - Any Don't Ship → dispatch builder sub-agents to fix concerns
   - Re-review after fixes (return to step 1)
   - Loop until clean or max 3 iterations
6. **If stuck after 3 iterations** — escalate to human with findings summary

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

## Philosophy Agent Perspectives

Each philosophy agent brings a distinct lens:

- **ousterhout**: "Is this the right abstraction? Are modules deep? Is information hidden?"
- **carmack**: "Does this ship? Is it over-engineered? Would you deploy this today?"
- **grug**: "Is this too complex? Too many layers? Would a junior understand it?"
- **beck**: "Is this tested correctly? Red-green-refactor? One behavior per test?"

The most conservative reviewer wins — if any single reviewer says "Don't Ship",
the concern gets addressed before proceeding.

## Auto-Fix Loop

When blocking issues are found:
1. Parse each concern into an actionable fix
2. Dispatch builder sub-agent(s) with specific fix instructions
3. Builder implements fix, runs tests
4. Re-trigger review on the updated diff
5. Repeat until clean or escalate

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
- critic: Ship ✓
- ousterhout: Ship ✓
- carmack: Don't Ship — over-engineered auth layer
- grug: Ship ✓
- beck: Ship ✓

### Iterations: 2 (fixed auth layer on iteration 2)
```

## Gotchas

- **Self-review leniency:** Models consistently overrate their own work. The critic must be a separate agent, not the builder evaluating itself.
- **Reviewing the whole codebase:** Review the diff, not the repo. `git diff main...HEAD` is the scope.
- **Vague feedback:** "Needs improvement" is useless. Every concern must have file:line + specific fix.
- **Infinite loop:** Cap at 3 review iterations. If still blocked, escalate — the issue needs human judgment.
- **Skipping philosophy agents:** Running only the critic misses structural issues. The bench adds distinct perspectives the critic doesn't cover.
- **Treating all concerns equally:** Blocking issues (correctness, security) gate shipping. Style preferences don't.
