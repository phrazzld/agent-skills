# /harness create

Create a new skill or agent from scratch.

## The description field is everything

The description determines when the model loads the skill. Write it assertively.
Include trigger phrases users actually say. If the skill doesn't fire, the
description is wrong — not the model.

**Good:** `"Use when: 'debug this', 'why is this broken', 'investigate', 'production down'"`
**Bad:** `"A debugging utility for code analysis"`

## Structure

```
skill-name/
├── SKILL.md          # < 500 lines. Core instructions.
├── references/       # Deep context loaded on demand.
└── scripts/          # Executable code for deterministic tasks.
```

## What to encode

Encode judgment the model lacks. Not procedures it already knows.

**Highest signal:** Gotchas — what goes wrong, not just what to do right.
A gotcha list is more valuable than pages of happy-path instructions.
Enumerate failure modes, common mistakes, things the model consistently
gets wrong without the skill.

**Avoid:** Step-by-step procedures the model can derive from context.
If you're writing "1. Read the file 2. Find the function 3. Edit it" —
that's not a skill, that's a task description.

## Progressive disclosure

Three layers. Each loads only when needed:

1. **Description** (~100 tokens) — always in context. Decides triggering.
2. **SKILL.md body** (< 500 lines) — loads when skill fires.
3. **References** (unlimited) — loaded on demand via file reads.

Keep SKILL.md focused on what to do and what goes wrong. Move deep
reference material (API docs, checklists, examples) to references/.

## Frontmatter fields that matter

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

## Dynamic context injection

Skills support shell injection: wrap a command in backticks prefixed with `!`
and the output replaces the placeholder at skill load time. For example, a
skill can inject the current git branch or recent commits so the model sees
live data, not the command. See the Claude Code skills docs for syntax.
