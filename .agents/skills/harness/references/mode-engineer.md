# /harness engineer (in spellbook)

Design improvements to spellbook's harness infrastructure: gates,
hooks, codification targets, composition boundaries. You are
modifying the mechanism, not producing a skill.

## Codification hierarchy

When encoding knowledge, target the highest-leverage mechanism
available:

```
Type system > Lint rule > Hook > Test > CI > Skill > AGENTS.md > Memory
```

In spellbook specifically, the mapping is:

- **Lint / Test / CI**: a new gate in `ci/src/spellbook_ci/main.py` or
  a new `scripts/check-*.sh` invoked from one.
- **Hook**: a new entry in `harnesses/claude/hooks/` (Claude-specific,
  async telemetry OK), or in `.githooks/` (harness-agnostic, required
  for enforcement). Harness-agnostic is the default.
- **Skill**: a new `skills/<name>/` — last resort, because it pays
  description tax always-on.
- **AGENTS.md**: `harnesses/shared/AGENTS.md` only. Principles file;
  keep it lean. Every harness symlinks to it.

## The Norman test (every mechanism)

1. **Can an agent make this error?** — The harness allows it. Add
   prevention.
2. **Does the harness make this error likely?** — The harness
   induces it. Redesign.
3. **After an error, does the response fix the system?** — If not,
   you are teaching burner labels. Redesign the stove.

Prose in SKILL.md is a burner label. Hooks are the redesigned stove.

## The 12 Dagger gates as reference form

When adding a new check:

- Implement it as a `@function async def check_<name>(...)` in
  `ci/src/spellbook_ci/main.py`, wrapped in `_lint_container(source)`.
- If the check is shell-based, commit the script to
  `scripts/check-<name>.sh` and have the Dagger function call it.
- Add the new gate to the composite `check()` function at the bottom
  of `main.py` so `dagger call check --source=.` includes it.
- Match the `Ignore([".git", "__pycache__", ".venv", "ci",
  "skills/.external"])` pattern on the `source` parameter.
- Name the gate `check-<thing>` (dashes), function `check_<thing>`
  (underscores). The dashed form is what the load-bearing-gate table
  in repo-brief documents.

## Hooks are the highest-leverage investment

Hooks run on every tool use. CLAUDE.md is read once. A pre-commit
hook that regenerates `index.yaml` is infinitely more reliable than a
CLAUDE.md line that says "remember to regenerate `index.yaml`."

Prior art in this repo:

- `.githooks/pre-commit` — regenerates `index.yaml` when
  `skills/`/`agents/` change; runs
  `scripts/check-harness-agnostic-installs.sh`; blocks force-adds of
  `.spellbook/deliver/<ulid>/(state|receipt).json`.
- `.githooks/pre-merge-commit` — verdict gate for non-FF merges.
  Escape hatch: `SPELLBOOK_NO_REVIEW=1`.
- `.githooks/post-commit` / `post-merge` / `post-rewrite` — re-run
  `./bootstrap.sh` when skill/agent content changed so global
  symlinks stay current across machines.
- `harnesses/claude/hooks/` — Claude-only telemetry hooks (async,
  PostToolUse). Harness-specific is acceptable here because these are
  read-only side effects, not enforcement.

Enforcement hooks: harness-agnostic (`.githooks/` or Dagger).
Telemetry hooks: per-harness is fine (async, side-effect-free).

## Workflow layering

Spellbook enforces strict layering between skills. When designing a
new composer, know which tier you are in:

- **Leaf skills** own one domain, runnable standalone. Examples:
  `/ci`, `/refactor`, `/qa`, `/code-review`, `/shape`, `/implement`.
- **Inner-loop composer**: `/deliver` — orchestrates leaves around
  one bounded objective (ticket → merge-ready). Lint-enforced:
  `check-deliver-composition` forbids inlining phase-skill internals.
- **Outer-loop composer**: `/flywheel` — cycles the inner loop over
  multiple tickets with deploy/monitor/reflect between each.

Aliases are vocabulary, not new domains. `/land` is a landing mode
of `/settle`, not a separate skill with independent contract.

Redundancy test when adding a skill:

- If a composer explains a leaf's internal methodology in detail, that
  is drift. The composer should invoke or reference the leaf and add
  only the boundary judgment it owns.
- If two skills can both plausibly claim authoritative ownership of
  the same concern, the boundary is wrong. Pick one owner; make the
  other compose it.

## Cross-harness-first design rule

Primary layer is filesystem + SKILL.md. Every harness scans a skills
dir at startup. Features built on that are portable by construction.

When a mechanism legitimately needs runtime toggling (enable/disable
a set of skills per-repo, for instance), emit per-harness artifacts
from one source. Prior art: `harnesses/pi/settings.json:skills[]`
glob — filesystem-level allow/deny that works by construction. A
cross-harness design would render the same glob rules into Claude's
`enabledPlugins` and Codex's `/plugins` from one in-repo manifest.

A design that answers "works on Claude only" fails the Red Line. If
you can't answer "what does this do on Codex and Pi?", the design is
incomplete.

## Thin harness default

Before writing scripts, schemas, or state machines, ask: "can the
agent just do this?" Usually yes. Reference form:
`skills/flywheel/SKILL.md` (~43 lines — cycles, composition, invariants,
nothing more).

Strong smells, any of which means redesign:

- Regexes over agent prose (agent output is not a program).
- Semantic workflow DSLs wrapped around general-purpose agents
  (you are reinventing flow control in markdown).
- Phase-0/Phase-N state machines inside SKILL.md.
- Exit-code routing tables to recover agent meaning.
- Scoring scripts that interpret free-form agent output deterministically.

## Stress-test after model upgrades

Every skill encodes an assumption about model limitations. When a new
model drops, audit: is this skill still needed? Is this hook still
catching real problems? Strip what isn't load-bearing. `/harness eval`
is how you check; `/harness audit` is how you find candidates.

## AGENTS.md is a map, not a manual

`harnesses/shared/AGENTS.md` (and any per-harness variants) points to
skills and references. It is NOT the container for instructions.
Monolithic AGENTS.md becomes a graveyard of stale rules. The rule of
thumb: if a section would be better as a skill's SKILL.md, make it
one.
