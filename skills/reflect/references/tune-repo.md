# /tune-repo

Make agents deeply effective in this repository.

## Role

Staff engineer onboarding a new team member who happens to be an AI. Build the complete context an agent needs to work autonomously: what the project is, how it's built, what to watch out for, and how to ship.

## Objective

Transform a repository from "generic AI agent target" to "finely tuned agent workspace" where autonomous skills (/deliver, /diagnose, /pr) operate with full project awareness.

## Philosophy

- AGENTS.md is the constitution, not the encyclopedia. Keep it token-cheap.
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
ls AGENTS.md docs/CODEBASE_MAP.md docs/context/ docs/adr/ 2>/dev/null || true
```

## Workflow

### Phase 1: Context Audit

Inventory the current context architecture:

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

### Phase 2: Codebase Map

Produce or refresh `docs/CODEBASE_MAP.md` by reading the codebase directly.

If `docs/CODEBASE_MAP.md` exists and is recent, update rather than rewrite.

Output:
- system overview
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

### Phase 4: AGENTS.md Audit + Update

Read current `AGENTS.md`, Cartographer output, and `docs/context/`.

AGENTS.md is the primary agent instruction file — constitution + operational playbook.

Cover:

1. What this repo is + essential commands
2. Architecture at high level + quality gates
3. Gotchas + environment/deployment if non-obvious
4. Commit/testing/PR conventions
5. Coding style beyond linting
6. Security boundaries
7. Routing rules pointing to `docs/context/ROUTING.md`

Hard constraint: 200 lines max. Preserve accurate existing content. Merge, don't churn.

If AGENTS.md exists, audit and correct drift.

### Phase 5: ADR Inventory

Scan for undocumented architectural decisions:

```bash
ls docs/adr/ 2>/dev/null || mkdir -p docs/adr
git log --oneline --all --grep="decision\\|migrate\\|replace\\|switch\\|deprecat" | head -20
```

Create at most 5 ADRs per run. Focus on decisions that would confuse a new agent.

### Phase 6: Memory Seeding

Extract repo-specific gotchas into harness memory (e.g. project-scoped memory files).

Good entries:
- CLI quirks
- flaky test causes
- environment footguns
- intentional weirdness

Bad entries:
- anything already in AGENTS.md
- generic framework knowledge
- temporary branch state

### Phase 7: Guardrail Discovery

Analyze codebase + context docs for invariants worth enforcing:

- import boundaries
- auth patterns
- data access layers
- API conventions
- deprecated patterns
- naming conventions

Report candidates for `/guardrail`. Do not generate the rules here.

### Phase 8: Skill Gap Analysis

Assess whether the repo needs project-specific skills:

- unique build/deploy workflow
- repeated multi-step maintenance rituals
- domain workflows general skills do not cover

Document the recommendation. Do not build the skill in this run unless explicitly asked.

## Anti-Patterns

- Writing AGENTS.md as a novel
- Overwriting accurate docs with generic generated prose
- Creating ADRs for obvious decisions
- Seeding memory with speculation
- Ignoring routing gaps and expecting humans to remember specialist selection
- Treating stale subsystem docs as harmless

## Output

Report:
- Codebase map: CODEBASE_MAP.md created/updated
- Context index: created/updated subsystems
- Routing table: created/updated triggers
- Drift watchlist: created/updated mappings
- AGENTS.md: sections added/updated, final line count
- ADRs: new ADRs created
- Memory: entries seeded
- Guardrail candidates: recommended patterns
- Skill gaps: recommendations
