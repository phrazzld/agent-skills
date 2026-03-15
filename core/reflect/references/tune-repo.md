# /tune-repo

Make agents deeply effective in this repository.

## Role

Staff engineer onboarding a new team member who happens to be an AI. Build the complete context an agent needs to work autonomously: what the project is, how it's built, what to watch out for, and how to ship.

## Objective

Transform a repository from "generic AI agent target" to "finely tuned agent workspace" where autonomous skills (/build, /autopilot, /pr-fix) operate with full project awareness.

## Philosophy

- CLAUDE.md is the constitution, not the encyclopedia. Keep it token-cheap.
- Policy in tracked files. State in memory. Procedures in skills.
- Use tiered context: hot memory, routing, cold memory.
- Document invariants, not obvious mechanics.
- Every gotcha captured now saves 10 agent iterations later.
- Stale specs are load-bearing bugs.

## Preconditions

Verify the repo is ready:

```bash
git rev-parse --is-inside-work-tree
git remote get-url origin
```

Read what already exists:

```bash
ls CLAUDE.md AGENTS.md docs/CODEBASE_MAP.md docs/context/ docs/adr/ 2>/dev/null || true
```

## Workflow

### Phase 1: Context Audit

Inventory the current context architecture:

- `CLAUDE.md`
- `AGENTS.md`
- `docs/CODEBASE_MAP.md`
- `docs/context/INDEX.md`
- `docs/context/ROUTING.md`
- `docs/context/DRIFT-WATCHLIST.md`
- `docs/context/*.md`

Detect:
- missing hot-memory rules
- missing subsystem docs
- routing gaps
- likely stale docs

### Phase 2: Cartographer

Invoke `/cartographer` to produce or refresh `docs/CODEBASE_MAP.md`.

If `docs/CODEBASE_MAP.md` exists and is recent, run in update mode.

Output:
- system overview
- architecture diagrams
- module guide
- data flow
- conventions
- gotchas

### Phase 3: Cold Memory Scaffold

Create or update `docs/context/`:

- `docs/context/INDEX.md` — subsystem -> docs -> source-file map
- `docs/context/ROUTING.md` — trigger table mapping file patterns/signals to specialists or workflows
- `docs/context/DRIFT-WATCHLIST.md` — files changed -> docs to review
- `docs/context/<subsystem>.md` — focused subsystem specs for risky areas

Start with the highest-failure or highest-change subsystems first.

Rules:
- one subsystem per doc
- write for agents, not humans
- include file paths, key APIs, invariants, and failure modes
- stop if you are writing encyclopedias

### Phase 4: CLAUDE.md Audit + Update

Read current `CLAUDE.md`, Cartographer output, and `docs/context/`.

CLAUDE.md should cover only:

1. What this repo is
2. Essential commands
3. Architecture at high level
4. Quality gates
5. Gotchas
6. Environment/deployment if non-obvious

Hard constraint: 200 lines max.

Preserve accurate existing content. Merge, don't churn.

### Phase 5: AGENTS.md Scaffold

AGENTS.md is the operational playbook for AI agents. It covers what CLAUDE.md doesn't: how to work here.

Sections:

1. Commit conventions
2. Testing guidelines
3. PR guidelines
4. Coding style beyond linting
5. Issue workflow
6. Definition of done
7. Security boundaries
8. Routing rules pointing to `docs/context/ROUTING.md`

If AGENTS.md exists, audit and correct drift.

### Phase 6: ADR Inventory

Scan for undocumented architectural decisions:

```bash
ls docs/adr/ 2>/dev/null || mkdir -p docs/adr
git log --oneline --all --grep="decision\\|migrate\\|replace\\|switch\\|deprecat" | head -20
```

Create at most 5 ADRs per run. Focus on decisions that would confuse a new agent.

### Phase 7: Memory Seeding

Extract repo-specific gotchas into:

```text
~/.claude/projects/<escaped-repo-path>/memory/MEMORY.md
```

Good entries:
- CLI quirks
- flaky test causes
- environment footguns
- intentional weirdness

Bad entries:
- anything already in CLAUDE.md
- generic framework knowledge
- temporary branch state

### Phase 8: Guardrail Discovery

Analyze codebase + context docs for invariants worth enforcing:

- import boundaries
- auth patterns
- data access layers
- API conventions
- deprecated patterns
- naming conventions

Report candidates for `/guardrail`. Do not generate the rules here.

### Phase 9: Skill Gap Analysis

Assess whether the repo needs project-specific skills:

- unique build/deploy workflow
- repeated multi-step maintenance rituals
- domain workflows general skills do not cover

Document the recommendation. Do not build the skill in this run unless explicitly asked.

## Anti-Patterns

- Writing CLAUDE.md as a novel
- Overwriting accurate docs with generic generated prose
- Creating ADRs for obvious decisions
- Seeding memory with speculation
- Ignoring routing gaps and expecting humans to remember specialist selection
- Treating stale subsystem docs as harmless

## Output

Report:
- Cartographer: CODEBASE_MAP.md created/updated
- Context index: created/updated subsystems
- Routing table: created/updated triggers
- Drift watchlist: created/updated mappings
- CLAUDE.md: sections added/updated, final line count
- AGENTS.md: created or audited, sections covered
- ADRs: new ADRs created
- Memory: entries seeded
- Guardrail candidates: recommended patterns
- Skill gaps: recommendations
