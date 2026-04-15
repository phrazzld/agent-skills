---
name: ci
description: |
  Audit a repo's CI gates, strengthen what is weak, then drive the pipeline
  green. Owns confidence in correctness — lint, types, tests, coverage,
  secrets. Dagger-first. Never returns red without a structured diagnosis.
  Bounded self-heal: auto-fix lint/format, regenerate lockfiles, retry
  flakes. Escalates algorithm/logic failures to the human.
  Use when: "run ci", "check ci", "fix ci", "audit ci", "is ci passing",
  "run the gates", "dagger check", "why is ci failing", "strengthen ci",
  "tighten ci", "ci is red", "gates failing".
  Trigger: /ci, /gates.
argument-hint: "[--audit-only|--run-only]"
---

# /ci

Confidence in correctness. CI is load-bearing: a green CI is a claim about
code correctness. If CI is weak (no type check, shallow tests, no coverage
floor), green means nothing. So this skill **audits first, then runs**.

Stops at green CI. Does not review code semantics (→ `/code-review`), does
not address review comments (→ `/settle`), does not ship.

## Execution Stance

You are the executive orchestrator.
- Keep judgment calls on the lead: what counts as strong CI in this repo,
  which failures are self-healable vs need escalation, whether a proposed
  strengthening is load-bearing or gold-plating.
- Delegate evidence gathering (inventory of configs, pipeline walks) and
  mechanical fixes (auto-format, lockfile regen, narrow test patches) to
  focused subagents.
- Run audit inventory checks in parallel; serialize fix-and-rerun loops.

## Modes

- Default: audit → run. Full pass.
- `--audit-only`: produce audit report and gap proposals; do not run gates.
- `--run-only`: skip audit, just drive gates green.

## Stance

1. **Audit before run.** A weak pipeline passing is worse than a strong
   one failing. Inventory coverage before trusting green.
2. **Dagger-first.** Run gates via `dagger call check` (or the repo's
   pipeline entrypoint). Hermetic, reproducible, matches CI runners.
   Never substitute raw local shells for hermetic containers when a
   Dagger pipeline exists.
3. **Fix-until-green on self-healable failures.** Don't report red and
   exit. Either fix or produce a precise diagnosis the human can act on.
4. **No quality lowering, ever.** Thresholds, lint rules, type strictness,
   coverage floors are load-bearing walls. Raising the floor is fine;
   lowering it to make CI pass is forbidden.
5. **Bounded self-heal.** See `references/self-heal.md` for the fix-vs-
   escalate decision. Algorithm and logic failures escalate.

## Process

### Phase 1 — Audit (skip if `--run-only`)

Read `references/audit.md` for the full audit rubric. Inventory in parallel:

- **Pipeline presence:** `dagger.json` / `.dagger/` exists? Entrypoint
  reachable? (`dagger functions` lists `check`?)
- **Gate coverage:** lint, format, type-check, tests, coverage floor,
  secrets scan — each one covered by a gate, or a gap?
- **Thresholds:** coverage floor ≥70% (calibrate to repo maturity),
  type-check in strict mode, lint rules not silently disabled.
- **Hermeticity:** tests don't hit network/external DBs? Fixtures pinned?
- **Speed:** full pipeline under ~10 minutes? If not, flag (not blocking).
- **Pre-push hook:** invokes the Dagger pipeline? (see
  `.githooks/pre-push` pattern).

Emit a structured audit report:

```markdown
## CI Audit
| Concern        | Status | Severity | Proposed fix                    |
|----------------|--------|----------|---------------------------------|
| lint           | ok     | -        | -                               |
| type-check     | gap    | high     | Add mypy strict to dagger check |
| coverage floor | weak   | med      | Raise floor from 40% → 70%      |
| secrets scan   | gap    | high     | Add gitleaks gate               |
```

For each gap: propose remediation with a diff preview. User approves or
defers per-item. Approved strengthenings are applied as commits before
Phase 2. Deferred items become backlog entries.

If audit finds no gaps worth fixing, say so and proceed.

### Phase 2 — Run (skip if `--audit-only`)

1. Run the pipeline end-to-end: `dagger call check` (or repo equivalent).
2. Capture structured per-gate output (which gate, pass/fail, excerpt).
3. If green → emit report, exit 0.
4. If red → classify each failure per `references/self-heal.md`:
   - **Self-healable** (lint/format drift, stale lockfile, trivially
     fixable import/typo, flake retry): dispatch a focused builder
     subagent to fix, commit, re-run the failing gate.
   - **Escalatable** (logic/algorithm failure, failing test that
     encodes a behavior change, type error in hand-written code, test
     that is genuinely broken): stop. Emit structured diagnosis
     (file:line, gate name, excerpt, candidate cause). Exit non-zero.
5. Bounded retries: cap self-heal attempts at **3 per gate**. Further
   failures escalate even if classified as self-healable — if auto-fix
   isn't converging, the model needs a human look.

### Phase 3 — Verify

Final pass of `dagger call check` after any fixes. Green or bust. If any
gate was strengthened in Phase 1, the full pipeline must pass under the
new thresholds before the skill returns clean.

## What /ci Does NOT Do

- Review code semantics → `/code-review`
- Shape tickets or write specs → `/shape`
- Address review comments or coordinate merges → `/settle` (for now)
- Deploy or release → `/deploy`
- QA against a running app → `/qa`
- Write new test frameworks — uses what the repo has
- Lower any threshold to make a gate pass

## Anti-Patterns

- **Reporting red and exiting** when the failure was a trivially
  auto-fixable format drift.
- **Lowering a threshold** (coverage, lint severity, type strictness)
  to make the gate pass. Any suggestion to do this is a red flag.
- **Skipping audit on a repo you haven't run against before.** If the
  pipeline is weak, green is a lie.
- **Running raw local shells** (`pytest`, `eslint`, etc.) when a Dagger
  pipeline is available. Reproduce what CI actually runs.
- **Unbounded self-heal loops.** 3 retries per gate. If it's not
  converging, stop and diagnose.
- **Auto-fixing a failing test by deleting it** or `@skip`-ing it. A
  failing test is either a bug in the code or a bug in the test —
  diagnose, don't suppress.
- **Auto-fixing a type error by casting to `Any` / `any`** or adding
  `# type: ignore`. Escalate — this is a logic/contract decision.
- **Declaring "green"** while gates are still running. Wait for exit.

## Output

Report:

- **Audit:** gaps found, severity, what was strengthened, what was deferred.
- **Run:** gates attempted, per-gate status, self-heals applied (count +
  summary), escalations (file:line diagnosis).
- **Final:** green / red, exit code, residual risks, backlog items filed
  for deferred strengthenings.

```markdown
## /ci Report
Audit: 2 gaps found (type-check missing, coverage floor 40%).
  → Strengthened: type-check added.
  → Deferred: coverage floor raise (filed as backlog 0XX).
Run: 6 gates, 1 self-heal (ruff auto-fix), 0 escalations.
Final: green. dagger call check passes in 4m12s.
```

On failure:

```markdown
## /ci Report — RED
Gate: test-python
Failure: tests/widget/test_reducer.py::test_merge_conflict line 42
  AssertionError: expected {'a': 1}, got {'a': 1, 'b': 2}
Classification: logic failure (behavior change in reducer)
Action: escalated — human decision needed on reducer contract.
```

## Follow-ups

- `/settle` deprecation (Phase 3 of ticket 034) — deferred. `/settle`
  retains review-comment and merge-coordination responsibilities until
  those split out too. File follow-up ticket after this skill lands and
  bakes for a cycle.
