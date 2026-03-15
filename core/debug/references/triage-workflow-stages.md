# Triage Workflow Stages

## Overview

```
+-----------------------------------------------------------------+
|                      /triage workflow                             |
+-----------------------------------------------------------------+
|                                                                   |
|   +----------+    +-------------+    +------+    +----------+    |
|   |  Status  |--->| Investigate |--->|  Fix |--->|Postmortem|    |
|   +----------+    +-------------+    +------+    +----------+    |
|        |                                                          |
|        | (if clean)                                               |
|        v                                                          |
|   "All systems nominal"                                           |
|                                                                   |
+-----------------------------------------------------------------+
```

## Stage 1: Status

**Command:** `/triage` or `/triage status`

**Purpose:** Quick health check across all observability sources.

**Checks performed (in parallel):**

| Source | Script | What it checks |
|--------|--------|----------------|
| Sentry | `check_sentry.sh` | Unresolved issues, priority scores |
| Vercel | `check_vercel_logs.sh` | Recent errors in log stream |
| Health | `check_health_endpoints.sh` | `/api/health` response time |

**Output states:**

| State | Meaning | Action |
|-------|---------|--------|
| All green | No issues detected | None required |
| Yellow warnings | Minor issues | Review when time permits |
| Red critical | Urgent issues | Investigate immediately |

**Scoring algorithm (from Sentry):**
```
Score = Events(1x) + Users(5x) + Severity(3x) + Recency(2x) + Env(4x)
```

Higher score = higher priority.

## Stage 2: Investigate

**Command:** `/triage investigate ISSUE-ID`

**Purpose:** Deep dive into specific issue. Gather context for fix.

**Actions performed:**

1. **Fetch issue context**
   - Full error details from Sentry
   - Stack trace with source locations
   - Breadcrumbs (user actions before error)
   - Affected users and environments

2. **Create fix branch**
   ```bash
   git checkout -b fix/ISSUE-ID-short-description
   ```

3. **Load affected files**
   - Parse stack trace for file paths
   - Load files into context
   - Check git blame for recent changes

4. **Form hypothesis**
   - Identify likely root cause
   - Check for related issues
   - Review recent deployments

**Output:** Investigation summary with:
- Root cause hypothesis
- Affected code locations
- Suggested fix approach
- Related context (recent changes, similar issues)

## Stage 3: Fix

**Command:** `/triage fix`

**Prerequisites:**
- On a `fix/` branch
- Changes committed or staged
- Tests passing (ideally)

**Actions performed:**

1. **Verify fix quality**
   ```bash
   pnpm typecheck && pnpm lint && pnpm test
   ```

2. **Create PR**
   - Standard PR format
   - Links Sentry issue
   - Includes test plan

**PR template:**
```markdown
## Summary
[Brief description of the fix]

## Sentry Issue
- **ID:** ISSUE-ID
- **Title:** Error title
- **Users affected:** N
- **First seen:** DATE

## Root Cause
[Technical explanation]

## Changes
- [Change 1]
- [Change 2]

## Test Plan
- [ ] Manual test case 1
- [ ] Manual test case 2
- [ ] Automated tests pass
```

## Stage 4: Postmortem

**Command:** `/triage postmortem ISSUE-ID`

**Prerequisites:**
- Fix PR merged
- Deployed to production
- Error rate back to normal

**Actions performed:**

1. **Verify resolution**
   - Check Sentry for new occurrences
   - Confirm error rate dropped
   - Health endpoints responding

2. **Generate postmortem document**
   - Uses template from `templates/postmortem.md`
   - Pre-fills Sentry data (title, dates, user count)
   - Creates `docs/postmortems/YYYY-MM-DD-ISSUE-ID.md`

3. **Resolve Sentry issue**
   ```bash
   ~/.claude/skills/sentry-observability/scripts/resolve_issue.sh ISSUE-ID
   ```

4. **Update documentation**
   - Add to CLAUDE.md if pattern worth capturing
   - Update relevant docs/ADRs if needed

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SENTRY_AUTH_TOKEN` | Yes* | - | Sentry API token |
| `SENTRY_MASTER_TOKEN` | Yes* | - | Alternative to AUTH_TOKEN |
| `SENTRY_ORG` | Yes | - | Organization slug |
| `SENTRY_PROJECT` | No | auto-detect | Project slug |
| `VERCEL_TOKEN` | No | - | For `vercel logs` access |
| `HEALTH_ENDPOINTS` | No | auto-detect | Comma-separated URLs |

*One of SENTRY_AUTH_TOKEN or SENTRY_MASTER_TOKEN required.

## Troubleshooting

### "No Sentry auth token"

Set `SENTRY_AUTH_TOKEN` in your environment:
```bash
# In ~/.secrets or ~/.zshrc
export SENTRY_AUTH_TOKEN="sntrys_..."
```

Or use `sentry-cli login` to authenticate.

### "Could not fetch Vercel logs"

1. Ensure you're in a Vercel project: `vercel link`
2. Set `VERCEL_TOKEN` for non-interactive access

### "No health endpoints configured"

Set `NEXT_PUBLIC_URL` in `.env.local` or:
```bash
export HEALTH_ENDPOINTS="https://myapp.com/api/health"
```

### Parallel check timeout

Increase timeout with:
```bash
export TRIAGE_HEALTH_TIMEOUT=30
```
