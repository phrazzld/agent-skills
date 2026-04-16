---
name: harness
description: |
  Build, maintain, evaluate, and optimize the agent harness — skills, agents,
  hooks, CLAUDE.md, AGENTS.md, and enforcement infrastructure.
  Use when: "create a skill", "update skill", "improve the harness",
  "sync skills", "eval skill", "lint skill", "tune the harness",
  "add skill", "remove skill", "convert agent to skill",
  "audit skills", "skill health", "unused skills",
  "lint this skill", "eval this skill", "evaluate this skill",
  "validate this skill", "check this skill".
  Trigger: /harness, /focus, /skill, /primitive.
argument-hint: "[create|eval|lint|convert|sync|engineer|audit] [target]"
---

# /harness

Build and maintain the infrastructure that makes agents effective.

## Routing

| Intent | Reference |
|--------|-----------|
| Create a new skill or agent | `references/mode-create.md` |
| Evaluate a skill (baseline comparison) | `references/mode-eval.md` |
| Lint/validate a skill against quality gates | `references/mode-lint.md` |
| Convert agent ↔ skill | `references/mode-convert.md` |
| Sync primitives from spellbook to project | `references/mode-sync.md` |
| Design harness improvements | `references/mode-engineer.md` |
| Audit skill health and usage | `references/mode-audit.md` |

If first argument matches a mode name, read the corresponding reference.
If no argument, ask: "What do you want to do? (create, eval, lint, convert, sync, engineer, audit)"

**Scaffold moved.** If user says "scaffold qa" or "scaffold demo", redirect:
"Scaffold is now owned by the domain skill. Run `/qa scaffold` or `/demo scaffold`."

## Skill Design Principles

These principles govern every mode. They are the quality standard for skills
this harness creates, evaluates, and lints.

1. **One skill = one domain, 1-3 workflows.** A skill that spans multiple
   domains should be split. Three workflows is healthy. Five is a refactor signal.
2. **Token budget: 3,000 target, 5,000 ceiling.** Every token competes for
   attention with the user's actual problem. 5,000 is the hard ceiling, not target.
3. **Mode content in references, not inline.** Mandatory for >3 modes. Thin
   SKILL.md with routing table, mode content in `references/mode-*.md`.
4. **Every line justifies its token cost.** Irrelevant-but-related content
   degrades more than unrelated noise. Cut related-but-off-topic content first.
5. **Description tax is always-on.** ~100 tokens per skill, loaded every
   conversation. Don't split unless domain coherence demands it.
6. **Encode judgment, not procedures.** If the model already knows how, the
   skill is waste. Gotcha lists outperform pages of happy-path instructions.
7. **Mode-bloat gate.** >4 modes with inline content is a lint failure.
   Extract to references/ or split the skill.

## Gotchas

- Skills that describe procedures the model already knows are waste
- Descriptions that don't include trigger phrases won't fire
- SKILL.md over 500 lines means you failed progressive disclosure
- Hooks that reference deleted skills will silently break
- Stale AGENTS.md instructions cause more harm than missing ones
- After any model upgrade, re-eval your skills — some become dead weight
- Regexes over agent prose are usually proof the boundary is wrong
