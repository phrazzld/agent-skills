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

### 1. Gather diff

```bash
git diff main...HEAD
```

Or use the specified scope (branch, files, commit range).

### 2. Launch all reviewers in parallel

Spawn all 5 in a single message — they run concurrently:

```
# In one message, spawn all of these:
Agent(subagent_type: "critic", prompt: "Review this diff. [diff]. Verdict: Ship/Don't Ship. Top 3 concerns (file:line + fix). Best thing about this code.")
Agent(subagent_type: "ousterhout", prompt: "Review this diff for module depth, information hiding, interface simplicity. [diff]. Verdict + concerns.")
Agent(subagent_type: "carmack", prompt: "Review this diff for shippability, over-engineering, speculative generality. [diff]. Verdict + concerns.")
Agent(subagent_type: "grug", prompt: "Review this diff for complexity. Too many layers? Too clever? [diff]. Verdict + concerns.")
Agent(subagent_type: "beck", prompt: "Review this diff for test quality. TDD? One behavior per test? Edge cases? [diff]. Verdict + concerns.")
```

If the harness doesn't support 5 concurrent sub-agents, run critic first,
then the philosophy bench in parallel (4), or run all sequentially.

### 3. Collect and synthesize

Each reviewer returns: Ship/Don't Ship + concerns + best thing.
Deduplicate findings. Rank by severity.

### 4. Gate

- **All Ship** → approve, proceed to merge
- **Any Don't Ship** → dispatch builder sub-agent to fix the blocking concern:
  ```
  Agent(subagent_type: "builder", prompt: "Fix this blocking issue: [concern with file:line and specific fix instruction]. Run tests after fixing.")
  ```
- Re-review after fixes (return to step 2). Max 3 iterations.

### 5. Escalate

If still blocked after 3 iterations → report findings to user, ask for judgment.

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
