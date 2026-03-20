# Focus Init

Generate a `.spellbook.yaml` manifest for a project that doesn't have one.

## Philosophy

Don't start by searching the catalog. Start by understanding the project
deeply, then reason from first principles about what domain knowledge
would make an agent most effective here. Search comes after thinking.

Before asking the user to confirm the manifest, persist a structured init
report to `.spellbook/init-report.json`. The report is the cold-memory
artifact for why the selection happened, what was rejected, and which gaps
still need follow-up.

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
python3 ${SKILL_DIR}/scripts/search.py --project-dir . --top 20 --json
```

Also run targeted searches for each wishlist item:
```bash
python3 ${SKILL_DIR}/scripts/search.py "stripe webhook patterns" --top 5 --json
python3 ${SKILL_DIR}/scripts/search.py "Next.js App Router" --top 5 --json
```

**Critical filter:** Exclude all global skills from results. These are
already available and must never appear in the manifest. The canonical
list is in `registry.yaml` under `global.skills`.

For each search result, map it against the wishlist:
- Does this skill address a concrete wishlist item?
- Is the match precise or vague?

### Phase 4: Candidate Matrix — Score, Rank, Select (Most Valuable Phase)

Semantic search is discovery, not selection. Phase 3 finds plausible candidates;
Phase 4 decides which ones to install. The job is **subset design**: choose the
smallest set that covers the repo's domains, tasks, failure modes, and
integrations without redundant overlap.

#### 4a. Build the candidate matrix

For every search result with score > 0.4, build a row with three score
dimensions:

| Dimension | What it measures | How to assess |
|-----------|-----------------|---------------|
| `semantic` | Embedding similarity to the wishlist need | Direct from search.py score (0.0–1.0) |
| `coverage` | How much of an **uncovered** need this fills | Read the candidate's full description. Does it address a domain, failure mode, or integration not yet covered by already-selected candidates? (0.0–1.0) |
| `overlap` | Degree of duplication with already-selected candidates | Compare this candidate's description against every already-selected candidate. Same domain? Same failure modes? Same integration? (0.0–1.0, higher = more overlap) |

Score `coverage` and `overlap` by reading each candidate's full description
against the wishlist item and the set of already-selected primitives. This is
a reasoning task, not a formula — use your judgment to assign interpretable
numbers.

**Scoring order matters.** Process candidates in descending semantic score.
When scoring `coverage` and `overlap` for candidate N, consider candidates
1..N-1 that are already tentatively selected. This makes overlap detection
accumulative — later candidates pay a higher overlap tax if earlier ones
already cover the same ground.

#### 4b. Select and reject with explicit reasoning

For each candidate row, assign a status:

| Status | When |
|--------|------|
| `selected` | High coverage, low overlap, addresses a concrete wishlist need |
| `rejected` | Overlaps heavily with a selected candidate, or too vague to justify |
| `gap` | Wishlist item with no candidate scoring above the match threshold |

**Every rejection needs an explicit rationale.** "Ranked lower" is not a
rationale. Explain WHAT it overlaps with, or WHY the match is too vague.
A human reading the init report should understand why each candidate was
included or excluded without needing to re-derive the reasoning.

When multiple candidates match the same wishlist item, explain why the
selected one is preferred and why the others were excluded. This is the
near-duplicate resolution behavior that makes selection legible.

#### 4c. Identify gaps

Wishlist items with no candidate scoring above the match threshold are gaps.

**Gaps are the most valuable output — not a footnote.** They represent
knowledge the model doesn't have in its training data:
- Domain-specific best practices for this stack combination
- Integration gotchas and failure modes from production experience
- Process patterns specific to this kind of project
- Conventions and invariants not documented anywhere public

Every gap is a skill waiting to be created — gap-born skills are the
highest-leverage primitives because they encode exactly what the model
can't already do on its own.

### Phase 5: Write Init Report

Before manifest confirmation, write `.spellbook/init-report.json` with:

- `repo_summary` — compact analysis of the repo, stack, domains, services,
  and the signals you read
- `wishlist` — first-principles capability wishlist, with why each item matters
- `candidate_matrix` — one row per wishlist item or considered primitive,
  including score (semantic, coverage, overlap), status, rationale, and evidence
- `selected_primitives` — the primitives that should land in `.spellbook.yaml`
- `gaps` — unmet wishlist items and recommended follow-up
- `confidence` — explicit confidence level, strongest evidence, and open questions

Use the helper to validate and write the artifact in one step:

```bash
python3 ${SKILL_DIR}/scripts/init_report.py write \
  --output .spellbook/init-report.json \
  --input /tmp/focus-init-report.json
```

The input payload must satisfy this compact shape:

- `repo_summary.project` must be a non-empty string.
- `repo_summary.stack`, `domains`, `services`, and `signals` must be arrays of non-empty strings.
- `candidate_matrix[*].primitive` and `score` (with `semantic`, `coverage`, `overlap`) are required for concrete candidates (`selected`, `rejected`, etc.); gap rows may omit both.
- `selected_primitives[*].selected_because` is required — explains why this candidate beat alternatives.

```json
{
  "repo_summary": {
    "project": "short description",
    "stack": ["python", "markdown"],
    "domains": ["agent tooling"],
    "services": ["GitHub"],
    "signals": ["README.md", "CLAUDE.md", "git log --oneline -20"]
  },
  "wishlist": [
    {
      "name": "repo tuning",
      "why": "Agents need cold-memory structure and routing guidance."
    }
  ],
  "candidate_matrix": [
    {
      "wishlist_item": "repo tuning",
      "primitive": "phrazzld/spellbook@codified-context-architecture",
      "status": "selected",
      "score": {
        "semantic": 0.82,
        "coverage": 0.9,
        "overlap": 0.05
      },
      "rationale": "Directly addresses repo-level context architecture.",
      "evidence": ["docs/context/** exists", "project vision emphasizes agent workflows"]
    },
    {
      "wishlist_item": "repo tuning",
      "primitive": "phrazzld/spellbook@harness-engineering",
      "status": "rejected",
      "score": {
        "semantic": 0.71,
        "coverage": 0.3,
        "overlap": 0.75
      },
      "rationale": "Overlaps with codified-context-architecture on repo structure; harness-engineering is a global skill and already available.",
      "evidence": ["description overlap on agent-repo interaction", "listed in registry.yaml global.skills"]
    }
  ],
  "selected_primitives": [
    {
      "name": "codified-context-architecture",
      "kind": "skill",
      "selected_because": "Highest coverage for repo-tuning need (0.9) with minimal overlap (0.05). Preferred over harness-engineering which covers the same ground but is already global."
    }
  ],
  "gaps": [
    {
      "name": "factory-specific routing policy",
      "why": "No current primitive encodes these conventions.",
      "next_action": "propose new spellbook skill"
    }
  ],
  "confidence": {
    "level": "medium",
    "summary": "Selection is grounded in repo docs and file layout.",
    "open_questions": ["Should deployment-specific guidance become project-local?"]
  }
}
```

### Phase 6: Generate Manifest

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

### Phase 7: Present for Confirmation

Show the user:

1. **Project analysis** (what was detected)
2. **Wishlist** (what domain knowledge would be ideal)
3. **Matched skills** with reasoning
4. **Skill gaps** — wishlist items with no match
5. **Init report path** — `.spellbook/init-report.json` written and ready to inspect

For each gap, offer:
> "No existing skill covers [X]. Want me to draft a new skill for this
> and open a PR to spellbook?"

Only write manifest after explicit confirmation.

### Phase 8: Create Skills for Gaps

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

When creating gap skills, invoke `/craft-primitive` which runs the full research
and context-engineering pipeline. Don't create shallow placeholder skills —
the whole point is to encode knowledge the model doesn't already have.

For each gap the user approves:

1. Use `/craft-primitive create {name}` — runs research, context-engineering, and
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

### Phase 9: Run Sync

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
