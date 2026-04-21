# Thinktank Review

Multi-provider review bench via Pi. 10 reviewers across 8 model providers.
This is where foundation diversity comes from — the philosophy bench is
same-model depth, thinktank is different-model breadth.

## Invocation

```
thinktank review --base $BASE --head HEAD --output /tmp/thinktank-review --json
```

- `$BASE` — merge target (usually `origin/master` for this repo).
- `--json` — structured output for programmatic consumption.
- `--output` — directory for raw agent reports and synthesis.
- Treat the command as long-running. If your shell tool returns a live
  session, keep polling until the `thinktank` process exits.

## What It Runs

Thinktank's `marshal` planner selects which of 10 reviewers apply to the
diff. Each runs on a different model provider (xAI, OpenAI, Google, Z-AI,
Minimax, Inception, Moonshot, Xiaomi). They cover correctness, security,
architecture, testing, API contracts, runtime risks, integration, craft,
upgrade paths, and operability.

For Spellbook diffs the most load-bearing thinktank lenses are typically:

- **architecture** — cross-harness parity (Red Line), self-containment.
- **craft** — SKILL.md as judgment-not-procedure, description as trigger.
- **operability** — does the Dagger gate still pass? does the pre-commit
  hook still regen `index.yaml`?
- **upgrade paths** — does this break existing `.agents/skills/` installs
  in downstream repos?

## Output

- `stderr` — newline-delimited JSON progress heartbeats. Earliest reliable
  signal that the run is alive and which phase it's in.
- `trace/summary.json` — run status. Treat the run as finished only when
  `status` is `complete` or `degraded`.
- `trace/events.jsonl` — lifecycle events. `run_completed` is the explicit
  completion sentinel.
- `agents/` — one report per reviewer. May stay empty until late in the run
  while a slow reviewer finishes.
- `review.md` and `summary.md` — aggregated findings across the bench.
- stdout JSON — final machine-readable result: agent metadata, artifact
  paths, synthesized review text, overall status.

Consume `review.md`, `summary.md`, or the final stdout JSON as one
reviewer's report in your overall synthesis. If a finding is ambiguous,
read the raw agent report for detail.

## Gotchas

- Thinktank runs its own internal synthesis. Don't double-synthesize —
  treat its output as one voice among your tiers, not as pre-processed
  truth.
- Do not inspect the output directory mid-run and assume it is stalled or
  missing synthesis. `review.md`, `summary.md`, and `agents/*.md` can
  appear only near the end, after the slowest reviewer finishes.
- `thinktank review eval` is broken in `thinktank 6.3.0` and crashes with
  `IO.chardata_to_string(nil)` from `lib/thinktank/review/eval.ex:45`. Do
  not rely on it for post-run consumption until the CLI is fixed.
- If thinktank fails or times out, proceed with the other judgment tiers.
  Don't block the entire review on one provider.
