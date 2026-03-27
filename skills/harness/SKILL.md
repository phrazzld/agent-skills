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

Skills support shell injection: wrap a command in backticks prefixed with `!`
and the output replaces the placeholder at skill load time. For example, a
skill can inject the current git branch or recent commits so the model sees
live data, not the command. See the Claude Code skills docs for syntax.

## Evaluating a Skill (/harness eval)

Test whether a skill improves output quality via baseline comparison.

Spawn two sub-agents in parallel with the same representative prompt. One runs
without the skill loaded (baseline). The other runs with the skill active.
Both produce their output and rate their confidence.

Then spawn a critic sub-agent to compare the two outputs: which is better?
By how much? Is the skill load-bearing or marginal?

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

### The Design Test (Norman Principle)

For any harness component, apply the Norman test:

1. **Can an agent make this error?** → The harness allows it. Add prevention.
2. **Does the harness make this error likely?** → The harness induces it. Fix urgently.
3. **After an error, does the response fix the system?** → If not, you're teaching
   burner mappings. Redesign the stove.

Prevention hierarchy: Type system > Hook > Lint > Test > Skill > Prose.
Prose is the burner label. Hooks are the redesigned stove.

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
