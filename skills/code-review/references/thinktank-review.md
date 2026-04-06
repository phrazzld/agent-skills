# Thinktank Review

Multi-provider review bench via Pi. 10 agents across 8 model providers.

## Invocation

```
thinktank review --base $BASE --head HEAD --output /tmp/thinktank-review --json
```

- `$BASE` — the merge target (usually `origin/main` or `origin/master`)
- `--json` — structured output for programmatic consumption
- `--output` — directory for raw agent reports and synthesis

## What It Runs

Thinktank's `marshal` planner selects which of 10 reviewers apply to the diff.
Each reviewer runs on a different model provider (xAI, OpenAI, Google, Z-AI,
Minimax, Inception, Moonshot, Xiaomi). They cover correctness, security,
architecture, testing, API contracts, runtime risks, integration, craft,
upgrade paths, and operability.

## Output

- `agents/` — one report per reviewer agent
- `synthesis.md` — aggregated findings across the bench

Consume the synthesis as one reviewer's report in your overall synthesis.
If a finding in the synthesis is ambiguous, read the raw agent report for detail.

## Gotchas

- Thinktank runs its own internal synthesis. Don't double-synthesize — treat
  its output as one voice among your tiers, not as pre-processed truth.
- If thinktank fails or times out, proceed with the other two tiers. Don't
  block the entire review on one provider.
