---
name: standup
description: |
  Generate a daily standup report from the last 24 hours of GitHub activity
  across all repos and orgs. Pulls PRs authored/reviewed, issues engaged,
  commits pushed, and open PRs needing attention. Synthesizes into
  Yesterday / Today / Blockers format.
  Use when: writing standup, daily update, what did I do yesterday,
  status report, daily sync, team update.
  Keywords: standup, daily, status, yesterday, update, sync, report.
allowed-tools: Bash, Read
---

# Standup

Generate a concise daily standup from GitHub activity across all repos and orgs.

## Workflow

### 1. Gather Activity

Run the gather script to pull last 24h of GitHub activity:

```bash
bash "$(dirname "$0")/scripts/gather.sh"
```

The script uses `gh` CLI to collect:
- PRs authored (with state: open/merged)
- PRs reviewed (others' PRs only)
- Issues engaged (commented on)
- Commits pushed (via events API)
- Open PRs that may need attention

### 2. Synthesize Standup

From the raw data, produce a standup in this format:

```
## Yesterday
- [grouped by theme/repo, not raw PR list]
- Focus on outcomes and impact, not mechanics

## Today
- Infer from open PRs, open issues, and in-progress work
- Mention PRs awaiting review or CI

## Blockers
- PRs with no reviews, stale open issues
- Or "None" if clear
```

### 3. Output Rules

- Group related PRs into narrative lines (e.g. "Hardened conductor lifecycle across 3 PRs")
- Lead with the *what* and *why*, not PR numbers
- Keep it to 5-8 bullets for Yesterday, 3-5 for Today
- Include PR links inline for reference but don't let them dominate
- If activity spans many repos, organize by project/theme not by repo
- Mention review work separately — "Reviewed X PRs on [project]"
