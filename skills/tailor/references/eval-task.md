# Canned Task Derivation — /tailor Phase 4

The A/B eval needs one canned task that exercises tool-use patterns
typical for this repo. Runs in both worktrees via `claude -p`,
measured by `tailor-ab-spike.sh`.

## Good task properties

- **Multi-tool** (3–10 expected tool calls — single-Read tasks give
  noisy signal)
- **Deterministic** (same prompt + same repo state = comparable output)
- **Binary `passed`** (`is_error` maps to a real verdict)
- **Short** (≤60s typical — long tasks amplify noise)
- **Representative** (looks like real work a user would ask for)

## Derivation priority

From Phase 1's ci-inspector output:

1. **`test_cmd` exists** — use the test-count template:
   > Run `$test_cmd` and output ONLY the count of failing tests as
   > a single integer. If all tests pass, output 0.

2. **`lint_cmd` exists but no `test_cmd`** — use lint-count:
   > Run `$lint_cmd` and output ONLY the count of lint warnings as
   > a single integer.

3. **Neither exists** — **abort** Phase 4. Per 029 Failure Modes, no
   synthetic fallback. Synthetic tasks don't exercise the agent's
   real load paths and give false-positive A/B signals. Tell the
   user: "cannot tailor without a test or lint command."

## User override

`--task "<custom>"` bypasses derivation. Store in manifest as
`{task, task_source: "user"}`. Refresh preserves the override.

## Invariants

- Task is **frozen** at generate-time in `manifest.eval.task`.
  Refreshes reuse it — apples-to-apples across runs.
- Task must run in a fresh `git worktree add` with no side effects
  beyond the canned output (no DB writes, no unbounded network
  calls).

## Bad tasks to avoid

- "Summarize this repo" — subjective, no binary passed
- "Add a new feature" — non-deterministic
- "Fix any failing tests" — unbounded, can loop indefinitely
