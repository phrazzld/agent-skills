# AI Agent Integration for Observability

## The Goal

Errors should trigger automated analysis and fixes. Not "alert me so I can debug" but "detect, analyze, propose fix, maybe even auto-PR."

## Integration Options

### Option A: Sentry MCP Server (Direct Claude Integration)

**Best for:** Interactive debugging with Claude

The Sentry MCP server gives Claude direct access to your error data.

**Setup:**
```json
// ~/.config/claude/claude_desktop_config.json (or similar)
{
  "mcpServers": {
    "sentry": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sentry"],
      "env": {
        "SENTRY_AUTH_TOKEN": "your-token",
        "SENTRY_ORG": "your-org"
      }
    }
  }
}
```

**Usage:**
```
User: "Check for recent errors in production"
Claude: [queries Sentry via MCP] "Found 3 unresolved issues..."

User: "Analyze the authentication error"
Claude: [fetches full context] "The error occurs in auth.ts:47..."

User: "Fix it"
Claude: [proposes code change based on error context]
```

### Option B: Webhook → GitHub Action → Agent

**Best for:** Automated triage without human initiation

New errors trigger a GitHub Action that spawns an analysis agent.

**Sentry webhook setup:**
1. Sentry Dashboard → Settings → Integrations → Internal Integrations
2. Create new integration
3. Add webhook URL: `https://api.github.com/repos/OWNER/REPO/dispatches`
4. Subscribe to: `issue` events
5. Add repository dispatch token

**GitHub Action:**
```yaml
# .github/workflows/sentry-auto-triage.yml
name: Auto-Triage Sentry Errors

on:
  repository_dispatch:
    types: [sentry-issue]

jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Get issue details
        id: sentry
        run: |
          ISSUE_ID="${{ github.event.client_payload.data.issue.id }}"
          # Fetch full issue details via Sentry API
          curl -H "Authorization: Bearer ${{ secrets.SENTRY_AUTH_TOKEN }}" \
            "https://sentry.io/api/0/issues/$ISSUE_ID/" > issue.json

      - name: Analyze with Claude
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # Use Claude API or Claude CLI to analyze
          cat issue.json | claude --print "Analyze this Sentry error. \
            Identify root cause, affected code, and propose a fix. \
            If confidence is high, create a draft PR."

      - name: Create issue/PR if needed
        run: |
          # Based on Claude's analysis, create GitHub issue or PR
```

### Option C: Sentry's Native AI (Seer)

**Best for:** Automated root cause analysis within Sentry

Sentry is building "Seer" - AI-powered issue analysis. You can subscribe to Seer webhooks:

**Seer webhook events:**
- `seer.root_cause_started` - Analysis began
- `seer.root_cause_completed` - Root cause identified
- `seer.fix_started` - Fix generation started
- `seer.fix_completed` - Fix ready
- `seer.pr_created` - PR created automatically

**Setup:**
1. Enable Seer in Sentry organization settings
2. Create internal integration with Seer webhook subscription
3. Point webhook to your handler

**Handler example:**
```typescript
// app/api/webhooks/sentry-seer/route.ts
export async function POST(req: Request) {
  const event = await req.json();

  switch (event.action) {
    case 'seer.fix_completed':
      // Sentry found a fix - review and maybe auto-merge
      const fix = event.data.fix;
      await notifySlack(`Sentry Seer proposed fix for ${event.data.issue.title}`);
      break;

    case 'seer.pr_created':
      // Sentry created a PR - add to review queue
      await addToReviewQueue(event.data.pull_request.url);
      break;
  }

  return Response.json({ ok: true });
}
```

### Option D: CLI Scripts (Manual but Scriptable)

**Best for:** On-demand triage, cron jobs, custom workflows

Existing scripts in `sentry-observability`:

```bash
# Daily triage cron
0 9 * * * ~/.claude/skills/sentry-observability/scripts/triage_score.sh --json | \
  jq '.[] | select(.score > 50)' | \
  claude --print "Prioritize these errors for today's work"

# Post-deploy verification
~/.claude/skills/sentry-observability/scripts/list_issues.sh --since "1 hour ago" | \
  claude --print "Any new errors since deploy? Should we rollback?"
```

## Recommended Approach

**Start with Option D (CLI scripts).** It's already built, requires no setup, and you control when it runs.

**Add Option A (MCP) for interactive sessions.** When you're actively debugging, having Claude query Sentry directly is powerful.

**Consider Option B/C for scale.** If you're getting enough errors that manual triage is a burden, automate it. But for indie dev, this is probably overkill initially.

## The Feedback Loop

The goal is a closed loop:

```
1. Error occurs
2. Sentry captures with full context
3. Agent analyzes (via MCP, webhook, or CLI)
4. Agent proposes fix
5. Fix deployed
6. Agent verifies error rate decreased
7. Issue marked resolved
```

Step 6 is key - the agent should be able to verify its fix worked by checking error rates post-deploy.

```bash
# Verify fix worked
~/.claude/skills/sentry-observability/scripts/list_issues.sh --issue PROJ-123 | \
  jq '.stats.24h' # Should show decreasing trend
```

## Security Considerations

- **Scope tokens narrowly.** Sentry tokens should have minimal permissions (read issues, maybe write to resolve).
- **Don't expose in logs.** The agent shouldn't log full error payloads (may contain PII).
- **Review before merge.** Even if Seer creates PRs, human review before merge.
- **Rate limit webhooks.** Don't spawn an agent for every error - batch or debounce.
