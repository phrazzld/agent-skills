---
name: agentic-bootstrap
description: Design repo-local Pi foundations using autonomous exploration lanes, model-job routing, synthesis-first artifact generation, and lean success criteria. Use when bootstrapping or overhauling `.pi/` in a repository.
---

# Agentic Bootstrap Engineering

Use this skill when creating or redesigning a repository's local Pi foundation.

## Core posture

- Treat models as capable collaborators, not scripts.
- Maximize exploration quality, then synthesize.
- Keep output focused and auditable.
- Bias toward repo-specific fit over generic templates.
- **Always generate a repo-local persona character in the root `AGENTS.md`.**
- Scaffold tiered context, not one giant manifest.

## Workflow

1. **Explore broadly & deeply**
   - Inspect local policy/context (`AGENTS.md`, `CLAUDE.md`, README/docs, scripts).
   - Mine existing automation/context layers (`.claude/`, `.codex/`, existing `.pi/`).
   - Analyze the **git history** (`git log --oneline -n 30`, `git log --stat`, major refactors) to understand where the project came from.
   - Review the **backlog, issues, and retrospectives** (e.g., `TODO`s, `.groom/retro/*.md`) to understand where it's going.
   - Run parallel lanes when useful (scout, docs, critic, context-bridge).

2. **Route models by job**
   - Scout/context/synthesis lanes: deeper reasoning models.
   - Research lanes: retrieval-strong models.
   - Critic lanes: adversarial/review-strong models.

3. **Synthesize with strict output contract**
   - Emit concrete artifacts (settings, overlays, prompts, pipelines, local workflow doc, and **AGENTS.md**).
   - **Design a personified character (`AGENTS.md`)**: The persona must be a *person* or *character* (e.g., an archivist, a chronomancer) deeply tied to the domain, complete with a Name, Title, Quote, Voice, and Belief System.
   - **Inject context front-and-center**: Do not bury capabilities or the persona in `.pi/persona.md`. The character identity, core domain rules, and essential capabilities must go directly into the repo-root `AGENTS.md` so the Pi runtime automatically loads them on every turn.
   - Create a codified context architecture:
     - hot memory: `CLAUDE.md`, `AGENTS.md`
     - routing: `docs/context/ROUTING.md`
     - cold memory: `docs/context/INDEX.md` + subsystem docs
     - drift control: `docs/context/DRIFT-WATCHLIST.md`
   - Require explicit opt-ins in settings.
   - Keep role overlays goal-oriented (role + objective + success criteria + output contract).

4. **Pressure test before finalize**
   - Surface failure modes and maintenance burden.
   - Remove brittle over-prescriptive instructions.
   - Keep only high-leverage local artifacts.

## Success criteria

- Foundation is clearly repo-specific.
- Local config is explicit and narrow.
- **The persona is a full character with Voice and Beliefs.**
- **The persona and core rules/capabilities are loaded automatically via the root `AGENTS.md`.**
- Context is tiered and maintainable, not one bloated file.
- Workflow supports explore -> design -> implement -> review.
- Instructions are high-signal and not procedurally bloated.
- Artifacts are understandable by a new operator in one read.

## Output contract

```markdown
## Repo Signals & Git History (Where we came from/Where we are going)
## Adopt / Bridge / Ignore Decisions
## Proposed Local Pi Foundation (including the Character Persona in AGENTS.md)
## Risks and Safeguards
## Why this is the minimal high-leverage setup
```

## References

- `references/best-practices.md`
