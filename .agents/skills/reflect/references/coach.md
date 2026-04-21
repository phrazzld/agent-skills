# /reflect coach

Deep operator-coaching pass for the human side of the collaboration.

Use this when the user wants to understand:
- how their prompts shaped the session
- what technical specificity would have helped sooner
- what concepts or vocabulary they should keep on the shelf for next time

`distill` already includes a lightweight operator lane.
`coach` expands that lane into the main deliverable.

## Objective

Make the user measurably better at steering future sessions.

This mode is not about blame.
It is about turning session friction into reusable prompting moves and durable
technical concepts.

## Workflow

### 1. Build a prompt timeline

Trace the session from:
- initial ask
- first correction or clarification
- turning points where scope sharpened
- final form of the request that actually unlocked progress

Capture the delta between the early prompt and the decisive prompt.

### 2. Score the prompts on useful dimensions

Use these dimensions:

| Dimension | Question |
|-----------|----------|
| **Goal clarity** | Was the desired outcome explicit? |
| **Scope control** | Was it clear what was in or out? |
| **Constraints** | Did the prompt say what must not change? |
| **Acceptance criteria** | Could the agent tell what "done" meant? |
| **Context anchors** | Did it point to files, docs, tools, or prior decisions? |
| **Depth request** | Did it ask for brainstorming, design, implementation, review, or teaching? |
| **Learning intent** | Did it say the user wanted explanation, concepts, or vocabulary growth? |

Do not output numeric scores unless they help. Short evidence-backed notes are
usually better.

### 3. Rewrite prompts, not just advice

For each high-leverage gap, provide:
- **Observed issue**
- **Before** — the weaker prompt pattern
- **After** — the stronger prompt
- **Why it works** — what ambiguity it removes

Prefer rewrites that preserve the user's natural style.
Do not turn every prompt into a sterile template.

### 4. Extract the concept shelf

Curate 3-7 concepts that became load-bearing during the session.

For each concept, provide:
- **Term**
- **Definition**
- **Why it mattered in this session**
- **When to use it in future prompts or design discussions**

Prioritize concepts that improve steering power:
- acceptance criteria
- control layer
- retrieval failure
- reference-backed router
- blast radius
- scope boundary

### 5. Identify the missing mental models

Look for places where the user likely benefited from having a clearer model of:
- the codebase
- the harness
- the stack
- the workflow

Translate those into short, usable explanations.

Good:
- "This skill wants to be a router, not a monolith, because mode-specific detail
  belongs in references and the top-level skill pays a constant description tax."

Bad:
- "Skills should be better structured."

### 6. End with next-session prompts

Produce 3 concrete prompt patterns the user can reuse next time.

Good examples:
- "Review `skills/reflect` as a router-pattern problem. I want a minimal skill
  file plus reference-backed modes. Tell me if AGENTS.md should change or not."
- "Implement this, but keep these boundaries fixed: no new dependency, no README
  churn unless behavior changes, and explain the tradeoff you chose."
- "I want two outputs: the code change and a short teaching section that names
  the concepts I should remember."

## Output Contract

```markdown
## What Already Worked
- [strength in the user's prompting or collaboration]

## Prompt Rewrites
- [issue] -> [stronger prompt] -> [why it helps]

## Concept Shelf
- [term]: [definition]. Use when [situation].

## Missing Mental Models
- [concept]: [short explanation tied to the session]

## Next 3 Prompts To Try
- [reusable prompt pattern]
```

## Gotchas

- **Template maximalism**: give reusable structure, not bureaucratic prompts
- **Concept dumping**: teach the few concepts that moved decisions, not everything
- **Style erasure**: improve the user's prompts without flattening their voice
- **Unfair critique**: do not coach the user for information the system should
  have found on its own
