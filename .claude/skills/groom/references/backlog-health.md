# Backlog Health Dashboard

Quick assessment of backlog state. Stats, staleness, priority distribution, readiness scores.

## Process

### 1. Fetch Issues

```bash
gh issue list --state open --limit 200 --json number,title,labels,body,createdAt,updatedAt,milestone,assignees
```

### 2. Compute Stats

| Metric | How |
|--------|-----|
| Total open | Count of open issues |
| By priority | Count per p0/p1/p2/p3/unlabeled |
| By horizon | Count per now/next/later/blocked/unlabeled |
| By type | Count per bug/feature/task/refactor/research/epic |
| By domain | Count per domain/* label |
| Assigned vs unassigned | Count with/without assignees |
| With milestone vs without | Count with/without milestone |

### 3. Staleness Report

Flag issues by staleness:
- **Stale** (>90 days since last update, no `blocked` label)
- **Aging** (60-90 days since last update)
- **Orphaned** (no labels beyond source/*)
- **Unlabeled priority** (missing p0-p3)

```bash
# Issues not updated in 90+ days
gh issue list --state open --json number,title,updatedAt,labels | \
  jq '[.[] | select((.updatedAt | fromdateiso8601) < (now - 7776000))]'
```

### 4. Readiness Distribution

Run `/issue lint --all` scoring (lightweight — just parse issue bodies,
don't spawn sub-agents). Report distribution:

```
Readiness Distribution:
  90-100 (Excellent):  4 issues  ████
  70-89  (Good):       8 issues  ████████
  50-69  (Needs work): 3 issues  ███
  0-49   (Incomplete): 5 issues  █████
```

### 5. Label Hygiene

Check for:
- Legacy labels that need migration
- Issues with multiple priority labels
- Issues with no type label
- Issues missing horizon label

### 6. BACKLOG.md Status

```bash
if [ -f .groom/BACKLOG.md ]; then
  echo "BACKLOG.md exists"
  grep -c '^\- \*\*' .groom/BACKLOG.md 2>/dev/null || echo "0 entries"
  head -3 .groom/BACKLOG.md | grep -o 'Last groomed: .*' || echo "Last groomed: unknown"
else
  echo "No .groom/BACKLOG.md (will create on first groom session)"
fi
```

### 7. Cap Enforcement

```bash
OPEN=$(gh issue list --state open --json number --jq 'length')
if [ "$OPEN" -gt 30 ]; then
  echo "OVER CAP: $OPEN open issues (cap: 30). Reduction required."
elif [ "$OPEN" -gt 20 ]; then
  echo "AT CAP: $OPEN open issues (target: 20-30). Monitor."
else
  echo "UNDER CAP: $OPEN open issues. Room for $(( 20 - OPEN )) more."
fi
```

## Output

```
BACKLOG HEALTH: {repo}
======================

Overview:
  Total open: 20 (cap: 20-30) ✓
  Ready for execution (score >= 70): 12 (60%)
  Needs enrichment (score 50-69): 3 (15%)
  Incomplete (score < 50): 5 (25%)

Priority Distribution:
  P0 (Critical):   1  █
  P1 (Essential):  5  █████
  P2 (Important):  8  ████████
  P3 (Nice to Have): 4  ████
  Unlabeled:       2  ██

Horizon Distribution:
  now:     3  ███
  next:    7  ███████
  later:   8  ████████
  blocked: 1  █
  None:    1  █

Staleness:
  Stale (>90d): #12, #15, #18
  Aging (60-90d): #22
  Orphaned (no labels): #31

Label Issues:
  Missing priority: #31, #33
  Missing type: #31
  Legacy labels: #15 (priority/p0 -> p0)

BACKLOG.md:
  Status: exists / missing
  High Potential: N ideas
  Someday/Maybe: N ideas
  Last groomed: {date}

Recommendations:
  1. Close or update 3 stale issues
  2. Enrich 5 incomplete issues (/issue lint --all --fix)
  3. Migrate 1 legacy label
  4. Add priority to 2 unlabeled issues
  5. Demote N issues to BACKLOG.md (over cap / below grooming threshold)
```
