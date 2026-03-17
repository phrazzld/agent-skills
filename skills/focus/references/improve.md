# Focus Improve

Synthesize accumulated observations into discrete spellbook improvements.

## Observation Format

Observations are stored in `.spellbook/observations.ndjson` — one JSON line
per observation, appended by `/calibrate` or manually.

```json
{
  "timestamp": "2026-03-16T22:00:00Z",
  "primitive": "phrazzld/spellbook@autopilot",
  "type": "friction",
  "summary": "Autopilot didn't handle draft PRs",
  "context": "Full context of what happened...",
  "confidence": 0.6
}
```

## Process

### 1. Collect Observations

Read `.spellbook/observations.ndjson` from the current project.

If running from the spellbook repo itself, also scan for observation files
in known project directories (check git config for recent repos, or ask
the user which projects to include).

### 2. Cluster by Primitive

Group observations by the `primitive` FQN. For each primitive with
2+ observations, there's likely a real pattern worth addressing.

Single observations with high confidence (>= 0.8) are also candidates.

### 3. Synthesize Improvements

For each cluster, analyze the observations and produce:

- **What's wrong**: Common thread across observations
- **Proposed fix**: Specific edit to the canonical skill/agent
- **Evidence**: The observations that support this
- **Confidence**: How certain we are this is the right fix

### 4. Choose Action

For each synthesized improvement, offer three actions:

| Confidence | Action |
|-----------|--------|
| >= 0.8 | **Direct PR**: Clone spellbook, edit skill, open PR |
| 0.5–0.8 | **GitHub Issue**: Create an issue on spellbook with evidence |
| < 0.5 | **Keep Logging**: Need more observations before acting |

### 5. Execute

**Direct PR flow:**
```bash
tmp=$(mktemp -d)
git clone --depth 1 https://github.com/phrazzld/spellbook.git "$tmp"
cd "$tmp"
git checkout -b fix/skill-name-improvement
# Apply the synthesized edit
git commit -m "fix(skill-name): description from synthesis"
gh pr create --title "fix(skill-name): ..." --body "..."
```

**GitHub Issue flow:**
```bash
gh issue create --repo phrazzld/spellbook \
  --title "Improve skill-name: summary" \
  --body "## Observations\n\n[evidence]\n\n## Proposed Fix\n\n[fix]"
```

### 6. Archive

After acting on observations, move processed entries to
`.spellbook/observations.archive.ndjson` so they don't get
re-processed. Add a `resolved` field with the action taken.

## Multi-Project Synthesis

When running from the spellbook repo, you can pull observations from
multiple projects for a global view:

```bash
# Find all observation files across projects
find ~/Development -name "observations.ndjson" -path "*/.spellbook/*" 2>/dev/null
```

This gives the highest signal — the same primitive causing friction
across different projects is a strong signal for improvement.
