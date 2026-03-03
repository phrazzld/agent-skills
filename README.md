# Agent Skills

58 core skills + 4 domain packs for AI coding agents. Works with Claude Code, Codex, Gemini, Factory, and Pi.

Skills are Markdown-first with a handful of Python helper scripts. No application code, no dependencies. They teach agents *how to work*: debugging methodology, PR workflows, design systems, incident response, and dozens of domain-specific playbooks.

## Why

AI agents are only as good as their instructions. Generic prompts produce generic work. These skills encode opinionated, battle-tested workflows that turn agents into effective teammates.

**The budget problem:** Claude Code allocates ~16K chars for skill descriptions. Naive skill libraries overflow this budget and most skills get silently dropped. This repo solves it with three tiers:

| Tier | Location | Distribution | Budget cost |
|------|----------|-------------|-------------|
| **Core** (58) | `core/` | `sync.sh claude` → global | Per-mode |
| **Pack** (19) | `packs/` | `sync.sh pack <name> <project>` → per-project | Per-mode |
| **Repo-local** (5) | `<repo>/.claude/skills/` | Lives in destination repo | Per-mode |

Invocation modes within each tier:

| Mode | Triggered by | Budget cost |
|------|-------------|-------------|
| **Model+User** | Agent decides or user invokes | Consumes budget |
| **Reference** | Auto-loaded when relevant | Consumes budget |
| **DMI** | User only (`/command`) | **Free** |

## Quick Start

```bash
git clone https://github.com/phrazzld/agent-skills.git
cd agent-skills

# Sync core skills to your agent harness
./scripts/sync.sh claude    # → ~/.claude/skills/
./scripts/sync.sh codex     # → ~/.codex/skills/
./scripts/sync.sh all       # All harnesses

# Load domain packs per-project
./scripts/sync.sh pack payments ~/Development/cerberus
./scripts/sync.sh pack growth ~/Development/cerberus-web
./scripts/sync.sh pack scaffold ~/Development/new-project
./scripts/sync.sh pack finance --global

# Preview without changes
./scripts/sync.sh claude --dry-run

# Remove stale symlinks after updates
./scripts/sync.sh --prune all
```

Skills are symlinked, not copied. Edit once, every harness sees the change.

## Skills

### Delivery Pipeline

| Skill | Mode | Description |
|-------|------|-------------|
| `/groom` | DMI | Backlog grooming, health checks, hygiene |
| `/shape` | DMI | Product + technical planning (absorbs spec, architect, brainstorming) |
| `/autopilot` | Model+User | Autonomous delivery: shape → build → commit → PR |
| `/build` | Model+User | Implementation with TDD workflow |
| `/commit` | DMI | Semantic commits with quality gates |
| `/pr` | DMI | PR creation with mandatory sections |
| `/pr-fix` | Model+User | Unblock PRs: conflicts, CI, review feedback, refactoring |
| `/pr-polish` | Model+User | Hindsight review and quality elevation |

### Quality & Debugging

| Skill | Mode | Description |
|-------|------|-------------|
| `/check-quality` | DMI | Audit quality gates: tests, CI, hooks |
| `/debug` | Model+User | Four-phase systematic debugging |
| `/test-coverage` | DMI | TDD workflow, Vitest config, coverage audit |
| `/distill` | Model+User | Repo knowledge distillation and session codification |
| `/done` | DMI | Session retrospective and codification |
| `/triage` | Model+User | Incident response → postmortem → verification |

### Audit / Fix / Log

Three unified skills replace 36 domain-specific check/fix/log skills:

```bash
/audit stripe           # Audit any domain
/fix docs               # Fix issues (model-invocable for autonomous work)
/log-issues production  # Create GitHub issues from findings
```

Domains: bitcoin, btcpay, bun, docs, landing, lightning, observability, onboarding, payments, posthog, product-standards, production, stripe, virality.

### Design & Visual

| Skill | Mode | Description |
|-------|------|-------------|
| `/design` | Model+User | Full design system: tokens, exploration, Vercel patterns |
| `/visual-qa` | Model+User | Pre-commit visual regression |
| `ui-skills` | Reference | Opinionated UI constraints |
| `/visualize` | DMI | Visual HTML deliverables |
| `pencil-renderer` | Reference | Pencil MCP rendering |
| `/pencil-to-code` | DMI | Convert Pencil designs to code |

### Agent Infrastructure

| Skill | Mode | Description |
|-------|------|-------------|
| `/agent-browser` | Model+User | Playwright CLI for AI agents |
| `delegate` | Reference | Multi-AI orchestration primitive |
| `agent-tools` | Reference | Agent tool patterns |
| `/agentic-bootstrap` | DMI | Bootstrap `.pi/` for autonomous repos |
| `prompt-context-engineering` | Reference | Production prompt design |
| `llm-communication` | Reference | Effective LLM instructions |
| `/llm-infrastructure` | Model+User | LLM evaluation, gateway routing, prompt ops |

### Ops, Testing & Infrastructure

| Skill | Mode | Description |
|-------|------|-------------|
| `/changelog` | DMI | Changelog infrastructure and automation |
| `/security-scan` | DMI | Whole-codebase vulnerability analysis |
| `/sysadmin` | DMI | System health checks |
| `/sysadmin-ops` | DMI | Incident triage and recovery |
| `/observability` | DMI | Observability setup |
| `/dogfood` | DMI | Exploratory QA with repro evidence |
| `webapp-testing` | Reference | Playwright test patterns |
| `database` | Reference | Schema design, migrations, Convex patterns |
| `guardrail` | DMI | Safety rails |

### References (auto-loaded)

`git-mastery` · `naming-conventions` · `external-integration-patterns` · `ui-skills` · `business-model-preferences` · `toolchain-preferences` · `next-patterns` · `database` · `delegate` · `cli-reference` · `ralph-patterns` · `skill-builder` · `agentic-ui-contract` · `webapp-testing`

## Domain Packs

Packs are loaded per-project via `sync.sh pack <name> <project-dir>`.

### payments (3 skills + 5 checklists)
`bitcoin` · `lightning` · `stripe`

### growth (7 skills + 3 checklists)
`brand` · `content` · `growth` · `ai-media` · `og-hero-image` · `app-screenshots` · `audit-website`

### scaffold (5 skills + 1 checklist)
`github-app-scaffold` · `slack-app-scaffold` · `monorepo-scaffold` · `mobile-migrate` · `bun`

### finance (4 skills)
`finances-ingest` · `finances-report` · `finances-snapshot` · `crypto-gains`

## Repo-Local Skills

These skills are hardcoded to specific projects and live in their repos:

| Skill | Repo |
|-------|------|
| `deploy` | `cerberus-mono/.claude/skills/` |
| `flywheel-qa` | `caesar-in-a-year/.claude/skills/` |
| `moneta-ingest` | `moneta/.claude/skills/` |
| `moneta-reconcile` | `moneta/.claude/skills/` |
| `tax-check` | `moneta/.claude/skills/` |

## Anatomy of a Skill

```
core/debug/
├── SKILL.md              # Frontmatter + skill definition
└── references/
    ├── investigation.md   # Absorbed from /investigate
    └── systematic.md      # Absorbed from /systematic-debugging
```

`SKILL.md` frontmatter:

```yaml
---
name: debug
description: |
  Investigate local development issues: test failures, type errors,
  runtime bugs, build problems. Use when something is broken and you
  need to find the root cause. Not for production incidents (use /triage).
---
```

## Adding a Skill

1. Create `core/{name}/SKILL.md` with frontmatter
2. Choose mode: default (model+user), `disable-model-invocation: true` (DMI), or `user-invocable: false` (reference)
3. Run `./scripts/sync.sh all`

## Principles

- **Deep modules** — hide complexity behind simple interfaces
- **Compose, don't duplicate** — orchestrators call primitives
- **Budget-aware** — use DMI for user-only workflows
- **Agent-agnostic** — works across Claude, Codex, Gemini, Pi

## License

MIT
