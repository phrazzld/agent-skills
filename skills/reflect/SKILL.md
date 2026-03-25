---
name: reflect
description: |
  Session retrospective, codification, and implementation feedback capture.
  Distill learnings to AGENTS.md/hooks/rules, propose lean improvements,
  tune repos for agents.
  Invoke for: "done", "wrap up", "what did we learn", "retro", "session end",
  "reflect", "distill", "tune repo".
argument-hint: "[distill|improve|tune-repo|append] [context]"
---

# /reflect

Structured reflection producing concrete artifacts. Every finding either becomes
a codified artifact or gets explicitly justified as not worth codifying.

## Routing

| Intent | Sub-capability |
|--------|---------------|
| Codify learnings, update AGENTS.md, hooks, skills | `references/distill.md` |
| Propose lean process improvements | `references/organic-reflection.md` |
| Specialize agents for a repo, tune context | `references/tune-repo.md` |

## Process

### 1. Gather Evidence

```bash
git diff --stat HEAD~N    # What changed
git log --oneline -10     # Recent commits
```

From conversation context:
- Commands that failed and why
- Bugs encountered and root causes
- Patterns discovered
- User corrections received
- Task list status, pending/blocked items

### 2. Categorize Findings

| Bucket | Question | Example |
|--------|----------|---------|
| **Went well** | Keep doing? | Module separation, lazy imports |
| **Friction** | What slowed us down? | Guessed at API, wrong return types |
| **Bugs introduced** | What broke and why? | Dict access on dataclass |
| **Missing artifacts** | What would have prevented friction? | Module API reference |
| **Architecture insights** | Design decisions right/wrong? | SQLite for persistence |
| **Bloat signals** | What layers should be deleted? | Compatibility shim with no real users |
| **Gaps** | What was MISSING from the agent's toolkit? | See gap types below |

#### Gap Types

When a session reveals something MISSING (not broken, not friction — absent):

| Gap Type | Signal | Remediation Target |
|----------|--------|--------------------|
| `missing_skill` | Had to improvise a workflow that should be reusable | Skill (create or enhance) |
| `missing_tool` | Needed a capability no available tool provided | Hook or MCP integration |
| `repeated_failure` | Same class of error across multiple sessions | Guardrail or lint rule |
| `wrong_info` | Acted on stale/incorrect AGENTS.md or reference | Update source doc |
| `permission_friction` | Correct action blocked by permission model | Hook or settings adjustment |

Omit the Gaps bucket when the session was clean — no gaps means no gaps.

If gaps are found, output them as structured entries in `.spellbook/observations.ndjson`
using the canonical schema (see `/calibrate`) with gap-specific extensions:

```jsonl
{"timestamp":"2026-03-18T12:00:00Z","primitive":"phrazzld/spellbook@reflect","type":"gap","summary":"No skill for X workflow","context":"Had to improvise...","confidence":0.7,"subtype":"missing_skill","remediation":"Skill"}
```

Gap-specific fields (`subtype`, `remediation`) extend the canonical fields — never replace them.
Use the codification hierarchy (Phase 3) to determine the right remediation target.

### 2.5. Health Assessment

Run the assess-* suite on the session's changed files to measure health delta:
- Compare working tree against `.spellbook/health.json` (last snapshot)
- Run relevant assess-* checks: `assess-depth` on changed modules, `assess-tests`
  on changed test files, `assess-drift` against declared constraints
- Report delta per check: "Module depth +5, test quality -3, overall: healthier"
- If any check degraded, surface as a codification target in Phase 3
- Write updated snapshot to `.spellbook/health.json` with trend tracking

This phase feeds directly into codification — if module depth degraded during
the session, that's a signal to add a guardrail or update AGENTS.md.

### 3. Codification Pass

Apply codification hierarchy from `/calibrate`. Highest reliability level wins:

```
Type system > Lint rule > Hook > Test > CI > Skill/reference > AGENTS.md > Memory
```

**Default: codify. Exception: justify not codifying.**

If you explained a subsystem twice, add or update a cold-memory doc.
If a risky subsystem had no relevant doc, record that retrieval miss explicitly.

### 3.5. Retro Append

If this session implemented a GitHub issue, append implementation feedback:

```
{repo}/.groom/retro/<issue>.md
```

Capture:
- Issue number and title
- Predicted effort vs actual effort
- Scope changes during implementation
- Blockers encountered
- Reusable pattern for future scoping

This feeds `/groom`'s planning feedback loop.

**Manual invoke:** `/reflect append --issue 42 --predicted m --actual l --scope "Added retry logic" --blocker "Undocumented API"`

### 3.6. Tune Repo

Run `/reflect tune-repo` to refresh context artifacts and update AGENTS.md
if drift detected.

### 4. Execute Codification

For each item:
1. Read the target file
2. Check for existing coverage (avoid duplication)
3. Add learning in file's native format
4. Verify no conflicts

| Target | Location | Format |
|--------|----------|--------|
| Hook | Harness config (e.g. settings.json + hooks/) | Script |
| Agent | Project-local agents dir | YAML + markdown |
| Skill | Project-local skills dir | Frontmatter + markdown |
| AGENTS.md | Repo `AGENTS.md` | Concise pattern |
| Docs | `AGENTS.md`, `docs/` | Varies |
| Memory | Harness memory system | Last resort |

### 5. Report

```markdown
## Session Retrospective

### Went Well
- [item]: [why it worked]

### Friction Points
- [item]: [what happened] -> [codified to: file]

### Bugs Introduced & Fixed
- [bug]: [root cause] -> [codified to: file]

### Artifacts Created/Updated
- [file]: [what changed]

### Not Codified (with justification)
- [item]: [specific reason]

### Open Items
- [anything unfinished or flagged]
```

## Retro Storage

See `references/retro-format.md` for entry format and how `/groom` consumes retros.

Storage: `{repo}/.groom/retro/<issue>.md` — one file per issue.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/gather_evidence.sh [N]` | Gather recent commits, changed files, uncommitted work |

## Anti-Patterns

- Reflecting without producing artifacts
- Codifying things already covered (check first)
- Over-codifying obvious patterns
- Creating docs nobody reads (prefer hooks/agents that enforce)
- Skipping "went well" (positive reinforcement matters)

## Integration

| Consumes | Produces |
|----------|----------|
| Session context | Updated AGENTS.md |
| `git diff`, `git log` | New/updated skills, agents |
| Task list state | New/updated hooks |
| Error logs | `.groom/retro/<issue>.md` entries |

**Hands off to:** `/commit` (if artifacts to commit)

## Related

- `/groom` -- Reads `.groom/retro/*.md` during planning
- `/pr` -- May append issue-scoped retro signals
