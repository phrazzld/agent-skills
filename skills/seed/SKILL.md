---
name: seed
description: |
  Install a default harness into this repo. Copy most spellbook
  primitives (skills, agents, philosophy bench) into .claude/ with
  no filtering or tailoring. For something fast and complete when
  you don't want to wait for /tailor's judgment. Use when: "seed
  this repo", "give me a default harness", "initialize the agent
  here", "set me up fast". Trigger: /seed.
---

# /seed

The dumb default. Copy most of spellbook into this repo's `.claude/`.
No picking, no tailoring — just a working harness in one command.
For a thoughtful per-repo setup, use `/tailor`.

## What to do

1. Find `$SPELLBOOK`: `readlink -f` this SKILL.md, walk up until you
   see `skills/` + `agents/` + `harnesses/`.

2. Copy every skill in `$SPELLBOOK/skills/` into `.claude/skills/`,
   preserving each skill's full directory (`references/`, `scripts/`,
   everything). Skip `tailor` and `seed` themselves — they live
   globally.

3. Copy every agent in `$SPELLBOOK/agents/` into `.claude/agents/`.

4. Copy `$SPELLBOOK/harnesses/shared/AGENTS.md` to `./AGENTS.md`
   only if one doesn't already exist.

5. Print what you installed.

## Invariants

- Never modify `$SPELLBOOK` or `~/.claude` / `~/.codex` / `~/.pi`.
  Writes only to the current repo.
- Don't clobber existing `.claude/` or `AGENTS.md` — ask first.
- Don't filter, don't judge, don't specialize. That's `/tailor`'s
  job. This skill is the dumb option on purpose.

Typical time: seconds. Typical cost: zero LLM tokens beyond the
skill body — just file copies.
