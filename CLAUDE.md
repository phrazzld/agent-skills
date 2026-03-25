# CLAUDE.md

## What This Repo Is

**Spellbook** — portable skills, agents, and enforcement infrastructure for AI-assisted
software development. One repo. All harnesses. Every stage of the software lifecycle.

Not a prompt library. Codified engineering judgment — constraints, invariants, feedback
loops, and quality gates that make agents produce correct software instead of plausible
software.

## Philosophy

**The harness is the product.** Models converge. Claude, GPT, Gemini — the gap narrows
every quarter. Leverage comes from persistent context infrastructure: skills that encode
judgment, tests that verify correctness, hooks that enforce invariants.

**Mechanical enforcement over prose.** A rule in CLAUDE.md is a suggestion. A lint rule
is a law. A test is physics. Encode taste as linters with remediation in error messages.
When docs fall short, promote the rule into code.

**Separate generator from evaluator.** Self-evaluation is unreliable — agents praise their
own work even when quality is mediocre. Separate the agent doing the work from the agent
judging it. The assess-* pipeline implements this: structured grading criteria that turn
subjective quality into concrete, gradable terms.

**Strip what's not load-bearing.** Every harness component encodes an assumption about
what the model can't do on its own. Stress-test those assumptions — they go stale as
models improve. "Find the simplest solution possible, and only increase complexity when
needed." When a new model lands, re-examine the harness and strip non-load-bearing pieces.

**Fix the system, not the instance.** When an agent produces bad output, update the skill,
add the lint rule, add the test. Never just fix the code and move on.

## Repo Structure

```
spellbook/
├── skills/              # All skills, flat (skills/{name}/SKILL.md)
├── agents/              # Agent definitions (markdown + YAML frontmatter)
├── scripts/             # Shared tooling (embeddings, assess pipeline)
├── registry.yaml        # Single source of truth: globals, sources, collections
├── bootstrap.sh         # Installs global primitives to harness dirs
├── .spellbook.yaml      # This repo's own manifest
├── SPEC.md              # Full lifecycle vision document
└── CLAUDE.md            # You are here
```

## How It Works

**Bootstrap** (once per machine): `curl -sL .../bootstrap.sh | bash`
Installs global process skills + agents to detected harnesses (~/.claude/, ~/.codex/, etc.)

**Focus** (per project): `/focus` reads `.spellbook.yaml`, pulls declared primitives
from GitHub into project-local harness directories. Nuke-and-rebuild on each sync.

**Manifest** (`.spellbook.yaml`): checked into git, harness-agnostic, declares which
skills and agents a project uses. Unqualified names resolve to `phrazzld/spellbook`.

## Primitives

**Skills** — directories with SKILL.md + optional references/, scripts/, assets/.
Follow the [Agent Skills spec](https://agentskills.io). Progressive disclosure:
description field triggers loading → SKILL.md body gives instructions → references
loaded on-demand for deep context.

**Agents** — markdown files with YAML frontmatter (name, description, tools).
Design philosophy reviewers (ousterhout, carmack, grug, beck) + specialized
analyzers (drift-sentinel, etc.).

## Key Patterns

### The Assess Pipeline (Generator/Evaluator)

Seven structured assessment skills with JSON output contracts:
`assess-depth`, `assess-docs`, `assess-drift`, `assess-intent`,
`assess-review`, `assess-simplify`, `assess-tests`.

Compose mechanically — orchestrator parses results, makes proceed/fix/escalate
decisions without reading prose. Orchestrated by `scripts/assess/run.py`.

### Context Packets

The unit of specification that precedes implementation. Encodes senior judgment
as explicit constraints: goal, non-goals, invariants, authority order, repo anchors,
prior art, oracle (definition of done), risk + rollout. Prevents agents from
guessing what "done" means.

### Night-Shift

Strict spec/implement separation. Humans write specs during the day; agents
implement overnight in autonomous multi-hour sessions. Output is PRs, not code.

## Adding a Skill

1. Create `skills/{name}/SKILL.md` with frontmatter
2. Add references/, scripts/, assets/ as needed
3. Commit and push — pre-commit hook regenerates index.yaml

## Principles

- **Flat over nested** — every skill at `skills/{name}/`, no hierarchy
- **Manifest-driven** — projects declare what they need, focus delivers it
- **Harness-agnostic** — primitives work across Claude Code, Codex, Pi, Factory
- **Nuke and rebuild** — focus deletes and recreates managed primitives each sync
- **Project-local** — focus installs to project dirs, never global; bootstrap handles globals
- **Marker-based ownership** — `.spellbook` marker distinguishes managed from unmanaged
- **Progressive disclosure** — description → SKILL.md body → references on-demand
- **GitHub as source of truth** — focus pulls from GitHub, works on any machine

## Artifact Hygiene

- Default scratch output goes to `/tmp`, not repo-relative paths
- Never require stable shared filenames for PR-local evidence
- Commit artifacts only when the repo explicitly wants them versioned
- **Focus output is committed to git, never gitignored.** Harness install
  directories (`.claude/skills/`, `.agents/`) are project artifacts in consuming
  repos, not build output. They are checked into the consuming repo's git history.
