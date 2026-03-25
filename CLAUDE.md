# CLAUDE.md

## What This Repo Is

**Spellbook** — 8 workflow skills, 7 agents, and harness configs for
AI-assisted development. One repo, all harnesses, symlinked to
~/.claude, ~/.codex, ~/.pi via bootstrap.sh.

## Structure

```
spellbook/
├── skills/        # 8 skills: autopilot, code-review, debug, groom,
│                  #   harness, reflect, research, shape
├── agents/        # 7 agents: planner, builder, critic,
│                  #   ousterhout, carmack, grug, beck
├── harnesses/     # Per-harness configs, hooks, shared principles
├── registry.yaml  # Single source of truth for globals
└── bootstrap.sh   # Symlinks spellbook → harness dirs
```

## Workflow

```
backlog.d/ → /groom → /shape (planner) → /autopilot (builder) → /code-review (critic + bench) → ship
```

## Principles

See `harnesses/shared/principles.md` for engineering doctrine.

- **8 skills, 7 agents** — resist expansion
- **Harness is the product** — models are commodities
- **Gotchas > instructions** — enumerate what goes wrong
- **Description is the trigger** — write it assertively
- **Strip non-load-bearing scaffold** — stress-test after model upgrades
- **Map, not manual** — AGENTS.md and CLAUDE.md point to skills, not contain them

## Gotchas for Contributing to This Repo

- Skills encode judgment, not procedures. If the model already knows how, delete the skill.
- SKILL.md must be < 500 lines. Extract deep content to references/.
- Run `/harness lint` on any skill you create or modify.
- Run `/harness eval` to verify the skill actually improves output vs baseline.
- The pre-commit hook regenerates index.yaml — don't edit it manually.
- bootstrap.sh has two modes: symlink (local checkout) and download (remote).
  Test both paths if you change it.
- `harnesses/claude/settings.json` is COPIED by bootstrap (Claude modifies it
  at runtime), not symlinked. Changes there need a re-bootstrap to take effect.
