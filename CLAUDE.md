# CLAUDE.md

## What This Repo Is

**Spellbook** — focused workflow skills, specialized agents, and harness
configs for AI-assisted development. One repo, all harnesses, symlinked
to ~/.claude, ~/.codex, ~/.pi via bootstrap.sh.

## Structure

```
spellbook/
├── skills/        # Leaf skills (qa, demo, investigate, research, ...) and
│                  #   orchestrators (autopilot, code-review, settle, ...)
├── agents/        # Specialized agents: planner, builder, critic,
│                  #   ousterhout, carmack, grug, beck
├── harnesses/     # Per-harness configs, hooks, shared principles
├── registry.yaml  # External skill sources (for embeddings)
└── bootstrap.sh   # Discovers skills/agents from filesystem, symlinks to harness dirs
```

## Issue Tracking

Issues are stored as git objects via **git-bug** (distributed, offline-first).
`backlog.d/` holds shaped work ready to build; git-bug holds raw issues/bugs.
GitHub Issues is an optional sync target — `git-bug push origin` creates issues
there for human visibility when desired. `backlog.d/` is the canonical backlog.

```bash
git-bug bug                          # list open issues
git-bug bug new -t "title" -m "..."  # create issue
git-bug bug status close <id>        # close issue
git-bug push origin                  # sync to GitHub bridge
```

Agent coordination uses atomic claims: `source scripts/lib/claims.sh && claim_acquire <id>`.

## Workflow

```
backlog.d/ → /groom → /shape (planner) → /autopilot (builder) → /code-review (critic + bench) → ship
```

## Principles

See `harnesses/shared/AGENTS.md` — one file, symlinked to every harness.

- **Focused set of skills and agents** — resist bloat, justify additions
- **Thin harness, strong models** — don't compensate for weak models with scaffold
- **Gotchas > instructions** — enumerate what goes wrong
- **Description is the trigger** — write it assertively
- **Strip non-load-bearing scaffold** — stress-test after model upgrades
- **Map, not manual** — AGENTS.md and CLAUDE.md point to skills, not contain them

## Gotchas for Contributing to This Repo

- Skills encode judgment, not procedures. If the model already knows how, delete the skill.
- SKILL.md must be < 500 lines. Extract deep content to references/.
- Regexes over agent prose and semantic workflow DSLs are strong smells.
- Run `/harness lint` on any skill you create or modify.
- Run `/harness eval` to verify the skill actually improves output vs baseline.
- The pre-commit hook regenerates index.yaml — don't edit it manually.
- bootstrap.sh has two modes: symlink (local checkout) and download (remote).
  Test both paths if you change it.
- If you bootstrap from a temporary worktree, prefer pinning `SPELLBOOK_DIR`
  to a stable checkout. Disposable worktree symlinks make global harness skills disappear later.
- `harnesses/claude/settings.json` is COPIED by bootstrap (Claude modifies it
  at runtime), not symlinked. Changes there need a re-bootstrap to take effect.
