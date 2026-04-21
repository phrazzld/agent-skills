# Thinktank Review

Multi-provider review bench via Pi. 10 agents across 8 model providers.

## Invocation

```
thinktank review --base $BASE --head HEAD --output /tmp/thinktank-review --json
```

- `$BASE` — the merge target (usually `origin/main` or `origin/master`)
- `--json` — structured output for programmatic consumption
- `--output` — directory for raw agent reports and synthesis
- Treat the command as long-running. If your shell tool returns a live session,
  keep polling until the `thinktank` process exits.

## What It Runs

Thinktank's `marshal` planner selects which of 10 reviewers apply to the diff.
Each reviewer runs on a different model provider (xAI, OpenAI, Google, Z-AI,
Minimax, Inception, Moonshot, Xiaomi). They cover correctness, security,
architecture, testing, API contracts, runtime risks, integration, craft,
upgrade paths, and operability.

## Output

- `stderr` — newline-delimited JSON progress heartbeats. This is the earliest
  reliable signal that the run is still alive and which phase it is in.
- `trace/summary.json` — run status. Treat the run as finished only when
  `status` is `complete` or `degraded`.
- `trace/events.jsonl` — detailed lifecycle events. `run_completed` is the
  explicit completion sentinel.
- `agents/` — one report per reviewer agent. This directory may stay empty
  until late in the run while a long reviewer is still executing.
- `review.md` and `summary.md` — aggregated findings across the bench.
- stdout JSON — final machine-readable result, including agent metadata,
  artifact paths, synthesized review text, and the overall status.

Consume `review.md`, `summary.md`, or the final stdout JSON as one reviewer's
report in your overall synthesis. If a finding is ambiguous, read the raw agent
report for detail.

## Gotchas

- Thinktank runs its own internal synthesis. Don't double-synthesize — treat
  its output as one voice among your tiers, not as pre-processed truth.
- Do not inspect the output directory mid-run and assume it is stalled or
  missing synthesis. `review.md`, `summary.md`, and `agents/*.md` can appear
  only near the end, after the slowest reviewer finishes.
- `thinktank review eval` is broken in `thinktank 6.3.0` and crashes with
  `IO.chardata_to_string(nil)` from `lib/thinktank/review/eval.ex:45`. Do not
  rely on it for post-run consumption until the CLI is fixed.
- If thinktank fails or times out, proceed with the other two tiers. Don't
  block the entire review on one provider.
