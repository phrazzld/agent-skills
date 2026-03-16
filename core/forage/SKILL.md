---
name: forage
description: |
  Check for relevant skills before starting any domain-specific task. Search
  pack skills for specialized guidance not in core, load content inline.
  Invoke PROACTIVELY before: writing code in any framework or platform,
  integrating external services, working with databases or infrastructure,
  debugging unfamiliar systems, making architectural decisions, starting
  implementation in any domain. The cost of checking is negligible; the cost
  of missing available guidance is high. Also: "find a skill", "what skills
  exist", "skill inventory", "menu", "show skills", project setup, switching
  tech domains, external skill marketplace (skills.sh).
argument-hint: "<query> [--list] [--load <pack>] [--menu]"
---

# /forage

Search the internal skill library. Find and load pack skills not currently in context.

## Usage

```
/forage stripe webhook       # Find skills matching "stripe webhook"
/forage --list               # Show all available pack skills
/forage --load payments      # Load a pack for future sessions
```

## How It Works

### 1. Read Index

Read `references/pack-index.md` — a generated index of all pack skills
with names, descriptions, and trigger terms.

### 2. Match Query

Semantic match against skill descriptions in the index.
Return ranked results with match reasoning.

### 3. Present Results

```
## Forage Results: "{query}"

### Best Match
**{skill-name}** ({pack-name} pack)
{one-line description}
Match: {why this matches the query}

### Also Relevant
- **{skill-2}** ({pack}) — {description}
- **{skill-3}** ({pack}) — {description}

### Actions
- Loading best match content... (auto)
- Load pack for future sessions? `sync.sh pack {pack} .`
- No match? Try `/find-skills {query}` for the external ecosystem.
```

### 4. Auto-Load Best Match

Read the matched skill's full SKILL.md body + relevant references/ into context.
Apply the knowledge immediately to the current task.

If the skill is in an unloaded pack, offer: "Load {pack} pack for future sessions?"
Run: `sync.sh pack {pack-name} .`

## Discovery Scope

| Source | What It Searches |
|--------|-----------------|
| `packs/*/*/SKILL.md` | Domain pack skills (payments, growth, scaffold, finance, + future) |
| Project `.claude/skills/*/SKILL.md` | Project-local skills |

Does NOT search core/ — those are already loaded and discoverable directly.

## Sub-capabilities

| Intent | Reference |
|--------|-----------|
| External skill marketplace (skills.sh) | `references/find-skills.md` |
| Show available skills / menu | `references/menu.md` |

If `--menu` or "menu" or "show skills" → read `references/menu.md`.
If "find skills", "skills.sh", "marketplace" → read `references/find-skills.md`.

## What Forage Is NOT

- NOT a skill recommender during autonomous pipelines
- NOT a skill creator (use `/skill`)

## Anti-Patterns

- Don't read all SKILL.md bodies upfront — index only, then body for top match
- Don't hardcode skill names or counts — discover dynamically from index
- If forage finds no pack match, fall back gracefully — don't block the task
