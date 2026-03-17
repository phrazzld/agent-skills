# Tidy Procedure

Automated backlog cleanup. Non-interactive.

## What This Does

1. Lint all open issues
2. Enrich issues scoring < 70
3. Deduplicate similar issues
4. Close stale issues (>90 days untouched, not blocked)
5. Migrate legacy labels
6. Report what changed

## Process

### 1. Lint All Issues

Run `/issue lint --all` to score every open issue.

### 2. Enrich Failures

For each issue scoring < 70:
- Run `/issue enrich` to fill gaps
- Re-lint to confirm improvement
- Skip issues scoring < 30 (need human input, not enrichment)

### 3. Deduplicate

Compare issue titles and bodies for semantic similarity:
- Same domain label + similar problem statement = potential duplicate
- Present duplicates for confirmation before closing
- Close the less-detailed duplicate with "Duplicate of #N"

### 4. Close Stale

```bash
# Issues untouched for 90+ days without blocked label
gh issue list --state open --json number,title,updatedAt,labels | \
  jq '[.[] | select(
    ((.updatedAt | fromdateiso8601) < (now - 7776000)) and
    (.labels | map(.name) | index("blocked") | not)
  )]'
```

For each stale issue:
```bash
gh issue close N --comment "Closing as stale (>90 days without update). Reopen if still relevant."
```

### 5. Migrate Legacy Labels

```bash
# Find issues with legacy labels
gh issue list --state open --label "priority/p0" --json number
gh issue list --state open --label "P0" --json number
gh issue list --state open --label "type/bug" --json number
```

Migrate each:
```bash
gh issue edit N --remove-label "priority/p0" --add-label "p0"
```

### 6. Report

```
TIDY REPORT
===========

Issues linted: 20
Issues enriched: 3 (#35: 45->82, #38: 55->78, #41: 62->75)
Duplicates closed: 1 (#39 -> duplicate of #42)
Stale closed: 2 (#12, #15)
Labels migrated: 1 (#18: priority/p0 -> p0)

Backlog health: 60% -> 78% ready for execution
```
