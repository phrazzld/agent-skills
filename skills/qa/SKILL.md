---
name: qa
description: |
  Browser-based QA, exploratory testing, evidence capture, and bug reporting.
  Drive running applications and verify they work — not just that tests pass.
  Use when: "run QA", "test this", "verify the feature", "exploratory test",
  "check the app", "QA this PR", "capture evidence", "manual testing".
  Trigger: /qa.
argument-hint: "[url|route|feature] [--tool playwright|chrome|agent-browser]"
---

# /qa

Drive the running application and verify it works. Tests passing is necessary
but not sufficient — QA means exercising the real app as a user would.

**Target:** $ARGUMENTS

## Routing

| Intent | Reference |
|--------|-----------|
| Exploratory QA (default) | This file |
| Browser tool deep-dive | `references/browser-tools.md` |
| Evidence capture patterns | `references/evidence-capture.md` |

## Tool Selection

Pick the right browser tool for the job. Don't default to one — match it.

| Tool | Best for | Token cost |
|------|----------|------------|
| **Playwright MCP** | Deterministic automation, test generation, cross-browser, traces | Medium |
| **Playwright CLI** | Same as MCP but 4x cheaper on tokens; saves snapshots to disk | Low |
| **Chrome MCP** (claude-in-chrome) | Exploratory QA in live browser, existing auth, GIF recording | Medium |
| **agent-browser** | Lowest token usage (82% less), annotated screenshots, video | Low |
| **Stagehand/Browserbase** | Hosted sessions, anti-bot, stealth, session recordings | Medium |
| **Chrome DevTools MCP** | Deep debug: console, network, perf traces, not primary QA | Low |

**Decision tree:**
1. Need existing browser auth/cookies? → **Chrome MCP**
2. Need hosted/stealth/anti-bot? → **Stagehand/Browserbase**
3. Need deterministic test generation? → **Playwright MCP/CLI**
4. Need annotated screenshots + lowest token cost? → **agent-browser**
5. Need deep frontend debug (perf/network)? → **Chrome DevTools MCP**
6. Not sure? → **Chrome MCP** for exploration, **Playwright** for regression

See `references/browser-tools.md` for setup and detailed usage patterns.

## QA Protocol

### Before

```bash
# Verify dev server is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/
# Start if not — adapt command to project
bun dev &
sleep 5
```

### During

For each user-facing change, verify:

- [ ] Happy path works end-to-end
- [ ] Key edge cases from oracle criteria
- [ ] No console errors on affected pages
- [ ] No failed network requests
- [ ] Loading/empty/error states render correctly
- [ ] Mobile viewport works (if applicable)

**Web apps:** Navigate to affected routes, exercise the feature, capture evidence.
**CLIs:** Run commands with representative inputs, verify output.
**APIs:** Curl endpoints, verify response shape and status codes.

### After

- Classify findings: P0 (blocks ship), P1 (fix before merge), P2 (log for later)
- P0/P1: fix and re-run QA on the fix
- P2: document in PR body or create issues
- Capture evidence for everything tested (see below)

## Evidence Requirements

Every QA run produces evidence. No exceptions.

| Change type | Default evidence |
|-------------|-----------------|
| UI feature/fix | GIF walkthrough + route screenshots |
| Visual change | Before/after screenshots |
| Multi-step flow | GIF or video recording |
| API/backend | Terminal output as code block |
| Refactor with parity | GIF showing the app still works |

Evidence goes to `/tmp/qa-{slug}/`. Use `/demo` to upload evidence to PRs.

See `references/evidence-capture.md` for tool-specific capture patterns.

## CLI QA

```bash
mkdir -p /tmp/qa-{slug}
your-cli command --args > /tmp/qa-{slug}/cli-output.txt 2>&1
echo "Exit code: $?"
```

## API QA

```bash
curl -s http://localhost:3000/api/endpoint | jq . > /tmp/qa-{slug}/api-response.json
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/endpoint
```

## Hardening to Tests

When a QA exploration reveals a stable flow worth keeping:

1. Use Playwright's test agents (Planner → Generator → Healer) to convert
   the exploratory flow into a deterministic test
2. Or manually write the test based on the QA notes
3. Add visual baselines if applicable

See `references/browser-tools.md` → Playwright test agents section.

## Gotchas

- **"Tests pass" is not QA.** Tests verify code paths. QA verifies user experience.
  A test can pass while the page is visually broken.
- **Collecting evidence before confirming repro** burns agent budget. Confirm the
  issue reproduces from a clean state before recording elaborate walkthroughs.
- **Screenshots of motionless screens** should be screenshots, not recordings.
  Use video/GIF only for flows with multiple steps or state changes.
- **Skipping console/network checks** misses the most common backend-caused
  frontend bugs: 500s, CORS, missing env vars.
- **Auth-heavy apps** need Chrome MCP (existing session) or Stagehand (stealth).
  Don't waste time re-implementing login flows in Playwright unless you're
  hardening them into a test.
- **agent-browser security controls are opt-in.** Turn on guardrails for
  internal apps.
