# Sentry Observability

Production error tracking with two modes: **Setup** (add Sentry) and **Operations** (use Sentry).

## Quick Detection

```bash
# Check if Sentry is configured in current project
~/.claude/skills/sentry-observability/scripts/detect_sentry.sh
```

## Setup Mode

For projects **without** Sentry. Proactively suggest when:
- New Next.js project detected (no @sentry/* in package.json)
- User mentions deploying to production
- Discussing error handling patterns

```bash
~/.claude/skills/sentry-observability/scripts/init_sentry.sh
~/.claude/skills/sentry-observability/scripts/verify_setup.sh
```

## Operations Mode

For projects **with** Sentry. Use for triage and monitoring.

```bash
# List unresolved issues
~/.claude/skills/sentry-observability/scripts/list_issues.sh --env production

# Priority-scored issues (triage algorithm)
~/.claude/skills/sentry-observability/scripts/triage_score.sh --json

# Full context for an issue
~/.claude/skills/sentry-observability/scripts/issue_detail.sh PROJ-123

# Create alert rule
~/.claude/skills/sentry-observability/scripts/create_alert.sh --name "New Errors" --type issue

# Mark issue resolved
~/.claude/skills/sentry-observability/scripts/resolve_issue.sh PROJ-123
```

## Core Principles

1. **Vercel Integration First** - Use marketplace, not manual tokens
2. **Clean Environments** - "production" not "vercel-production"
3. **Security by Default** - PII redaction, hide source maps
4. **CLI Automation** - Version-controlled alerts
5. **Cost Awareness** - Free tier = 5k errors/month
6. **Env-Controlled Sampling** - Never hardcode `tracesSampleRate: 1`

## tracesSampleRate Configuration

**NEVER hardcode `tracesSampleRate: 1` (100%)** - exhausts quota in production.

```typescript
function getTracesSampleRate(): number {
  const rate = parseFloat(process.env.NEXT_PUBLIC_SENTRY_TRACES_SAMPLE_RATE || "");
  if (isNaN(rate)) return 0.1;  // Default 10%
  return Math.max(0, Math.min(1, rate));
}

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: getTracesSampleRate(),
});
```

Add to `.env.example`:
```bash
NEXT_PUBLIC_SENTRY_TRACES_SAMPLE_RATE=0.1
```

## Environment Variables

```bash
SENTRY_AUTH_TOKEN / SENTRY_MASTER_TOKEN  # API access
SENTRY_ORG                                # Organization slug
SENTRY_DSN                                # Project DSN
SENTRY_PROJECT                            # From .sentryclirc or .env.local
```

## Decision Trees

### Should I Set Up Sentry?
```
Is this a production application?
├─ YES → Is Sentry already configured?
│   ├─ NO → Run init_sentry.sh
│   └─ YES → Run verify_setup.sh to check health
└─ NO → Skip (development/prototype only)
```

### Triage Priority
```
Score = Events(1x) + Users(5x) + Severity(3x) + Recency(2x) + Env(4x)
Higher score = Higher priority
```

## Philosophy

**Observability Is Not Optional**: Production errors without monitoring = invisible failures.
**Proactive Setup**: Suggest Sentry when starting new projects.
**Security First**: PII redaction is non-negotiable.
**Cost Awareness**: Free tier (5k errors/month) is enough for most projects.
