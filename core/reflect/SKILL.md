---
name: reflect
description: |
  Session retrospective, codification, and implementation feedback capture.
  Distill learnings to CLAUDE.md/hooks/rules, propose lean improvements,
  tune repos for agents, generate changelogs.
  Invoke for: "done", "wrap up", "what did we learn", "retro", "session end",
  "reflect", "distill", "tune repo", "changelog", "organic reflection".
disable-model-invocation: true
argument-hint: "[--skip-commit] [--focus area] [append --issue N]"
---

# /reflect

Structured reflection producing concrete artifacts. Every finding either becomes
a codified artifact or gets explicitly justified as not worth codifying.

## Routing

| Intent | Sub-capability |
|--------|---------------|
| Codify learnings, update CLAUDE.md, hooks, skills | `references/distill.md` |
| Propose lean process improvements | `references/organic-reflection.md` |
| Specialize agents for a repo, tune context | `references/tune-repo.md` |
| Generate semantic changelog | `references/changelog.md` |

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

### 3. Codification Pass

For EACH friction point and bug, evaluate targets in order:

```
Hook      -> Prevent automatically? (pre-edit)
Lint rule -> Catch at edit time? -> invoke /guardrail
Agent     -> Reviewer catches this?
Skill     -> Reusable workflow?
Memory    -> Auto-memory captures this?
CLAUDE.md -> Convention/philosophy?
Docs      -> Reference doc needs update?
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

Run `/reflect tune-repo` to refresh context artifacts and update CLAUDE.md/AGENTS.md
if drift detected.

### 4. Execute Codification

For each item:
1. Read the target file
2. Check for existing coverage (avoid duplication)
3. Add learning in file's native format
4. Verify no conflicts

| Target | Location | Format |
|--------|----------|--------|
| Hook | `~/.claude/settings.json` + `~/.claude/hooks/` | Script |
| Agent | `~/.claude/agents/` | YAML config |
| Skill | `~/.claude/skills/*/SKILL.md` | Frontmatter + markdown |
| Memory | `~/.claude/projects/*/memory/*.md` | Notes |
| CLAUDE.md | `~/.claude/CLAUDE.md` Staging section | Concise pattern |
| Docs | Repo `CLAUDE.md`, `AGENTS.md`, `docs/` | Varies |

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

```
{repo}/.groom/retro/<issue>.md
```

Created automatically if missing. One file per issue to avoid branch-hot append conflicts.

### Retro Entry Format

```markdown
## Entry: #{issue} -- {title} ({date})

**Effort:** predicted {predicted} -> actual {actual}
**Scope changes:** {what changed}
**Blockers:** {what blocked}
**Pattern:** {reusable insight}

---
```

### How /groom Uses Retro

During planning, `/groom` reads `.groom/retro/*.md` and extracts:
- Effort calibration ("Payment issues take 1.5x estimates")
- Scope patterns ("Webhook issues always need retry logic")
- Blocker patterns ("External API docs frequently wrong")
- Domain insights ("Bitcoin wallet needs regtest testing")
- Bloat patterns ("Agent kept layering fallback paths instead of deleting old code")

## Anti-Patterns

- Reflecting without producing artifacts
- Codifying things already covered (check first)
- Over-codifying obvious patterns
- Creating docs nobody reads (prefer hooks/agents that enforce)
- Skipping "went well" (positive reinforcement matters)

## Integration

| Consumes | Produces |
|----------|----------|
| Session context | Updated CLAUDE.md staging |
| `git diff`, `git log` | New/updated skill files |
| Task list state | New/updated hooks |
| Error logs | Auto-memory entries |
| | `.groom/retro/<issue>.md` entries |

**Hands off to:** `/commit` (if artifacts to commit)

## Related

- `/groom` -- Reads `.groom/retro/*.md` during planning
- `/pr` -- May append issue-scoped retro signals
