# Spellbook Feedback Loop

When the fix target is a Spellbook-managed skill (has `.spellbook` marker),
the improvement should flow back to the canonical source.

## High Confidence: Direct Push

If the fix is clear and you're certain:

1. Read the `.spellbook` marker to get `source` and `name`
2. Clone/worktree the spellbook repo (or use local if available)
3. Edit the canonical skill
4. Commit with message: `fix(skill-name): [what was wrong]`
5. Open PR against spellbook

The consuming project gets the fix on next `/focus sync`.

## Lower Confidence: Log Observation

If you're not sure what the right fix is, or it needs more evidence,
use the `log_observation.py` script:

```bash
scripts/log_observation.py \
  --primitive "phrazzld/spellbook@skill-name" \
  --type friction \
  --summary "Brief description" \
  --context "Detailed context" \
  --confidence 0.6
```

Or append manually to `.spellbook/observations.ndjson`:

```json
{
  "timestamp": "2026-03-16T22:00:00Z",
  "primitive": "phrazzld/spellbook@autopilot",
  "type": "friction|gap|error|enhancement",
  "summary": "Brief description of observation",
  "context": "Detailed context about what happened",
  "confidence": 0.6
}
```

## Observation Types

- **friction** — skill works but is awkward or slow for this use case
- **gap** — skill doesn't cover a scenario it should
- **error** — skill gave wrong instructions
- **enhancement** — skill could be better with an addition

These accumulate across sessions. Use `/focus improve` to synthesize
observations into discrete spellbook improvements.
