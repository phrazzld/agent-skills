# Focus Init

Generate a `.spellbook.yaml` manifest for a project that doesn't have one.

## Philosophy

Don't start by searching the catalog. Start by understanding the project
deeply, then reason from first principles about what domain knowledge
would make an agent most effective here. Search comes after thinking.

## Process

### Phase 1: Deep Project Analysis

Read everything available to understand what this project IS:

| Signal | Where |
|--------|-------|
| Project purpose, tech stack | `CLAUDE.md`, `README.md`, `AGENTS.md` |
| Dependencies | `package.json`, `go.mod`, `mix.exs`, `Gemfile`, `requirements.txt`, `Cargo.toml` |
| Directory structure | `ls` top-level dirs |
| Recent activity | `git log --oneline -20` |
| External services | `.env.example`, config files, API references |
| Existing skills | `.claude/skills/`, `.agents/skills/` |

Synthesize a 1-2 paragraph description of the project covering:
what it does, what tech it uses, what domains it touches, what
external services it integrates with.

### Phase 2: First-Principles Skill Design

Using context-engineering and harness-engineering thinking, reason about
what domain knowledge would make an agent most effective in this project.
Do NOT look at the catalog yet. Think from the project's needs.

**Answer these questions:**

1. **What domains does this project touch?** (payments, auth, data pipeline,
   frontend framework, mobile, infrastructure, etc.)
2. **What external services does it integrate with?** (Stripe, AWS, Vercel,
   Sentry, PostHog, database provider, etc.)
3. **What recurring agent tasks would benefit from domain expertise?**
   (e.g., "writing Stripe webhook handlers requires knowing idempotency
   patterns, event types, and signature verification")
4. **What are the most common failure modes an agent would hit?**
   (e.g., "Next.js App Router caching gotchas", "Convex transaction limits")
5. **What knowledge is NOT already covered by the global process skills?**
   The global skill list lives in `registry.yaml` under `global.skills`.
   Only domain-specific knowledge is missing.

Produce a **wishlist**: a list of ideal domain skill descriptions, independent
of whether they exist in any catalog.

### Phase 3: Search and Match

Now search the Spellbook index for skills matching the wishlist:

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/search.py --project-dir . --top 20 --json
```

Also run targeted searches for each wishlist item:
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/search.py "stripe webhook patterns" --top 5 --json
python3 ${CLAUDE_SKILL_DIR}/scripts/search.py "Next.js App Router" --top 5 --json
```

**Critical filter:** Exclude all global skills from results. These are
already available and must never appear in the manifest. The canonical
list is in `registry.yaml` under `global.skills`.

For each search result, map it against the wishlist:
- Does this skill address a concrete wishlist item?
- Is the match precise or vague?

### Phase 4: Diff — Identify the Gaps (Most Valuable Phase)

Compare the wishlist against search results:

| Wishlist Item | Match Found? | Skill Name | Quality |
|--------------|-------------|------------|---------|
| Stripe webhook patterns | Yes | stripe | Strong |
| Next.js caching gotchas | Yes | next-patterns | Strong |
| Custom auth middleware | No | — | **GAP** |
| Convex transaction patterns | No | — | **GAP** |

**For items with strong matches:** Add to manifest.

**For items with no match — THESE ARE THE MOST VALUABLE OUTPUT.**

Gaps represent knowledge the model doesn't have in its training data:
- Specific best practices for this domain/stack combination
- Integration gotchas and failure modes learned through production experience
- Process patterns specific to this kind of project
- Conventions and invariants that aren't documented anywhere public

**Do not treat gaps as a footnote.** Present them as the primary opportunity.
Every gap is a skill waiting to be created — and gap-born skills are the
highest-leverage primitives in the library because they encode exactly
what the model can't already do on its own.

### Phase 5: Generate Manifest

```yaml
# .spellbook.yaml
# Domain skills for [project description]
# Global skills (13) + agents (4) are available via bootstrap.
skills:
  - stripe
  - next-patterns
  - anthropics/skills@frontend-design
agents:
  - stripe-auditor
```

### Phase 6: Present for Confirmation

Show the user:

1. **Project analysis** (what was detected)
2. **Wishlist** (what domain knowledge would be ideal)
3. **Matched skills** with reasoning
4. **Skill gaps** — wishlist items with no match

For each gap, offer:
> "No existing skill covers [X]. Want me to draft a new skill for this
> and open a PR to spellbook?"

Only write manifest after explicit confirmation.

### Phase 7: Create Skills for Gaps

**This is NOT optional.** For every gap identified in Phase 4, actively
propose creating a new skill. Present a concrete 1-2 sentence description
of what each gap skill would contain, then ask which ones to create.

**Default: create in spellbook.** Most domain skills (Electron patterns, Supabase
integration, testing frameworks, cloud providers) are broadly applicable. If another
project could ever use it, it belongs in the spellbook repo — not project-local.

**Project-local only when:** The skill encodes knowledge specific to THIS repo that
no other project would use — internal module APIs, company-specific conventions,
proprietary infrastructure, or repo-specific deployment workflows.

When in doubt, ask: "Would I want this skill if I started a new project with the
same tech stack?" If yes → spellbook.

When creating gap skills, invoke `/primitive` which runs the full research
and context-engineering pipeline. Don't create shallow placeholder skills —
the whole point is to encode knowledge the model doesn't already have.

For each gap the user approves:

1. Use `/primitive create {name}` — runs research, context-engineering, and
   harness-engineering to craft a skill that goes beyond training data
2. Create a branch in the local spellbook repo (or a worktree)
3. Write the skill to `skills/{name}/SKILL.md` in the spellbook repo
4. Generalize: strip project-specific references, use generic examples
5. Also create matching agents if the domain warrants auditing (e.g., `electron-architect`, `supabase-auditor`)
6. Open a PR with the new skill(s) and agent(s)
7. Add the skill name to the project's manifest (available after merge + re-index)

This is how spellbook grows — organically from real project needs, with
each new skill encoding domain knowledge that makes agents genuinely
more effective than they'd be from base model capabilities alone.

### Phase 8: Run Sync

After writing the manifest, immediately run the sync flow to install
the declared domain primitives.

## External Sources

Skills from external sources use fully qualified names (FQN):

```yaml
skills:
  - stripe                                       # phrazzld/spellbook (default)
  - anthropics/skills@frontend-design            # external source
  - vercel-labs/agent-skills@vercel-react-best-practices
  - garrytan/gstack@qa                           # gstack source
```

Unqualified names resolve to `phrazzld/spellbook`. Any other source
must use `owner/repo@skill-name` format.
