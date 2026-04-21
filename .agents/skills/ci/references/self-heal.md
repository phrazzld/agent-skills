# Self-Heal Scope — Spellbook

When `dagger call check --source=.` goes red, `/ci` must classify and
decide: run `dagger call heal`, fix manually, or escalate. Heal is
bounded by design — it repairs **exactly one** failing lint-style gate
per run, capped at `--attempts=2` by default.

## What Heal Can Do

`ci/src/spellbook_ci/heal_support.py:HEALABLE_GATES`:

| Gate                | Repair instruction baked into the prompt |
|---------------------|------------------------------------------|
| `lint-yaml`         | Fix YAML syntax or structural issues without changing meaning. |
| `lint-shell`        | Fix shellcheck errors without changing script behavior. |
| `lint-python`       | Fix Python syntax or import errors without changing behavior. |
| `check-frontmatter` | Fix invalid frontmatter metadata without broad rewrites. |

`select_healable_failure()` rejects any input that isn't exactly one
healable failure — multi-gate red, or a non-lint red, both raise.
This is deliberate: heal is a repair agent, not a rescue mission.

## Decision Protocol

For each failing gate from `check()`'s summary:

1. **Is it in `HEALABLE_GATES`?**
   - Yes + only one total failure → run `dagger call heal`.
   - Yes + other gates also red → fix the others first (usually
     manually), then heal the remaining lint.
   - No → escalate.
2. **Is it a derived-artifact drift?** (`check-index-drift`,
   `check-vendored-copies`) → manual fix with a known command, not heal.
3. **Is it a contract signal?** (`test-bun`, `check-exclusions`,
   `check-portable-paths`, `check-harness-install-paths`,
   `check-deliver-composition`, `check-no-claims`) → escalate.
4. **Is it a flake?** Containers are hermetic; flakes are rare. Retry
   once before classifying.

If ambiguous, escalate. False-escalate costs a human glance. False-fix
silently ships wrong code.

## Running Heal

```bash
dagger call heal --source=. --model=gpt-4.1 --attempts=2
```

Returns a `dagger.Directory` with the repaired tree. Typical flow:

```bash
# Export to a sibling directory, inspect, apply by hand.
dagger call heal --source=. export --path=./.spellbook/heal-out
git diff --no-index -- . .spellbook/heal-out

# If the diff is minimal and correct, apply and commit.
rsync -a --delete .spellbook/heal-out/ ./   # or copy specific files
git add -p
git commit -m "ci: heal <gate-name>"

# Verify.
dagger call check --source=.
```

Heal does not commit for you. It returns a directory and exits. Commit
discipline — small, scoped, one gate per commit — stays with the human
driver of `/ci`.

## Manual Self-Heals (outside the heal agent)

### `check-index-drift`

Mechanical, deterministic. Not a heal-agent candidate.

```bash
bash scripts/generate-index.sh
git add index.yaml
git commit -m "chore: regenerate index.yaml"
```

Root cause is almost always "committed `skills/` change without
running pre-commit hook." Check `git config core.hooksPath` points at
`.githooks`; if not, `bootstrap.sh` should have set it and hasn't been
run.

### `check-vendored-copies`

```bash
bash scripts/check-vendored-copies.sh    # reads diagnostic locally
# Edit the canonical source (never the vendored copy directly).
# Re-run sync if the repo has one, or hand-copy.
dagger call check-vendored-copies --source=.
```

### `check-harness-install-paths`

Rewrite Claude-only install wording to harness-agnostic form. The
script's diagnostic points at the offending line. Typical pattern:
`~/.claude/skills/` → `~/.claude/skills/ or ~/.codex/skills/ or
~/.pi/skills/` (or reference `bootstrap.sh` directly).

## Escalate Categories

Structured diagnosis, no silent pass.

### `test-bun` failure

`bun test` under `skills/research/` failed. Test failures encode
behavior contracts. **Never** fix by editing the assertion.
**Never** `.skip()` it (`check-exclusions` will catch that anyway).
Surface: file, line, assertion, candidate cause (one sentence).

### `check-exclusions` / `check-portable-paths` failure

Someone added a suppression or hardcoded path. Fix the underlying
code; do **not** add to the gate's ALLOW / SKIP set unless the
allowance is legitimately scoped.

### `check-harness-install-paths` failure

Install copy became Claude-only. Rewrite to harness-agnostic form.
If the copy *must* be Claude-only (e.g. documentation specifically
about Claude plugin features), move it under `harnesses/claude/`.

### `check-deliver-composition` failure

`skills/deliver/SKILL.md` started inlining phase-skill internals.
Refactor to trigger-syntax composition (`/ci`, `/qa`, `/code-review`,
etc.) — never delete the gate. See backlog.d/032.

### `check-no-claims` failure

`claims.sh` / `claim_acquire` / `claim_release` resurfaced under
`skills/`. These were deliberately removed in backlog.d/032.
Removing the gate to accommodate reintroduction is a product
decision, not a heal case.

### Multi-gate red

`select_healable_failure` raises. Fix manually:

1. Triage each failure independently.
2. Fix the non-lint ones first (they're usually the root cause of
   downstream lint noise).
3. Re-run `dagger call check`.
4. If exactly one lint-style gate remains, heal it.

## Bounded Retries

`--attempts=2` is the default. Inside heal's loop:

1. Launch a Dagger `llm()` agent with a writable `builder` container
   at `/src` (see `_repair_container` + `_repair_prompt` in
   `main.py`).
2. Agent repairs, binds updated container to `$repaired`.
3. Heal re-runs the target gate on the repaired directory, then the
   full `check()`.
4. On failure, the next attempt uses the partially-repaired tree as
   its input.
5. After `--attempts` exhausted, heal raises with the last error.

Running with `--attempts=3` or higher is a smell — if two bounded
passes don't converge, the failure isn't what the classifier said it
was. Escalate.

## Red Lines

- Never lower a threshold, loosen a severity, or expand an ALLOW set
  to make a gate pass.
- Never `@skip` / `.skip()` / comment out a failing bun test.
- Never edit `index.yaml` by hand to match the generator.
- Never delete a gate (`check-no-claims`, `check-deliver-composition`,
  etc.) to unblock a commit — gates enforce ratified doctrine.
- Never exceed the heal attempt budget. If `--attempts=2` didn't
  converge, escalate.
- Never feed heal more than one failing gate. `select_healable_failure`
  is the contract; bypassing it is bypassing the design.

Any proposal to cross one of these is itself an escalation signal.
Surface to the human — do not execute.

## Diagnosis Format

```markdown
## /ci Escalation
Gate: <gate-name>
Command: dagger call <function> --source=.
Status: failed (not in HEALABLE_GATES | heal attempts exhausted | multi-gate red)
Failure:
  <file>:<line>
  <error excerpt, verbatim>
Classification: <category from above>
Candidate cause: <one sentence hypothesis, if clear>
Suggested first file to read: <path>
```

Structured output, not a prose dump. Let the human move fast.
