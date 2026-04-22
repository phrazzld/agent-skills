# Common Stacks

Known-good compositions, organized by pyramid layer. Each stack gives
driver + mode + wrapper + infrastructure with a short rationale.

For the pyramid rationale itself, see `references/pyramid.md`.

---

## Layer 1 — Deterministic Playwright E2E

### CI test suite for a web app

**Stack:** Playwright Test → scripted → raw Playwright API → local
Chromium (per-runner).

- CI runners are disposable and deterministic. Local Chromium is the
  cheapest and most reproducible.
- Playwright's auto-wait + tri-browser contexts + built-in trace viewer
  cover evidence without extra tooling.
- AI-layer wrappers buy nothing in CI: you control the UI, and selectors
  break on intentional UI changes you want to catch anyway.

### Electron app E2E tests

**Stack:** Playwright `_electron` → scripted → raw Playwright +
`electron-playwright-helpers` → local app under Node (source) *and*
packaged binary (CI).

- Electron needs both sides: renderer (web) and main (Node).
- `electron-playwright-helpers` covers menus, IPC, dialog stubs, and
  packaged-app parsing.
- Split source-mode and packaged-mode as two CI jobs. Packaged-mode
  catches ASAR / code-signing regressions source tests miss.

---

## Layer 2 — Hybrid / AI-Assisted

### AI-authored tests, committed to repo

**Stack:** Playwright Test → scripted output → Playwright Planner/Generator/
Healer (1.56+) → local Chromium.

- Planner explores the app and produces a Markdown plan.
- Generator turns the plan into runnable Playwright code.
- Healer repairs failing tests against the live UI.
- **Authoring-time AI, runtime-deterministic.** The output is committed
  code you review in PR.

**When to step out:** if the commercial platform fit is better (bigger
suite, non-technical stakeholders authoring), use QA Wolf or Octomind
— both output Playwright code so you keep escape-hatch ownership.

### Self-healing fragile steps

**Stack:** Playwright Test → scripted body, hybrid on fragile steps →
raw Playwright + Stagehand atomic for the one bad step → local Chromium.

- Wrap only the problematic step in `page.act("click the date picker
  for next month")`. Everything else stays as CSS/role locators.
- You pay LLM cost per *fragile* step, not per *every* step.
- Cache the resolved action so repeat runs harden into deterministic
  code over time.

**When to step out:** if the whole suite is fragile, something is wrong
at a higher level (design system churn, testability debt). Fix the
cause before papering over with LLM calls.

### Structured extraction from a fragile site

**Stack:** Playwright → hybrid → Stagehand `extract()` with Zod schema
→ local Chromium or Browserbase if anti-bot.

- The page layout changes; the data shape doesn't. `extract()` with a
  typed schema stays stable across redesigns.
- Keep navigation in raw Playwright code; only data-pulling uses the LLM.
- Cache extractions to harden into deterministic code.

### Visual regression

**Stack:** Playwright → scripted → `toHaveScreenshot()` baseline diffs
→ local Chromium. OR Applitools / Percy as a plugin for AI-tolerant
diffing.

- Playwright's built-in is the lowest-friction path. Baseline images
  committed to the repo.
- Applitools/Percy shine when the UI changes intentionally often and
  you want AI to tolerate expected diffs while flagging regressions.
- agent-browser's `snapshot --diff` fits when the capturing loop is an
  agent, not a test runner.

### Agent debugging a live app (dev loop)

**Stack:** local dev server → interactive → Playwright MCP + Chrome
DevTools MCP → local Chromium.

- Agent edits code; this stack lets it verify the UI actually works —
  accessibility tree + console + network in one session.
- Playwright MCP provides interaction; Chrome DevTools MCP provides
  observability.

---

## Layer 3 — Exploratory / Persona-Driven

### Persona-driven exploratory charter

**Stack:** Playwright (via CDP) → full agent → Browser Use (Python) or
Stagehand `agent()` (TS) → local Chromium or Browserbase.

- Persona lives in the system prompt ("Sarah, water utility director,
  not technical, patient"). Charter lives in the user prompt
  ("explore the onboarding flow for 10 minutes").
- Agent states expectation before every click. Mismatch = bug.
- Output is an SBTM session note + PROOF report (Past / Results /
  Obstacles / Outlook / Feelings).
- Findings feed back into Layer 1 or 2 as new deterministic tests.

### Site-agnostic exploratory harness (alexop.dev pattern)

**Stack:** agent-browser CLI or Playwright CLI → full agent → external
LLM (Claude, GPT, Gemini) → local Chromium.

- Harness reads the chosen CLI's `--help` at runtime — no hardcoded
  selectors in the prompt. Swapping CLI doesn't require prompt rewrites.
- Run for 5–10 minutes per charter; save screenshots only on findings.
- `/agent-battle` — run the same charter as 2–3 parallel agents with
  different foundation models. Disagreements are triage signals.

### Exploratory QA in my logged-in SaaS

**Stack:** real Chrome → interactive → Claude-in-Chrome MCP *or*
Dramaturg (`@playwright-repl/mcp`) → your session.

- Re-authing Gmail/Notion/Salesforce every run is the killer cost.
  Real-session tools eliminate it.
- Claude-in-Chrome for GIF capture and visual verification.
- Dramaturg when you want Playwright locators (seedable future tests).
- **Not a CI tool.** Sessions and auth persist.

### Token-conscious long agent loop

**Stack:** Playwright → agent-driven → agent-browser CLI → local Chromium.

- Agent-browser's compact snapshots matter when the agent runs for hours.
- Annotated screenshots with element labels let the agent "see" without
  streaming full images.

---

## Layer 4 — Continuous QA (staging / production)

### Scheduled persona agent against staging

**Stack:** CI cron job → full agent → Browser Use or Stagehand `agent()`
→ Browserbase (for stealth/replay) or local Chromium in a container.

- Agent runs the charter on schedule. Findings post to Slack/Jira/Linear.
- Layer 3 outputs (repro + screenshots) become Layer 1 tests when
  confirmed.
- Budget the LLM cost explicitly — an hourly Layer 4 agent is a real
  monthly bill.

### Autonomous bug-filing pipeline

**Stack:** persona agent → triage classifier (second LLM or prompt) →
bugAgent MCP (or git-bug + custom webhook) → Jira/Linear/GitHub.

- First agent explores and flags anomalies.
- Second agent/prompt classifies: severity, repro confidence, flake vs
  real bug.
- Confident findings auto-file; low-confidence findings queue for human
  review.
- **Never let the agent close bugs** — filing is reversible, closing
  isn't.

### Synthetic monitoring with AI classification

**Stack:** supaguard (or custom Playwright + Claude classifier) →
scheduled globally → on failure, AI classifier triages → alert only on
real outages.

- Traditional synthetic monitors page on transient network blips.
- AI classifier distinguishes critical outage / performance degradation
  / soft visual glitch.
- supaguard's "teleportation retries" verify failures from multiple
  regions before alerting — reduces 99%+ of false alarms.

### Production-mirror QA tenant

**Stack:** write-capable Layer 3 agent → dedicated QA tenant with
cleanup hooks → Browserbase (for stealth against your own prod).

- QA tenant mirrors production config but is isolated from real users.
- Post-run cleanup hook empties the tenant state.
- Agent can exercise write-path flows (checkout, signup, settings
  changes) without production risk.

---

## Layer 0 — Anti-bot sites at scale

Not a pyramid layer per se; an orthogonal concern that can attach to
any layer.

**Stack:** any of the above **+ Browserbase**.

- Browserbase's stealth mode + residential proxies + auto-CAPTCHA
  handles the anti-bot layer at infrastructure level.
- Your code doesn't change — it connects to Chromium over CDP.
- Session recording lets you replay a failed run with full timeline and
  network log (the only sane way to debug intermittent anti-bot blocks).

**When to step out:** if your data can't leave your infrastructure,
run stealth Chromium locally with `playwright-extra` + stealth plugins.
You give up session replay.

---

## Stack-selection shortcut

If you're unsure, default by pyramid layer:

- **Layer 1 (CI gate, web):** Playwright Test, local Chromium. Done.
- **Layer 1 (Electron):** Playwright `_electron` + electron-playwright-helpers. Done.
- **Layer 2 (AI-authored tests):** Playwright 1.56+ Planner/Generator/Healer.
- **Layer 2 (fragile step):** Stagehand atomic on just that step.
- **Layer 3 (TS exploration):** Stagehand atomic primitives with persona prompt.
- **Layer 3 (Python exploration):** Browser Use with persona prompt.
- **Layer 3 (logged-in exploration):** Claude-in-Chrome or Dramaturg.
- **Layer 4 (scheduled QA):** Layer 3 stack in cron + bug-filing integration.
- **Any layer + anti-bot:** add Browserbase.

**Nothing fits cleanly?** Pick Playwright at Layer 1 and add AI layers
only where selectors genuinely fail.
