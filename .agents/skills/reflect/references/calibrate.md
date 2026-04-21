# /reflect calibrate

Mid-session harness postmortem.

Use this when the agent made a wrong decision and the priority is to fix the
system before continuing with the task.

## Objective

The harness fix is the real deliverable. The code fix should become obvious
after the harness is corrected.

## Workflow

### 1. Name the bad call

Describe the incorrect decision in one sentence.

Examples:
- wrong tool choice
- skipped obvious repo context
- asked an unnecessary question
- implemented before understanding
- overfit on code and missed workflow guidance

### 2. Apply the Norman Principle

Do not ask "why did the agent fail?"
Ask:

**How did it make sense for the agent to do that given what it saw?**

This reveals the missing context or misleading instruction that made the error
rational.

### 3. Walk the Swiss Cheese layers

Check the layers in order:
- **Instructions** — missing, stale, or conflicting guidance
- **Skills** — missing skill, bad routing, stale references, weak trigger phrases
- **Hooks/guardrails** — missing automatic prevention
- **Tools/environment** — broken or unavailable tool, undocumented setup
- **Agent reasoning** — only after upper layers are ruled out

Induction errors outrank all other findings:
- the harness told the agent the wrong thing
- the harness omitted load-bearing context
- the skill shape encouraged the wrong move

### 4. Separate harness from operator feedback

If the user's prompt truly lacked decisive information that only they knew,
note that as an operator-spec gap.

But:
- repo context missing from the agent is not the user's fault
- unused available tools are not the user's fault
- stale skill docs are not the user's fault

### 5. Fix at the highest-leverage layer

Use the codification hierarchy:

```
Type system > Lint rule > Hook > Test > CI > Skill/reference > AGENTS.md > Memory
```

Choose the smallest fix that prevents recurrence across future sessions.

### 6. Resume the task

Once the harness fix exists, return to the original task.
The code or workflow correction should now be narrower and easier.

## Report Format

```markdown
## Bad Call
- [what the agent did]

## How It Made Sense
- [missing or misleading context]

## System Fix
- [artifact changed] -> [why this prevents recurrence]

## Operator Note
- [only if a true operator-spec gap existed]

## Resume Plan
- [what to do next in the original task]
```

## Gotchas

- **Teaching burner mappings**: prose-only reminders instead of structural fixes
- **Fixing code before the harness**: symptom patching
- **Dumping blame downward**: if upper layers failed, do not call it reasoning failure
- **Turning every issue into user coaching**: calibrate is system-first
