---
name: harness
description: |
  Build, maintain, evaluate, and optimize the agent harness — skills, agents,
  hooks, CLAUDE.md, AGENTS.md, and enforcement infrastructure.
  Use when: "create a skill", "update skill", "improve the harness",
  "sync skills", "eval skill", "lint skill", "tune the harness",
  "add skill", "remove skill", "convert agent to skill".
  Trigger: /harness, /focus, /skill, /primitive.
argument-hint: "[create|eval|lint|convert|sync|engineer] [target]"
---

# /harness

Build and maintain the infrastructure that makes agents effective.

## Modes

| Mode | Intent |
|------|--------|
| **create** | Create a new skill or agent from scratch |
| **eval** | Test a skill with/without baseline comparison |
| **lint** | Validate skill quality against gates |
| **convert** | Convert a sub-agent definition to a skill (or vice versa) |
| **sync** | Pull primitives from spellbook into project harness dirs |
| **engineer** | Design harness improvements (hooks, enforcement, context) |

## Creating a Skill

### The description field is everything

The description determines when the model loads the skill. Write it assertively.
Include trigger phrases users actually say. If the skill doesn't fire, the
description is wrong — not the model.

**Good:** `"Use when: 'debug this', 'why is this broken', 'investigate', 'production down'"`
**Bad:** `"A debugging utility for code analysis"`

### Structure

```
skill-name/
├── SKILL.md          # < 500 lines. Core instructions.
├── references/       # Deep context loaded on demand.
└── scripts/          # Executable code for deterministic tasks.
```

### What to encode

Encode judgment the model lacks. Not procedures it already knows.

**Highest signal:** Gotchas — what goes wrong, not just what to do right.
A gotcha list is more valuable than pages of happy-path instructions.
Enumerate failure modes, common mistakes, things the model consistently
gets wrong without the skill.

**Avoid:** Step-by-step procedures the model can derive from context.
If you're writing "1. Read the file 2. Find the function 3. Edit it" —
that's not a skill, that's a task description.

### Progressive disclosure

Three layers. Each loads only when needed:

1. **Description** (~100 tokens) — always in context. Decides triggering.
2. **SKILL.md body** (< 500 lines) — loads when skill fires.
3. **References** (unlimited) — loaded on demand via file reads.

Keep SKILL.md focused on what to do and what goes wrong. Move deep
reference material (API docs, checklists, examples) to references/.

### Frontmatter fields that matter

```yaml
---
name: my-skill
description: |
  What it does. When to use it. Trigger phrases.
argument-hint: "[arg1] [arg2]"      # shown in autocomplete
context: fork                        # run in isolated subagent (optional)
agent: Explore                       # which subagent type (optional)
disable-model-invocation: true       # user-only invocation (optional)
allowed-tools: Read, Grep, Glob     # restrict tool access (optional)
hooks:                               # skill-scoped lifecycle hooks (optional)
  PostToolUse:
    - matcher: "Edit|Write"
      hooks: [{type: command, command: "bash scripts/validate.sh"}]
---
```

### Dynamic context injection

Use `` !`command` `` to inject runtime data before the skill reaches the model:

```markdown
Current branch: !`git branch --show-current`
Recent changes: !`git log --oneline -5`
```

The command runs at skill load time. Claude sees the output, not the command.

## Evaluating a Skill (/harness eval)

Test whether a skill improves output quality. Spawn parallel sub-agents
for baseline comparison — one with the skill, one without:

```
# Run both in parallel for the same prompt:
Agent(prompt: """
[DO NOT load the {skill} skill for this run]
Task: {eval prompt}
Output your result, then rate your confidence 1-10.
""")

Agent(prompt: """
[Load and follow the {skill} skill]
Task: {eval prompt}
Output your result, then rate your confidence 1-10.
""")
```

Then spawn a **critic** sub-agent to compare:

```
Agent(subagent_type: "critic", prompt: """
Compare these two outputs for the same task.
Baseline (no skill): [output A]
With skill: [output B]
Which is better? By how much? Is the skill load-bearing or marginal?
""")
```

If improvement is marginal, the skill isn't load-bearing. Delete it.
Write eval prompts to `evals/` in the skill directory. Rerun after changes.

## Linting a Skill (/harness lint)

Validate a skill against quality gates:

| Gate | Check | Fix |
|------|-------|-----|
| **Description triggers** | Does description include trigger phrases? | Add "Use when:" with concrete phrases |
| **Size** | SKILL.md < 500 lines? | Extract to references/ |
| **Gotchas** | Does it enumerate failure modes? | Add a gotchas section |
| **Judgment test** | Does it encode judgment the model lacks? | If not, delete the skill |
| **Oracle** | Can you verify the skill worked? | Add success criteria |
| **Freshness** | Do instructions match current model capabilities? | Strip non-load-bearing scaffold |

Run on all skills: `for s in skills/*/SKILL.md; do /harness lint "$s"; done`

## Converting Agent ↔ Skill (/harness convert)

### Agent → Skill
1. Read the agent's system prompt and tools
2. Strip agent-specific fields (model, tools, color)
3. Transform description from "who this agent is" to "when to invoke"
4. Restructure as SKILL.md with progressive disclosure
5. Move detailed instructions to references/

### Skill → Agent
1. Read the skill's SKILL.md
2. Add agent frontmatter (name, description, tools)
3. Rewrite description as persona ("You are...")
4. Keep instructions focused — agents get full context at startup

## Harness Engineering (/harness engineer)

### Codification hierarchy

When encoding knowledge, target the highest-leverage mechanism:

```
Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
```

### Hooks are the highest-leverage investment

Hooks run on every tool use. CLAUDE.md is read once. A hook that blocks
`rm -rf` is infinitely more reliable than a CLAUDE.md line saying
"don't delete files." Invest in hooks over prose.

Source of truth: `harnesses/claude/hooks/`

### AGENTS.md is a map, not a manual

Keep AGENTS.md under 100 lines. It should point to deeper sources of truth
(skills, references, docs/) rather than containing all instructions inline.
A monolithic AGENTS.md becomes a graveyard of stale rules.

### Stress-test assumptions

Every harness component encodes an assumption about model limitations.
When a new model drops, audit: is this skill still needed? Is this hook
still catching real problems? Strip what's not load-bearing.

## Sync (/harness sync)

Reads `.spellbook.yaml`, pulls declared skills/agents from GitHub into
project-local harness directories. When a local spellbook checkout exists,
uses symlinks instead (edits propagate instantly).

Managed primitives have a `.spellbook` marker file.
/harness sync only touches directories with this marker.

## Gotchas

- Skills that describe procedures the model already knows are waste
- Descriptions that don't include trigger phrases won't fire
- SKILL.md over 500 lines means you failed progressive disclosure
- Hooks that reference deleted skills will silently break
- Stale AGENTS.md instructions cause more harm than missing ones
- After any model upgrade, re-eval your skills — some become dead weight
