---
name: curate
description: |
  Evolve the Spellbook library. Scan external sources for new skills worth indexing,
  review observations for improvement opportunities, brainstorm new primitives,
  investigate existing skills for consolidation or deletion, research power user
  patterns and best practices.
  Use when: "curate", "evolve spellbook", "what should we build", "find new skills",
  "audit the library", "consolidate skills", "what's new in the ecosystem",
  "spellbook maintenance", "improve primitives".
disable-model-invocation: true
argument-hint: "[scan|improve|brainstorm|audit|research]"
---

# /curate

Evolve the Spellbook library. This is the primary workflow for maintaining and
growing the primitive collection.

## Routing

| Command | Action |
|---------|--------|
| `/curate` | Full curation session (all phases below) |
| `/curate scan` | Scan external sources for new skills worth indexing |
| `/curate improve` | Synthesize observations into discrete improvements |
| `/curate brainstorm` | Identify gaps, propose new primitives |
| `/curate audit` | Review existing skills for quality, overlap, staleness |
| `/curate research` | Research power users, best practices, ecosystem trends |

## Full Curation Session

### Phase 1: Ecosystem Scan

Research what's new in the agent skills ecosystem:

1. **Check indexed sources** — Run `python3 scripts/generate-embeddings.py --dry-run`
   to see current source coverage. Are there new skills in existing sources?

2. **Discover new sources** — `/research web-search` for:
   - New skill repos on GitHub (search "SKILL.md" agent skills)
   - skills.sh marketplace for trending skills
   - Posts/threads about effective Claude Code / Codex workflows
   - Power user setups and custom agent configurations

3. **Evaluate candidates** — For each discovered skill/source:
   - Does it fill a gap in our library?
   - Is it high quality? (check frontmatter, structure, references)
   - Does it overlap with something we already have?
   - Would our users actually use it?

4. **Update sources** — If a new repo is worth indexing, add it to
   `EXTERNAL_SOURCES` in `scripts/generate-embeddings.py` and regenerate.

### Phase 2: Observation Synthesis

Process accumulated feedback from consuming projects:

1. **Collect** — Find all `.spellbook/observations.ndjson` files:
   ```bash
   find ~/Development -name "observations.ndjson" -path "*/.spellbook/*" 2>/dev/null
   ```

2. **Cluster** — Group by primitive FQN. Primitives with 2+ observations
   have a real pattern.

3. **Act** — For each cluster:
   - High confidence (>= 0.8): Direct PR with the fix
   - Medium (0.5–0.8): Create a GitHub issue with evidence
   - Low (< 0.5): Keep logging, note the pattern

### Phase 3: Brainstorm

Identify gaps and propose new primitives:

1. **Run `/research thinktank`** with:
   - Current skill inventory (from index.yaml)
   - Recent user workflows and pain points
   - Question: "What recurring workflows are NOT covered by a skill?"

2. **Cross-reference with ecosystem** — Compare our coverage against
   anthropics/skills, openai/skills, vercel-labs/agent-skills.
   What do they have that we don't? What do we have that's unique?

3. **Propose** — For each candidate new primitive:
   - What gap does it fill?
   - Who would use it? How often?
   - Could an existing skill be extended instead?
   - Effort estimate

### Phase 4: Audit Existing Skills

Review the current library for quality and relevance:

1. **Overlap detection** — Run `python3 scripts/search-embeddings.py` with
   each skill's description as query. High similarity between two skills
   (> 0.85) suggests consolidation.

2. **Staleness check** — For each skill:
   - When was it last modified? (`git log -1 --format=%ci skills/{name}/`)
   - Does it reference tools/APIs that have changed?
   - Is the description still accurate?

3. **Quality gate** — Spot-check frontmatter:
   - Description present and meaningful?
   - Trigger phrases included?
   - References load correctly?

4. **Consolidation candidates** — Skills that overlap heavily should be
   merged (one absorbs the other as references).

5. **Deletion candidates** — Skills with no clear user, stale content,
   or zero observations should be considered for removal.

### Phase 5: Apply Changes

For each proposed change from phases 1-4:

1. Make the edit to the canonical skill/agent
2. Run `./scripts/generate-index.sh`
3. Run `python3 scripts/generate-embeddings.py`
4. Commit with descriptive message
5. Update `.spellbook.yaml` if the change affects this repo's manifest

## Anti-Patterns

- Adding skills because they exist, not because they fill a gap
- Keeping skills "just in case" when no one uses them
- Reviewing skills without checking consuming project observations
- Brainstorming without researching what the ecosystem already offers
- Auditing quality without checking actual usage patterns
