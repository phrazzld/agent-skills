# Systematic Debugging Protocol

Absorbed from the `systematic-debugging` skill.

## Core Principle

Random fixes waste time and create new bugs. ALWAYS find root cause before
attempting fixes. Symptom fixes are failure.

## When to Use

Use for ANY technical issue: test failures, production bugs, unexpected behavior,
performance problems, build failures, integration issues.

Use ESPECIALLY when:
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- You don't fully understand the issue

## Phase 1: Root Cause Investigation (Detail)

### Multi-Component Evidence Gathering

WHEN system has multiple components (CI -> build -> signing, API -> service -> database):

BEFORE proposing fixes, add diagnostic instrumentation:

```
For EACH component boundary:
  - Log what data enters component
  - Log what data exits component
  - Verify environment/config propagation
  - Check state at each layer

Run once to gather evidence showing WHERE it breaks
THEN analyze evidence to identify failing component
THEN investigate that specific component
```

### Data Flow Tracing

WHEN error is deep in call stack:

- Where does bad value originate?
- What called this with bad value?
- Keep tracing up until you find the source
- Fix at source, not at symptom

## Phase 4.5: Architecture Check (After 3+ Failed Fixes)

Pattern indicating architectural problem:
- Each fix reveals new shared state/coupling/problem in different place
- Fixes require "massive refactoring" to implement
- Each fix creates new symptoms elsewhere

STOP and question fundamentals:
- Is this pattern fundamentally sound?
- Are we "sticking with it through sheer inertia"?
- Should we refactor architecture vs. continue fixing symptoms?

Discuss with user before attempting more fixes. This is NOT a failed
hypothesis -- this is a wrong architecture.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too |
| "Emergency, no time" | Systematic is FASTER than guess-and-check |
| "Just try this first" | First fix sets the pattern |
| "Multiple fixes at once saves time" | Can't isolate what worked |
| "I see the problem, let me fix it" | Seeing symptoms != understanding root cause |
| "One more fix attempt" (after 2+) | 3+ failures = architectural problem |

## The Scientific Method (One Experiment at a Time)

Debugging is empirical science. Apply the method rigorously:

1. **Examine** what you know about the software's behavior, construct a hypothesis
   about what might cause it.
2. **Design an experiment** that tests the hypothesis. Justify: why this experiment,
   what will it tell us? If you can't justify it, you don't understand the problem.
3. **If disproved** — new hypothesis. Ruling things out is progress. This step
   eliminates unrelated issues and narrows the search space.
4. **If supported** — keep experimenting until either disproved or proven with high
   confidence. "Supported" is not "proven."

**One experiment at a time.** Multiple simultaneous changes make it impossible to
attribute results. If you changed two things and the bug disappeared, you don't
know which fixed it — and the other change may introduce a new bug later.

## Instrumented Reproduction

When the bug requires human reproduction (can't trigger programmatically):

```
Agent instruments → User reproduces → Agent reads logs → Refine → Repeat
```

Key rules:
- Tag log lines with the hypothesis they test: `[H1]`, `[H2]`
- Log at decision points, not everywhere (targeted, not shotgun)
- Write to a single file the user can find easily (`~/Desktop/debug-*.log`)
- Max 3 instrumentation rounds — if still ambiguous, escalate
- ALWAYS clean up instrumentation after diagnosis

## Supporting Techniques

- **Root cause tracing**: Trace bugs backward through call stack
- **Defense in depth**: Add validation at multiple layers after finding root cause
- **Condition-based waiting**: Replace arbitrary timeouts with condition polling
