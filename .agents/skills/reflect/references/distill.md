# /reflect distill

End-of-session retrospective that upgrades both:
- the **system** that produced the work
- the **operator** who collaborated with it

This is the default reflect mode.

## Objective

Produce concrete artifacts and concrete lessons.

If the retro ends with only repo CRUD, it underfit the session.
If it ends with only vague advice, it also failed.

## Deliverables

Every `distill` run must inspect both lanes:

1. **System lane**
   - harness findings ranked by leverage
   - codification targets chosen by hierarchy
   - repo or harness edits applied when warranted

2. **Operator lane**
   - prompt-quality findings tied to real turns in the session
   - rewritten prompts that would have reduced search space
   - 3-7 reusable concepts or vocabulary items that became load-bearing
   - 1-3 concrete practices for the next session

System lane output is mandatory.
Operator lane output is mandatory only when there is concrete coaching to give.
Otherwise state `No high-leverage operator feedback this session.` and move on.

## Workflow

### 1. Gather evidence

Collect evidence from:
- the full conversation
- git diff, git log, and worktree state
- skill invocation logs when available
- AGENTS.md, CLAUDE.md, and touched skill docs
- any moments where the user corrected, redirected, or clarified the agent

Prefer specific turns, code changes, and corrections over impressions.

### 2. Split findings by responsibility

Classify each friction point:

| Class | Meaning | Typical fix |
|------|---------|-------------|
| **Harness failure** | The system should have prevented this | Hook, lint, test, skill, AGENTS |
| **Shared ambiguity** | Neither side made the decisive constraint explicit | Better prompts plus better skill guidance |
| **Operator-spec gap** | The key constraint existed only in the user's head | Coaching, prompt rewrite, concept extraction |

Use this rule aggressively:

**If the answer already existed in the repo, tools, or prompt context, do not
call it a user prompt problem.**

### 3. Run the system lane

Walk findings top-down through the Swiss Cheese layers:

| Layer | What to check | Finding type |
|-------|--------------|--------------|
| **Instructions** | Missing guidance, stale rules, conflicting directives | Highest priority |
| **Skills** | Missing skill, wrong description, skill that did not fire | High |
| **Hooks/guardrails** | Missing pre-commit check, no validation hook | High |
| **Tools/environment** | Missing MCP, broken tool, undocumented setup | Medium |
| **Agent reasoning** | Wrong decision with correct context available | Lowest |

Rank system findings by this order:
1. Harness induction errors
2. Missing control layers
3. Available-but-undiscovered information
4. Stale context
5. Tooling gaps
6. Workflow dead ends
7. Code-level findings

Apply codification hierarchy:

```
Type system > Lint rule > Hook > Test > CI > Skill/reference > AGENTS.md > Memory
```

### 4. Run the operator lane

Do not give vibes-based advice. Build an evidence-backed coaching pass.

#### Prompt archaeology

Find the turns where:
- the user goal was clear but constraints arrived late
- success criteria were implicit rather than stated
- the agent explored a wide search space that a better prompt could have bounded
- the user had to restate priority, scope, or desired output shape

For each, capture:
- **what the prompt did well**
- **what was missing**
- **a stronger rewrite**
- **why the rewrite changes the search space**

#### Specificity ladder

When rewriting prompts, look for missing details in this order:
1. **Goal** — what outcome matters?
2. **Scope** — what is in and out?
3. **Constraints** — what must not change?
4. **Acceptance criteria** — how will we know it is done?
5. **Artifacts** — code change, plan, summary, patch, benchmark, PR, etc.
6. **Context pointers** — files, commands, URLs, prior decisions
7. **Depth** — brainstorm, design, implement, review, or teach

If a prompt was already strong on some of these, say so explicitly.

#### Concept extraction

Extract 3-7 concepts that were load-bearing in the session:
- a term or phrase
- a one-line definition
- why it mattered here
- when the user should reach for it next time

Good concept cards are concrete:
- `router pattern`
- `reference integrity`
- `acceptance criteria`
- `codification hierarchy`
- `shared ambiguity`

Bad concept cards are generic:
- `AI`
- `coding`
- `improvement`

#### Next-session leverage

End with 1-3 habits the user can try immediately, for example:
- give acceptance criteria up front
- point to the decisive files instead of naming the area loosely
- say whether the goal is brainstorming, design, implementation, or critique

### 5. Pre-mortem the next session

Ask two questions:
- What failure mode will this same harness produce next?
- What failure mode will this same prompting style produce next?

Codify preventive fixes only if they clear the leverage bar.

## Report Format

```markdown
## System Changes
- [finding] -> [codification target] -> [fix applied or proposed]

## Operator Feedback
- [observed prompt gap] -> [stronger prompt] -> [why it helps]
- or `No high-leverage operator feedback this session.`

## Concepts To Keep
- [term]: [definition]. Use when [situation].

## Next Session Moves
- [habit or prompt pattern]

## Not Codified
- [finding]: [specific justification]

## Pre-Mortem
- [predicted system failure] -> [preventive fix]
- [predicted operator failure] -> [preventive move]
```

## Gotchas

- **Agent blame masquerading as user coaching**: If the system could have
  retrieved the answer, coaching the user is wrong.
- **Generic advice**: Replace "be more specific" with named missing fields.
- **Overloading the user**: Cap concepts and habits. Curate, do not dump.
- **Only praising or only criticizing**: operator feedback should start with
  what worked, then sharpen what did not.
- **Artifact-only retros**: a retro that changes files but teaches nothing is
  incomplete.
