# Spellbook

8 workflow skills, 7 agents, and harness infrastructure for AI-assisted
software development. One repo. All harnesses (Claude Code, Codex, Pi).

## Quick Start

```bash
# Bootstrap (one-time per machine)
# Symlinks if local checkout exists, downloads from GitHub otherwise
curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/master/bootstrap.sh | bash
```

## The 8 Skills

| Skill | Purpose |
|-------|---------|
| `/autopilot` | Full delivery: plan→build→review→ship |
| `/code-review` | Parallel multi-agent review, auto-fix loop |
| `/debug` | Investigate, triage, fix |
| `/groom` | Backlog management, brainstorming, rethink, scaffold |
| `/harness` | Skill engineering, primitive management, context lifecycle |
| `/reflect` | Session retrospective, learning extraction, harness postmortem |
| `/research` | Multi-source web research, delegation, think tank |
| `/shape` | Spec/design → context packet output |

## The 7 Agents

**GAN triad:** planner (spec) → builder (implement) → critic (evaluate)

**Design review bench:** ousterhout (depth), carmack (ship), grug (simplicity), beck (TDD)

## Workflow

```
backlog.d/ → /groom → /shape (planner) → /autopilot (builder) → /code-review (critic + bench) → ship
```

## Structure

```
spellbook/
├── skills/        # 8 workflow skills
├── agents/        # 7 agent definitions
├── harnesses/     # Per-harness configs (claude/, codex/, pi/)
│   └── shared/    # Common engineering principles
├── registry.yaml  # Single source of truth
└── bootstrap.sh   # Symlinks spellbook → harness dirs
```

## Adding a Skill

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Keep it < 500 lines. Encode judgment, not procedures.
3. Run `/harness lint` to validate quality gates
4. Commit — pre-commit hook regenerates index.yaml

## Principles

- **8 skills, 7 agents** — resist expansion
- **Gotchas > instructions** — enumerate what goes wrong
- **Strip non-load-bearing scaffold** — stress-test after model upgrades
- **Symlink, not copy** — bootstrap.sh links to local checkout when available
- **Progressive disclosure** — description → SKILL.md → references

## License

MIT
