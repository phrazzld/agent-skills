---
name: night-shift
description: |
  Autonomous multi-hour implementation from a spec. Strict spec/implement separation.
  Humans write specs during the day; the agent implements overnight.
  Use when: "night shift", "implement overnight", "autonomous build",
  "build this while I sleep", "long-running implementation".
  Trigger: /night-shift.
trigger: night-shift
category: build
---

# Night-Shift

Autonomous multi-hour implementation from a spec. The human provides judgment
and taste (via a context packet or spec). The agent provides labor.

> "I do not want to read agent plans. I do not want to sit and prompt and
> reprompt agents." — Jamon Holmgren

## When to Use

- Implementation is well-scoped with a clear context packet or spec
- The work is >1 hour of agent time
- You want to review a PR in the morning, not sit through the build
- The oracle (definition of done) is mechanically verifiable

NOT for: exploratory work, design decisions that need human judgment mid-stream,
anything where the spec is vague. If you can't write an oracle, you can't
night-shift it.

## Prerequisites

1. **Context packet** — write one with `/context-packet` first. The oracle is
   non-negotiable. If the agent can't verify its own work, it will produce
   plausible-looking output that doesn't actually work.

2. **Tests or verifiable criteria** — the agent's primary feedback loop. Without
   mechanical verification, the agent has no way to know if it's on track.

3. **Clean branch** — start from a clean state. The agent will create commits
   and a PR.

## The Protocol

### Phase 1: Validate Spec

Read the context packet. Verify:
- Goal is a single verifiable sentence
- Oracle has mechanically checkable criteria
- Repo anchors exist and are readable
- Non-goals are explicit (the "helpful creativity" kill switch)

If any are missing, STOP and ask the human. Do not proceed with a vague spec.

### Phase 2: Plan

Decompose the work into sprints. Each sprint:
- Implements one feature or capability
- Has its own subset of the oracle criteria
- Can be verified independently
- Builds on the previous sprint

Write the plan to a file so it survives context resets. This is the structured
handoff artifact that carries state between sessions.

### Phase 3: Build Loop

For each sprint:

```
1. Write failing tests (from oracle criteria for this sprint)
2. Implement until tests pass
3. Run full test suite — no regressions
4. Run linters — all clean
5. Self-evaluate against sprint criteria
6. Commit with semantic message
7. Move to next sprint
```

**Context management:** If the context window is filling up, do a context reset
rather than letting the model degrade. Write a handoff artifact with:
- What's done (sprint N completed, all tests passing)
- What's next (sprint N+1: implement X)
- Key decisions made and why
- Current state of the codebase

The handoff must contain enough state for a fresh agent to continue cleanly.

### Phase 4: QA

After all sprints complete, run a full evaluation pass:
- All oracle criteria from the context packet
- Full test suite
- Linter/typecheck
- If the project has a browser-testable UI: exercise it via Playwright/CDP

If QA fails, iterate. Fix issues and re-verify.

### Phase 5: Ship

- Create a PR with the full context packet in the description
- Link to the original issue if one exists
- Include a summary of what was built, sprint by sprint
- Flag any oracle criteria that couldn't be verified mechanically

## Key Lessons (from Anthropic's Harness Design Research)

**Decompose into sprints.** Models lose coherence on lengthy tasks as context
fills. Working one feature at a time keeps the agent focused.

**Context resets > compaction.** Compaction preserves continuity but doesn't
give the agent a clean slate. Context anxiety can persist through compaction.
Resets with structured handoffs are more reliable for long tasks.

**Separate generator from evaluator.** When asked to evaluate their own work,
agents consistently overrate quality. The QA phase should apply skeptical
grading criteria, not ask "is this good?"

**Grading criteria make quality measurable.** "Is this design good?" is hard
to answer. "Does this follow our principles?" gives the agent something
concrete to grade against. Use the assess-* pipeline for structured evaluation.

**Strip non-load-bearing scaffold.** Every harness component encodes an
assumption about model limitations. As models improve, re-examine: is the
sprint structure still needed? Is the context reset still needed? Test
removing components one at a time and measure impact on output quality.

## Anti-Patterns

- Proceeding without a clear oracle (you'll get plausible-looking garbage)
- Skipping the plan phase ("just build it" → scope drift)
- Not committing between sprints (no rollback points)
- Ignoring QA failures ("it mostly works" → it doesn't)
- Running night-shift on exploratory work (exploration needs human judgment)

## Related

- `/context-packet` — write the spec that night-shift implements
- `/autopilot` — similar pipeline but interactive, not autonomous
- `/shape` — design the spec before handing off to night-shift
- `/settle` — polish the PR that night-shift produces
