---
name: organic-reflection
description: Reflect on recent work and propose lean, high-leverage Pi/process improvements with tradeoff analysis. Use when evolving prompts/skills/extensions/tools organically instead of bulk migration.
---

# Organic Reflection Skill

Use this skill when the user wants Pi/process/tooling to evolve from real usage signals.

## Core principles

- No bulk migration.
- No command/catalog bloat.
- Minimize configuration, maximize opinionated defaults.
- Prefer reversible changes.
- Codify only repeated, high-value behavior.

## Default scope

Always evaluate both:
1. Repo-local improvements
2. Global Pi workflow/config improvements

## Inputs to gather

1. **Recent execution evidence**
   - Git history (recent commits and changed files)
   - Recent issue/PR context
   - Notable friction points and repeated manual work

2. **Memory evidence (local-first)**
   - Session JSONL (`~/.pi/agent/sessions/...`)
   - Runtime logs (`~/.pi/agent/logs/...`)
   - If available, run `memory_ingest` + `memory_search` (or `memory_context`) before broad research
   - Use `scope=both` and explicitly prioritize local findings over global fallback

3. **Config source context**
   - Existing repo assets (`prompts/`, `skills/`, `extensions/`, `docs/`)
   - Legacy sources (`~/.claude/skills`, `~/.codex/commands`, `~/.codex/agents`)

4. **Pi capability constraints**
   - Prompt templates, skills, extensions, packages
   - Session storage/branching/compaction behavior
   - SDK + extension examples relevant to orchestration and memory

5. **External best practices**
   - Web/doc research with citations

## Swarm-first research (recommended)

If a `subagent` tool is available, propose a parallel swarm plan first.
Reference lane templates: `references/swarm-lanes.md`.

Important:
- Swarm is recommended, not mandatory.
- User chooses whether to launch swarm, number of agents, and lane focus.

If no subagent support is available, run lanes sequentially.

## Mandatory workflow

1. **Replay reality**
   - Describe what actually happened recently (not planned work).
   - Extract repeated tasks and decision bottlenecks.

2. **Identify codification targets**
   - Convert repeated patterns into candidate artifacts across these classes:
     - Process-only improvement
     - Global Pi config update (prompt/skill/extension/package)
     - Repo-local config update
     - External tool adoption or internal tool build

3. **Run rubric scoring**
   - Load and apply: `references/evaluation-rubric.md`

4. **Memory strategy analysis**
   - Compare options:
     - Session/log indexing only
     - Local semantic index (e.g., QMD-backed)
     - External memory layer
   - Prefer local-first until evidence says otherwise.

5. **Ask clarifying questions**
   - Ask focused questions before locking recommendations.
   - Resolve scope, maintenance, and reversibility tradeoffs.

6. **Recommend in phases**
   - Toe-dip: smallest experiment today
   - Pilot: short validation run
   - Scale: only after evidence

## Memory analysis checklist

- Verify what survives in session JSONL
- Explain compaction tradeoff (summary is lossy, full history remains in session file)
- Check current logs and retention behavior
- Prefer storing raw transcript excerpts + derived summaries/metadata
- Propose external memory integration only if local-first is insufficient

## Output contract

```markdown
## Reflection Findings

## Repeated Patterns Worth Codifying

## Candidate Artifacts (scored)
| Idea | Type | Scope | Score | Why now/next/later |
|---|---|---|---|---|

## Memory Strategy Notes

## Clarifying Questions

## Recommendation
- Now:
- Next:
- Later:
```
