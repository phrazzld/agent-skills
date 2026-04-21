---
name: seed
description: |
  Install a default harness into this repo. Copy most spellbook
  primitives (skills, agents, philosophy bench) into a repo-local
  shared skill layer with no filtering or tailoring, then bridge
  harness-specific entrypoints back to that shared copy. For
  something fast and complete when you don't want to wait for
  /tailor's judgment. Use when: "seed this repo", "give me a
  default harness", "initialize the agent here", "set me up fast".
  Trigger: /seed.
---

# /seed

The dumb default. Copy most of spellbook into this repo's shared
skill root, then keep harness-specific paths as thin bridges back to
that shared copy. No picking, no tailoring — just a working harness
in one command. For a thoughtful per-repo setup, use `/tailor`.

## What to do

1. Find `$SPELLBOOK`: `readlink -f` this SKILL.md, walk up until you
   see `skills/` + `agents/` + `harnesses/`.

2. Resolve the repo-local **shared skill root**. Prefer an existing
   `.agent/skills/`. If absent, prefer an existing `.agents/skills/`.
   If neither exists, create one shared root before copying. The
   shared root is the canonical storage for spellbook-distributed
   skills; `.claude/skills/` is a compatibility bridge, not the
   source of truth.

3. Copy every skill in `$SPELLBOOK/skills/` into the shared skill
   root, preserving each skill's full directory (`references/`,
   `scripts/`, everything). Skip `tailor` and `seed` themselves —
   they live globally.

4. Ensure `.claude/skills/<name>` points at each shared skill you
   installed. If `.claude/skills/` already exists as a directory,
   create per-skill symlinks. If it does not exist and the repo wants
   Claude slash-command compatibility, create it and then add the
   symlinks. Do not duplicate the skill contents into `.claude/`.

5. Copy every agent in `$SPELLBOOK/agents/` into the repo's existing
   agent directory. In most repos today that is `.claude/agents/`.
   Do not invent a second copy of agents unless the repo already has
   a documented shared-agent convention.

6. Copy `$SPELLBOOK/harnesses/shared/AGENTS.md` to `./AGENTS.md`
   only if one doesn't already exist.

7. Print what you installed.

## Invariants

- Never modify `$SPELLBOOK` or `~/.claude` / `~/.codex` / `~/.pi`.
  Writes only to the current repo.
- Shared skill root first. Spellbook-distributed skills live in the
  repo-local shared skill layer; `.claude/skills/` is only a bridge.
- Don't clobber existing shared skill roots, `.claude/`, or
  `AGENTS.md` — ask first.
- Don't filter, don't judge, don't specialize. That's `/tailor`'s
  job. This skill is the dumb option on purpose.

Typical time: seconds. Typical cost: zero LLM tokens beyond the
skill body — just file copies.
