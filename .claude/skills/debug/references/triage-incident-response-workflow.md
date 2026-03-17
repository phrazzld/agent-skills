# Incident Response Workflow

Absorbed from the `incident-response` skill.

## Role

Incident commander running the full response lifecycle.

## Latitude

- Multi-AI investigation: Codex (stack traces), Gemini (research), Thinktank (validate)
- Create branch immediately: `fix/incident-$(date +%Y%m%d-%H%M)`
- Demand observable proof -- never trust "should work"

## Full Workflow

1. **Triage** -- Parse Sentry context (stack trace, file paths, breadcrumbs, users)
2. **Investigate** -- Create INCIDENT.md with timeline, evidence, root cause
   - If issue contains Sentry link: query via Sentry MCP for full context
   - `git log --oneline -10` on affected files to find causal PR/commit
3. **Branch** -- `fix/incident-$(date +%Y%m%d-%H%M)` from main
4. **Reproduce** -- Write failing test BEFORE fixing
5. **Fix** -- Delegate to Codex + verify
6. **Verify** -- Observable proof: log entries, metrics, database state
   - Mark UNVERIFIED until confirmed
7. **Auto-revert check** -- If fix unverified within 30 min:
   ```bash
   git revert <causal-commit> --no-edit
   git push
   ```
8. **Postmortem** -- Blameless: summary, timeline, 5 Whys, follow-ups
9. **Prevent** -- If systemic: create prevention issue, optionally `/autopilot`
10. **Codify** -- Regression test, agent update, monitoring rule

## Sentry Integration

When issue body contains Sentry context (auto-filed by Sentry-GitHub integration):
- Extract stack trace, file paths, breadcrumbs from issue body
- Use Sentry MCP for full event details
- Cross-reference affected files with `git log` for causal commit
- Include Sentry issue link in PR for auto-resolution on deploy

## Auto-Detected Issues

Issues labeled `auto-detected` + `bug` are from the observability pipeline.
Treat as P0 unless evidence suggests otherwise.

## Output

Incident resolved, postmortem filed, prevention issue created (if applicable).
PR includes `fixes #<issue>` for Sentry auto-resolution on deploy.
