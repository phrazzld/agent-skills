# Spellbook

8 workflow skills, 7 agents, and harness infrastructure for AI-assisted
software development. One repo. All harnesses (Claude Code, Codex, Pi).

## Quick Start

```bash
# Bootstrap (one-time per machine)
# Symlinks if local checkout exists, downloads from GitHub otherwise
curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/master/bootstrap.sh | bash
```

If you're running bootstrap from a temporary git worktree, it now prefers a
stable checkout like `~/Development/spellbook` automatically. To intentionally
point your harnesses at a specific checkout, set `SPELLBOOK_DIR=/path/to/spellbook`.

## The 8 Skills

| Skill | Purpose |
|-------|---------|
| `/deliver` | Inner-loop composer: ticket → merge-ready (shape → implement → review+ci+refactor+qa) |
| `/code-review` | Parallel multi-agent review, auto-fix loop |
| `/investigate` | Investigate, triage, fix |
| `/groom` | Backlog management, brainstorming, rethink, scaffold |
| `/harness` | Skill engineering, primitive management, context lifecycle |
| `/reflect` | Session retrospective, harness postmortem, operator coaching |
| `/research` | Multi-source web research, delegation, think tank |
| `/shape` | Spec/design → context packet output |

## The 7 Agents

**GAN triad:** planner (spec) → builder (implement) → critic (evaluate)

**Design review bench:** ousterhout (depth), carmack (ship), grug (simplicity), beck (TDD)

## Workflow

```
backlog.d/ → /groom → /shape → /deliver → ship
```

## Structure

```
spellbook/
├── skills/        # 8 workflow skills
├── agents/        # 7 agent definitions
├── harnesses/     # Per-harness configs (claude/, codex/, pi/)
│   └── shared/    # Common engineering principles
├── registry.yaml  # External skill sources (for embeddings)
└── bootstrap.sh   # Discovers skills/agents from filesystem, symlinks to harness dirs
```

## Adding a Skill

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Keep it < 500 lines. Encode judgment, not procedures.
3. Run `/harness lint` to validate quality gates
4. Run `bootstrap.sh` — it discovers skills from the filesystem automatically

## Principles

- **8 skills, 7 agents** — resist expansion
- **Gotchas > instructions** — enumerate what goes wrong
- **Strip non-load-bearing scaffold** — stress-test after model upgrades
- **Symlink, not copy** — bootstrap.sh links to local checkout when available
- **Progressive disclosure** — description → SKILL.md → references

## License

MIT
