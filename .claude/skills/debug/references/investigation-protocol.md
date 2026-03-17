# Production Investigation Protocol

Absorbed from the `investigate` skill.

## SRE Investigation Approach

### Config Before Code Checklist

1. Env vars present? `npx convex env list --prod`, `vercel env ls`
2. Env vars valid? No trailing whitespace, correct format (sk_*, whsec_*)
3. Endpoints reachable? `curl -I -X POST <webhook_url>`
4. Then examine code

### Toolkit

- **Observability**: sentry-cli, npx convex, vercel
- **Git**: Recent deploys, changes, bisect
- **Gemini CLI**: Web-grounded research, hypothesis generation
- **Thinktank**: Multi-model validation on hypotheses

### Multi-Hypothesis Mode (Agent Teams)

When >2 plausible root causes:

1. Create agent team with 3-5 investigators
2. Each teammate gets one hypothesis to prove/disprove
3. Teammates challenge each other's findings
4. Lead synthesizes consensus root cause into incident doc

### Observable Proof Requirements

Before declaring "fixed":
- Log entry that proves the fix worked
- Metric that changed (subscription status, webhook delivery)
- Database state that confirms resolution

Mark investigation as UNVERIFIED until observables confirm.

### INCIDENT.md Work Log Format

```markdown
## Timeline
- HH:MM UTC: [event]

## Evidence
- [log/metric/config checked]

## Hypotheses
1. [hypothesis] - likelihood: [high/medium/low]

## Actions
- [what tried] -> [what learned]

## Root Cause
[when found]

## Fix
[what resolved it]

## Postmortem
- What went wrong
- Lessons learned
- Follow-ups
```

### Sentry Integration

When issue body contains Sentry context:
- Extract stack trace, file paths, breadcrumbs
- Use Sentry MCP for full event details
- Cross-reference affected files with `git log` for causal commit
- Include Sentry issue link in PR for auto-resolution on deploy
