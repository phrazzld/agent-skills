# Mode-bloat lint gate — catch attention dilution early

Priority: medium
Status: done
Estimate: S

## Problem

Skills with too many inline modes cause attention dilution and instruction
omission. The model loads 400 lines of SKILL.md, half of which describe modes
it won't use this invocation. Signal-to-noise drops; the model skips or
conflates instructions. /investigate and /settle solved this with a router
table + references/ pattern, but nothing prevents new skills from repeating
the monolith mistake.

## Goal

Add a mode-bloat detection gate to `/harness lint` and a preventive design
principle to `/harness create`. Two surgical edits to `skills/harness/SKILL.md`.

## Non-Goals

- Don't build a script or programmatic checker — this is an agent-evaluated lint gate
- Don't refactor existing skills — just flag them when linted
- Don't change the lint invocation interface

## Changes

### 1. New lint gate row

**Where:** `skills/harness/SKILL.md`, lint gate table (after the "Freshness" row, line 125).

**Add this row:**

```
| **Mode bloat** | >4 modes with inline content, or any single mode >60 lines inline? | Extract mode content to `references/mode-*.md`; use router pattern (see /investigate, /settle) |
```

### 2. Router pattern guidance in create mode

**Where:** `skills/harness/SKILL.md`, "Creating a Skill" section, after the
"Progressive disclosure" subsection (after line 73, before "Frontmatter fields
that matter").

**Add this subsection:**

```markdown
### Multi-mode skills: router + references

When a skill has >3 modes, keep SKILL.md as a thin router. Each mode gets
a heading with a one-line intent and a `Read references/mode-*.md` delegation.
Inline content stays only for the default/simplest mode.

Exemplars: /investigate (routing table + 7 reference files), /settle (3 phases
each delegating to `references/`).

Anti-pattern: every mode fully inlined in SKILL.md. This causes attention
dilution — the model loads all modes but uses one.
```

## Oracle

- [ ] `skills/harness/SKILL.md` lint table has exactly 7 rows (6 existing + 1 new)
- [ ] New gate row mentions the >4 modes threshold, >60 lines threshold, and the router pattern
- [ ] New "Multi-mode skills" subsection appears between "Progressive disclosure" and "Frontmatter fields"
- [ ] Subsection references /investigate and /settle as exemplars
- [ ] No other lines in SKILL.md are modified
- [ ] Total addition is <20 lines
