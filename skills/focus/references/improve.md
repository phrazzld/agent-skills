# Focus Improve

Synthesize accumulated observations into discrete spellbook improvements.

## Observation Format

Observations are stored in `.spellbook/observations.ndjson` — one JSON line
per observation, appended by `/focus`, `/calibrate`, or manually.

Use the `/focus` helper to keep selector telemetry compact and consistent:

```bash
python3 ${SKILL_DIR}/scripts/observation_log.py validate .spellbook/observations.ndjson
```

Shared envelope:

- `timestamp` — UTC write time
- `type` — event family
- `summary` — one-sentence headline
- `context` — compact evidence, not raw transcript
- `confidence` — `0.0` to `1.0`

Supported `/focus` event families:

| Type | Required fields | Meaning |
|------|-----------------|---------|
| `selected` | `primitive`, `wishlist_item`, `run_kind` | Candidate chosen for active subset |
| `excluded` | `primitive`, `wishlist_item`, `run_kind` | Plausible candidate rejected with rationale |
| `gap` | `wishlist_item`, `run_kind`, `gap_scope` | Need with no strong primitive match |
| `installed` | `primitive`, `run_kind` | Sync added a managed primitive |
| `updated` | `primitive`, `run_kind` | Sync refreshed a managed primitive |
| `removed` | `primitive`, `run_kind` | Sync removed a managed primitive |
| `undertriggered` | `primitive`, `run_kind` | Later review found a selected primitive is rarely used |

Examples:

```json
{"timestamp":"2026-03-20T15:00:00Z","type":"selected","summary":"Selected codified-context-architecture for repo tuning.","context":"High semantic match and low overlap with the other candidates.","confidence":0.82,"primitive":"phrazzld/spellbook@codified-context-architecture","wishlist_item":"repo tuning","run_kind":"init"}
{"timestamp":"2026-03-20T15:00:01Z","type":"gap","summary":"No skill matched factory-specific routing policy.","context":"Catalog search found no strong candidate for the repo-specific conventions.","confidence":0.71,"wishlist_item":"factory-specific routing policy","run_kind":"init","gap_scope":"spellbook"}
{"timestamp":"2026-03-20T15:05:00Z","type":"undertriggered","summary":"React performance skill was installed but never selected in later sessions.","context":"Three review passes and two build sessions completed without routing to the skill.","confidence":0.64,"primitive":"phrazzld/spellbook@react-performance","run_kind":"improve"}
```

## Process

### 1. Collect Observations

Read `.spellbook/observations.ndjson` from the current project.

If `.spellbook/init-report.json` exists, read it before clustering anything
else. Treat it as the baseline record of:

- what `/focus init` saw in the repo
- which primitives were selected or rejected
- which gaps were already known
- what confidence and open questions existed at selection time

If running from the spellbook repo itself, also scan for observation files
in known project directories (check git config for recent repos, or ask
the user which projects to include).

### 2. Cluster by Primitive or Gap Key

Group observations by the strongest stable key:

- If `primitive` exists, cluster by primitive FQN
- For `gap` events without a primitive, cluster by `(wishlist_item, gap_scope)`
- For selection decisions, use `wishlist_item` to compare winners, losers, and persistent misses

For each cluster with 2+ observations, there's likely a real pattern worth addressing.

Single observations with high confidence (>= 0.8) are also candidates.

### 3. Synthesize Improvements

For each cluster, analyze the observations and produce:

- **What's wrong**: Common thread across observations
- **Proposed fix**: Specific edit to the canonical skill/agent
- **Evidence**: The observations and init-report entries that support this
- **Confidence**: How certain we are this is the right fix

If the init report already listed a gap or weak match for the same area,
reuse that language instead of reconstructing the rationale from scratch.

When a cluster mixes `selected`, `excluded`, and `gap` events for the same
wishlist item, prefer the longitudinal story over any single line:

- repeated `gap` + no later `selected` => likely missing skill
- repeated `excluded` in favor of the same winner => maybe catalog duplication
- repeated `undertriggered` on the same primitive => selection quality or trigger-quality issue

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
