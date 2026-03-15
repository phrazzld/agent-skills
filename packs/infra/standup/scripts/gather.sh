#!/usr/bin/env bash
# Gather last 24h GitHub activity for standup generation.
# Outputs JSON sections that the LLM synthesizes into a standup.
set -euo pipefail

SINCE="${1:-$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)}"
USER=$(gh api /user --jq '.login')

echo "=== STANDUP DATA (since $SINCE for @$USER) ==="

# --- PRs authored ---
echo ""
echo "## PRs Authored"
gh search prs --author="@me" --created=">=$SINCE" \
  --json repository,title,state,url --limit 50 \
  --jq '.[] | "- [\(.state)] \(.repository.nameWithOwner): \(.title) (\(.url))"' 2>/dev/null || echo "(none)"

# --- PRs reviewed (exclude self-authored) ---
echo ""
echo "## PRs Reviewed (others' PRs)"
gh search prs --reviewed-by="@me" --updated=">=$SINCE" \
  --json repository,title,state,url,author --limit 50 \
  --jq "[.[] | select(.author.login != \"$USER\")] | .[] | \"- [\(.state)] \(.repository.nameWithOwner): \(.title) (\(.url))\"" 2>/dev/null || echo "(none)"

# --- Issues commented on ---
echo ""
echo "## Issues Engaged"
gh search issues --commenter="@me" --updated=">=$SINCE" \
  --json repository,title,state,url --limit 30 \
  --jq '.[] | "- [\(.state)] \(.repository.nameWithOwner): \(.title) (\(.url))"' 2>/dev/null || echo "(none)"

# --- Push events (commits) from events API ---
echo ""
echo "## Commits Pushed"
gh api "/users/$USER/events?per_page=100" \
  --jq "[.[] | select(.type == \"PushEvent\" and .created_at >= \"$SINCE\") | {repo: .repo.name, commits: [.payload.commits[] | .message | split(\"\n\")[0]]}] | .[] | \"- \(.repo): \" + (.commits | join(\"; \"))" 2>/dev/null || echo "(none)"

# --- Open PRs needing attention (authored, open, no recent review) ---
echo ""
echo "## Open PRs (may need attention)"
gh search prs --author="@me" --state=open \
  --json repository,title,url,updatedAt --limit 20 \
  --jq '.[] | "- \(.repository.nameWithOwner): \(.title) (\(.url))"' 2>/dev/null || echo "(none)"

echo ""
echo "=== END STANDUP DATA ==="
