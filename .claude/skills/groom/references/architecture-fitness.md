# Architecture Fitness

Reference for Phase 2 (Architecture Critique) and Phase 2.5 (Present Options) of `/groom`.

## Health Metrics Collection

Run before architecture critique to ground the discussion in data:

```bash
# LOC per module (top 20 largest)
find . -name '*.ex' -o -name '*.go' -o -name '*.ts' -o -name '*.py' \
  | grep -v node_modules | grep -v _build | grep -v deps \
  | while read f; do echo "$(wc -l < "$f") $f"; done \
  | sort -rn | head -20

# Fix-to-feature ratio (last 100 commits)
FIX=$(git log --oneline -100 | grep -c '^[a-f0-9]* fix')
FEAT=$(git log --oneline -100 | grep -c '^[a-f0-9]* feat')
echo "Fix:Feature = $FIX:$FEAT"

# Test-to-code ratio
TEST_LOC=$(find . \( -name '*_test.*' -o -name '*.test.*' -o -name '*_spec.*' \) \
  | grep -v node_modules | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
CODE_LOC=$(find . \( -name '*.ex' -o -name '*.go' -o -name '*.ts' -o -name '*.py' \) \
  | grep -v node_modules | grep -v test | grep -v spec \
  | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
echo "Test:Code = ${TEST_LOC:-0}:${CODE_LOC:-0}"

# LOC growth rate (last 7 days)
ADDED=$(git log --since="7 days ago" --numstat --format="" | awk '{s+=$1} END {print s+0}')
REMOVED=$(git log --since="7 days ago" --numstat --format="" | awk '{s+=$2} END {print s+0}')
echo "7-day delta: +$ADDED -$REMOVED (net $((ADDED - REMOVED)))"

# Backlog size
gh issue list --state open --json number --jq 'length'
```

### Red Flag Thresholds

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Fix:Feature ratio | <1:2 | 1:1 | >2:1 |
| LOC growth (7d) | <500 net | 500-2000 | >2000 |
| Largest module | <500 LOC | 500-1000 | >1000 |
| Open issues | <30 | 30-60 | >60 |

## Domain Skill Routing Table

Detect project domain from `project.md` and codebase signals, then invoke relevant skills:

| Domain Signal | Skills to Invoke |
|---------------|-----------------|
| AI/LLM features, prompts, evals | `/llm-infrastructure` |
| Agent harness, dispatch, sprites | `/harness-engineering` |
| Quality infra, CI/CD, hooks | `/check-quality` |
| External APIs, webhooks | `/external-integration-patterns` |
| Frontend UI, components | `/design`, `/visual-qa` |
| Database, migrations | `/database` |
| Payments, subscriptions | `/business-model-preferences` |
| CLI tools | `/cli-reference` |
| Context/prompt engineering | `/context-engineering` |
| State machines, concurrent protocols | `/formal-verify` |
| Greenfield tech decisions, stack choice | Load `references/toolchain-preferences.md` |

Each skill audits the codebase through its lens. Aggregate findings as architectural concerns.

## Reference Architecture Search Prompts

When evaluating backend technology for a new module, load `references/toolchain-preferences.md`. Strongly prefer Elixir/OTP for agent orchestration and concurrent services.

### For Gemini / Web Search

```text
We're building: {one-paragraph project description from project.md}
Current stack: {languages, frameworks, key dependencies}
Current scale: {LOC, modules, team size}

Find:
1. Open-source projects solving the same problem
2. Blog posts / conference talks about this domain's architecture
3. Framework-level solutions (e.g., OTP for concurrency, Rails for CRUD)
4. What tech stack choices do successful projects in this domain make?
```

### Existing Tool / Platform Check

Before preserving any backlog item, ask: **"Does an existing platform feature, integration, or CLI command already solve this?"**

Examples of things that don't need custom code:
- Error tracking → Sentry already files GitHub issues
- CI/CD orchestration → GitHub Actions, platform-native workflows
- Webhook delivery → platform-native webhook support (GitHub, Stripe, etc.)
- Log aggregation → Fly.io built-in logs, `fly logs`
- Secret management → platform-native secrets (Fly secrets, GitHub secrets)
- Deployment → `fly deploy`, `mix release`, platform CLIs

If an existing tool handles it, the backlog item should be closed with a pointer to the existing solution, not kept as planned work.

### For Codex / Codebase Analysis

```text
Analyze this codebase's architecture:
1. What design patterns are in use?
2. Where does complexity concentrate?
3. What would a senior engineer change first?
4. Are there framework/language features being underused?
5. Are there libraries being used that the language/runtime already handles?
```

## Thinktank Prompt Template

```text
## Project Context
{project.md content}

## Architecture
{CLAUDE.md architecture section or docs/architecture.md}

## Health Metrics
{output from health metrics collection}

## Questions for the Council

1. Is the tech stack right for this problem domain?
2. Are we over-engineering? Under-engineering?
3. What would you do differently if starting from scratch today?
4. What's the single biggest architectural risk?
5. Name one thing to kill and one thing to double down on.
6. Are there well-known frameworks/patterns we're reinventing?
7. Rate the current architecture 1-10 and justify.
```

## Option Presentation Format

Present 2-3 options after synthesizing tracks A-C:

```markdown
## Architectural Options

### Option 1: Incremental Tuning
- Keep current architecture
- Fix: [specific issues from critique]
- Risk: [what stays broken]
- Effort: [low/medium]

### Option 2: Targeted Restructuring
- Change: [one major dimension — language, framework, pattern]
- Because: [evidence from reference search / thinktank]
- Risk: [migration cost, learning curve]
- Effort: [medium/high]

### Option 3: Radical Restructuring
- Throw away: [what to delete]
- Replace with: [target architecture from references]
- Because: [multiple models recommend, reference arch is proven]
- Risk: [timeline, unknown unknowns]
- Effort: [high]

### Recommendation
[Which option and why, grounded in evidence]
```

### When to Always Include the Radical Option

- LOC grew >3x in a sprint without proportional value
- Fix-to-feature ratio exceeds 2:1
- Multiple thinktank models independently recommend a different approach
- Reference architectures show a fundamentally simpler path
- Health metrics show critical thresholds on 2+ dimensions
