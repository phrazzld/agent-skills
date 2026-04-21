# /harness audit (in spellbook)

Assess skill health across spellbook's catalog: what's hot, what's
cold, what's dead weight paying description tax for nothing.

## Data source

`~/.claude/skill-invocations.jsonl`. Each line:

```
{"ts": "ISO8601", "skill": "name", "args": "...",
 "session_id": "...", "cwd": "...", "project": "..."}
```

Populated by the PostToolUse telemetry hook in
`harnesses/claude/hooks/`. If the file doesn't exist or is empty:

> No invocation data found. Skill invocations are tracked via the
> PostToolUse hook in `harnesses/claude/hooks/`. Once data accrues,
> re-run `/harness audit`.

Codex and Pi invocation telemetry is not currently captured in this
file — if you need cross-harness counts, instrument separately or
accept Claude-only data as a proxy.

## Flags

- `--since <duration>` — e.g. `30d`, `7d`, `90d`. Default: all data.
- `--skill <name>` — deep-dive a single skill instead of full report.

## Full report (default)

### 1. Frequency table

| Skill | Invocations | Last Used | Projects |
|-------|-------------|-----------|----------|

Sort descending by invocation count. Compare against the full catalog
(`ls skills/`) — any skill not in the table and with zero rows in the
JSONL is Dead.

### 2. Health categories

| Category | Criteria | Action |
|----------|----------|--------|
| **Hot** | >10 invocations in window | Keep; consider investing (deeper `references/`, sub-modes) |
| **Warm** | 3-10 | Keep; monitor |
| **Cold** | 1-2 | Evaluate: niche or dead? |
| **Dead** | 0 | Deprecation candidate |

### 3. Consolidation candidates

Flag skills that:

- Always fire in sequence within the same session (A→B → merge into A
  or make B a composer).
- Share >50% of trigger phrases with another skill (description
  overlap — `/harness eval` both on the same prompt to see which wins).
- Sit in complementary domains that could be one skill without
  exceeding 3 workflows.

### 4. Recommendations

For each skill, emit exactly one:

- **keep** — earning its tax.
- **invest** — hot; would benefit from deeper references or a mode.
- **deprecate** — dead or cold with no defensible niche.
- **merge <target>** — consolidation candidate; name the target.
- **split** — exceeds the mode-bloat gate; extract to `references/mode-*.md`.
- **promote** — used across >2 projects (via the `project:` field in
  the JSONL); consider making it more prominent in `index.yaml`.

### 5. Description-tax report

Count `skills/*/SKILL.md`. Estimate ~100 tokens per `description:`,
always loaded. Report total. Flag if >2,500 tokens.

Current steady state: 26 skills × ~100 = ~2.6k tokens per
conversation, every conversation, every repo. New skills must justify
this cost.

## Deep-dive (`--skill <name>`)

For one skill:

- Invocation timeline (count per week/month).
- Project breakdown: which `project:` values dominate.
- Session co-occurrence: which other skills fire in the same
  `session_id` — the composition pattern.
- Specific recommendations with rationale (not generic "keep/deprecate").

## Output format

Structured markdown. Tables and bullets only. No prose filler. End
with **TLDR**: 3-5 bullet summary of the most actionable findings.

## Follow-on

Audit produces candidates; `/harness eval` proves whether a Cold
skill earns its description tax. A Dead skill is a deprecation
candidate even without eval — if nobody invokes it, the eval is moot.

When deprecating:

1. `git rm -r skills/<name>/`.
2. `./scripts/generate-index.sh` (or pre-commit).
3. `dagger call check --source=.` — verify no lint references to the
   removed skill (routing tables in sibling skills, hook scripts,
   `harnesses/pi/settings.json:skills[]` globs).
4. Commit as `refactor: drop unused skill /<name>`.

When promoting a project-local skill to global:

1. Move the skill from the consumer repo's `.agents/skills/<name>/`
   to spellbook's `skills/<name>/`.
2. Edit `bootstrap.sh`'s `discover_local`/`discover_remote`
   `GLOBAL_SKILLS` array ONLY if it should be one of the minimal
   globally-symlinked skills (currently `tailor`, `seed`). Otherwise
   leave it out — per-repo via `/tailor` is the default.
3. Run `dagger call check --source=.`.
