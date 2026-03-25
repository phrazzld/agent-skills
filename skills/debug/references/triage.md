# /triage

Fix production issues. Audit, investigate, fix, verify, postmortem.

## Usage

```bash
/triage                        # Audit and fix highest priority (default)
/triage investigate VOL-456    # Deep dive on specific Sentry issue
/triage investigate-ci 12345   # Deep dive on specific CI run failure
/triage fix                    # Create PR for current fix
/triage verify                 # Verify fix with observable proof
/triage postmortem VOL-456     # Generate postmortem after merge
```

## Stage 1: Production Audit

Invoke `/check-production` primitive for parallel checks:
1. **Sentry** -- Unresolved issues via triage scripts
2. **Vercel logs** -- Recent errors in stream
3. **Health endpoints** -- `/api/health` response
4. **GitHub CI/CD** -- Failed workflow runs

If all clean: "All systems nominal. No action required."

## Stage 2: Investigate

### Sentry Issues (`/triage investigate ISSUE-ID`)

1. Fetch full issue context from Sentry (MCP or CLI)
2. Parse stack trace, file paths, breadcrumbs, affected users
3. Create branch: `fix/incident-$(date +%Y%m%d-%H%M)`
4. Load affected files, check `git log --oneline -10` for causal commit
5. Form root cause hypothesis

### CI/CD Failures (`/triage investigate-ci RUN-ID`)

1. `gh run view RUN-ID --log-failed`
2. Identify failed step and error
3. Create branch: `fix/ci-[workflow]-[date]`
4. Check recent commits for regression

### Delegation

- **Builder sub-agent**: Stack trace analysis, code archaeology
- **/research**: Prior art, known issues, similar incidents
- **/research thinktank**: Validate proposed fix before implementing
- **Parallel investigators**: When >2 plausible root causes (see `/debug`)

### Multi-Hypothesis Mode

When >2 plausible root causes:
1. Create agent team with 3-5 investigators
2. Each teammate gets one hypothesis to prove/disprove
3. Teammates challenge each other's findings
4. Lead synthesizes consensus root cause

## Stage 3: Fix (`/triage fix`)

Prerequisites: On `fix/` branch with changes.

1. **Write failing test first** -- reproduce the error BEFORE fixing
2. Run tests to verify fix
3. Create PR with Sentry issue link (`fixes #<issue>` for auto-resolution)
4. If fix cannot be verified within 30 min, revert the causal commit:
   ```bash
   git revert <causal-commit> --no-edit
   git push
   ```

## Stage 4: Verify (`/triage verify`)

**MANDATORY** -- a fix is just a hypothesis until proven by metrics.

### Verification Protocol

1. **Define observable success criteria:**
   ```
   SUCCESS CRITERIA:
   - [ ] Log entry: "[specific message]"
   - [ ] Metric change: [metric] from [X] to [Y]
   - [ ] Database state: [field] = [expected]
   - [ ] API response: [endpoint] returns [expected]
   ```

2. **Trigger test event:**
   ```bash
   stripe events resend [event_id] --webhook-endpoint [endpoint_id]
   curl -X POST [endpoint] -d '[test payload]'
   ```

3. **Observe results:**
   ```bash
   vercel logs [app] --json | grep [pattern]
   npx convex logs --prod | grep [pattern]
   ```

4. **Verify database state:**
   ```bash
   npx convex run --prod [query] '{"id": "[id]"}'
   ```

5. **Document evidence:**
   ```
   VERIFICATION EVIDENCE:
   - Timestamp: [when]
   - Test performed: [what]
   - Log observed: [paste]
   - Metric before/after: [values]
   - Database confirmed: [yes/no]
   VERDICT: [VERIFIED / NOT VERIFIED]
   ```

### Red Flags (NOT Verified)

- "The code looks right now"
- "It should work"
- "Let's wait and see"
- No log entry observed, metrics unchanged

### If Verification Fails

1. Don't panic -- hypothesis was wrong
2. Revert if fix made things worse
3. Loop back to investigation
4. Question assumptions

## Stage 5: Postmortem (`/triage postmortem ISSUE-ID`)

Prerequisites: Fix deployed (PR merged).

### Blameless Postmortem Structure

- **Summary**: One paragraph -- what, impact, resolution
- **Timeline**: Key events in UTC
- **Root Cause**: Actual underlying cause, not symptoms
- **5 Whys**: Dig to systemic factors
- **What Went Well**: Good practices during response
- **What Went Wrong**: Honest assessment, no blame
- **Follow-up Actions**: Concrete items with ownership

Write to `docs/postmortems/YYYY-MM-DD-ISSUE-ID.md` or update `INCIDENT-{timestamp}.md`.

### Stage 6: Prevent

If systemic issue:
1. Create prevention issue
2. Optionally `/autopilot` the fix
3. Codify learnings (regression test, agent update, monitoring rule)

## Auto-Detected Issues

Issues labeled `auto-detected` + `bug` are created by the observability pipeline.
Treat as P0 unless evidence suggests otherwise.

## Sentry MCP Integration

When Sentry MCP is configured, use specific tools per triage phase:

| Phase | Tool | Use |
|-------|------|-----|
| Audit | `mcp__sentry__search_issues` | Find unresolved issues by query |
| Audit | `mcp__sentry__search_events` | Search raw events |
| Investigate | `mcp__sentry__get_issue_details` | Full context: stack trace, breadcrumbs, tags |
| Investigate | `mcp__sentry__analyze_issue_with_seer` | AI-powered root cause analysis |
| Investigate | `mcp__sentry__get_trace_details` | Distributed trace for cross-service issues |
| Investigate | `mcp__sentry__search_issue_events` | All events for a specific issue |
| Investigate | `mcp__sentry__get_issue_tag_values` | Filter by environment, browser, user |
| Verify | `mcp__sentry__search_issues` | Confirm issue stopped after fix deploy |
| Performance | `mcp__sentry__get_profile` | CPU/memory profiling for performance issues |
| Manage | `mcp__sentry__update_issue` | Resolve, ignore, or assign issues |

Include Sentry issue link in PR for auto-resolution on deploy.

## Scripts

```bash
# Multi-source orchestrator
~/.claude/skills/triage/scripts/check_all_sources.sh

# Individual checks
~/.claude/skills/triage/scripts/check_sentry.sh
~/.claude/skills/triage/scripts/check_vercel_logs.sh
~/.claude/skills/triage/scripts/check_health_endpoints.sh

# Postmortem generator
~/.claude/skills/triage/scripts/generate_postmortem.sh ISSUE-ID

# GitHub CI
gh run list --branch main --status failure --limit 10
gh run view RUN-ID --log-failed
gh run rerun RUN-ID --failed
```

## Environment Variables

```bash
SENTRY_AUTH_TOKEN   # Required for Sentry
SENTRY_ORG          # Organization slug
SENTRY_PROJECT      # From .sentryclirc or .env.local
VERCEL_TOKEN        # Optional for vercel logs
```

## References

- `references/verify-fix-protocol.md` -- Detailed verification checklist
- `references/postmortem-template.md` -- Blameless postmortem format
- `references/incident-response-workflow.md` -- Full incident lifecycle

## Related

- `/check-production` -- The audit primitive (read-only)
- `/log-production-issues` -- Create GitHub issues from findings
- `/debug` -- Systematic debugging protocol
- `/done` -- Session retrospective and codification
