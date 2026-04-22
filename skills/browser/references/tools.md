# Per-Tool Capabilities

One section per wrapper / MCP / infrastructure option. Each section
opens with **what it is**, gives minimal install, then **reach for it
when** and **skip it when**.

---

## Playwright (driver + wrapper)

The universal substrate. Cross-browser (Chromium/Firefox/WebKit),
multi-language (TS, Python, .NET, Java). Auto-waits for elements,
network, and navigations. Isolated browser contexts per test.
Built-in tracing (screenshots + DOM + network in one `.zip`).

**"Playwright" is three distinct surfaces with different cost profiles:**

| Surface | Tokens/action | Use for |
|---------|---------------|---------|
| **Raw Playwright (code)** | 0 — no LLM in loop | Pyramid Layer 1: CI, known flows |
| **Playwright CLI** | ~0 — snapshots to disk | Pyramid Layer 3: token-conscious loops |
| **Playwright MCP** | 200–400/snapshot, accumulates | Pyramid Layer 2/3: interactive agent debugging |

When developers say "Playwright is heavy for agents," they mean
**Playwright MCP**. Raw Playwright (code you write) is the most
efficient option in the entire space.

### Install

```bash
# Node
npm init playwright@latest
# Python
pip install playwright && playwright install
```

### Reach for it when

- You know the flow and selectors are stable.
- You need cross-browser coverage.
- You want deterministic CI without per-action LLM cost.
- You need screenshots/video/trace evidence for CI artifacts.
- You're testing an Electron app (see `electron.md`).

### Skip it when

- Selectors break more often than you can fix them (add Stagehand).
- You need the agent to explore a novel UI (add Browser Use or Stagehand).
- You need hosted stealth/proxies (add Browserbase).

### Docs

- https://playwright.dev/
- https://playwright.dev/docs/api/class-electronapplication

---

## Playwright MCP (official, Microsoft)

MCP server exposing Playwright to any MCP client (Claude Code, Cursor,
Windsurf, Claude Desktop). Uses accessibility-tree snapshots (~200–400
tokens) with element refs — no vision model needed, no coordinate
guessing. 40+ tools: navigate, click, type, screenshot, trace, network
mocking, storage.

### Install (Claude Code)

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

### Reach for it when

- An agent needs a persistent interactive browser loop during a coding
  session.
- Accessibility-tree introspection is more valuable than a screenshot.
- You want the agent to generate Playwright test code from exploration
  (`browser_generate_playwright_test`).

### Skip it when

- You're running headlessly in CI (use raw Playwright in code).
- You need to attach to your real Chrome session (use Dramaturg or
  Claude-in-Chrome).
- Token budget matters more than interactivity (use agent-browser CLI).

### Docs

- https://playwright.dev/mcp/introduction

---

## Stagehand (Browserbase, hybrid wrapper)

Browser automation SDK with four primitives that each wrap an LLM call:

- `act("click the submit button")` — natural-language action.
- `extract("get the price", schema)` — structured extraction with Zod.
- `observe("what's clickable here?")` — semantic page understanding.
- `agent({ task })` — multi-step autonomous execution.

v3 (2025-10) decoupled from Playwright-only: Puppeteer and raw CDP
drivers now supported. 44% faster on iframes/shadow DOM. Caching across
runs turns repeat AI calls into deterministic code. TypeScript-first;
Python bindings at `browserbase/stagehand-python` (lag behind TS).

### Install

```bash
npm install @browserbasehq/stagehand
# With Browserbase:
export BROWSERBASE_API_KEY=...
# Or BYOK with Anthropic/OpenAI
```

### Reach for it when

- UI changes often and raw Playwright selectors become maintenance debt.
- You need structured extraction with schema guarantees.
- You want deterministic *most* of the time but resilience on edge cases.
- TypeScript codebase.

### Skip it when

- UI is stable — raw Playwright is cheaper and faster.
- Python codebase — Browser Use is the better Python fit.
- Budget is per-action-sensitive and tasks aren't decomposable —
  consider raw Playwright with explicit recovery logic.

### Critical

**Default to atomic primitives.** `agent()` can burn 500k+ tokens on a
single goal. `act`/`extract`/`observe` run at ~7k tokens/step with
caching. Reserve `agent()` for genuinely open-ended tasks you can't
decompose.

### Docs

- https://github.com/browserbase/stagehand
- https://docs.stagehand.dev/
- https://www.browserbase.com/blog/stagehand-v3

---

## Browser Use (full LLM agent, Python)

Python library where an LLM plans and drives the entire task. The agent
reads the DOM + screenshots and decides actions. Model-agnostic (Claude,
GPT, Gemini, local via LiteLLM). Multi-tab, memory, composes with
LangChain/CrewAI. Wraps Playwright under the hood via CDP.

**Autonomy-optimized, NOT token-optimized.** Every step involves a
planning LLM call on top of DOM reading. Expect 2–5s per action and
$0.02–0.30 per complete task. Compared to raw Playwright code (zero
tokens), Browser Use is dramatically more expensive — you're buying
autonomy, not efficiency. The pyramid places it firmly in Layer 3
(exploration) or Layer 4 (continuous), never Layer 1.

Organization also ships `workflow-use` (RPA 2.0), `macOS-use`
(macOS app automation), `video-use`, and `web-ui` (Gradio UI).

### Install

```bash
uv init && uv add browser-use && uv sync
uvx browser-use install  # installs Chromium
```

### Reach for it when

- You need full autonomy on multi-step tasks without decomposing them.
- Python codebase.
- You're composing with LangChain/CrewAI.
- The task is truly open-ended ("find the cheapest flight matching …").

### Skip it when

- Task is decomposable — Stagehand atomic primitives are more controllable.
- You need deterministic replay — the planner varies run to run.
- Budget is tight — Browser Use burns tokens on planning loops (2–5s
  per action, $0.02–0.30 per task).
- TypeScript codebase — Stagehand fits better.

### Docs

- https://github.com/browser-use/browser-use
- https://github.com/browser-use/browser-use/blob/main/AGENTS.md

---

## Browserbase (infrastructure)

Hosted headless Chrome. Not a framework — infrastructure you plug into
Playwright, Puppeteer, Stagehand, or Browser Use. Key capabilities:

- **Stealth / anti-bot** — residential proxies, fingerprint rotation.
- **Auto-CAPTCHA** — solved at infrastructure level.
- **Session recording** — every session captured as video.
- **Session Inspector** — replay with timeline, logs, network.
- **Live View** — watch agents in real time for human-in-the-loop.
- **Concurrent browsers** — 25/100/250+ per tier.

### Install (connect with Playwright)

```typescript
import { chromium } from 'playwright-core';
const browser = await chromium.connectOverCDP(
  `wss://connect.browserbase.com?apiKey=${API_KEY}`
);
```

### Reach for it when

- Target has bot detection or CAPTCHAs.
- You need session replay for team review.
- You're running at scale and concurrent-browser limits matter.
- You want a human to watch/intervene via Live View.

### Skip it when

- Target has no bot detection and you don't need replay — local
  Chromium in a container is cheaper.
- Latency-sensitive work — network round-trips to hosted browser add ms.
- Your data can't leave your infrastructure.

### Pricing (2026)

- Free: 3 concurrent, 1 browser-hour, 15-min sessions.
- Developer: 100 browser-hours included, then $0.12/hr, 25 concurrent.
- Startup: 500 browser-hours, $0.10/hr overflow, 100 concurrent.
- Scale: custom, 250+ concurrent, SSO, HIPAA.

### Docs

- https://www.browserbase.com/
- https://www.browserbase.com/pricing
- https://docs.browserbase.com/

---

## Claude-in-Chrome (live-session MCP)

Chrome extension that exposes your real Chrome to Claude via MCP tools:
`navigate`, `read_page`, `find`, `form_input`, `computer` (click/type),
`gif_creator`, `read_console_messages`, `read_network_requests`,
`javascript_tool`. Always call `tabs_context_mcp` first.

### Reach for it when

- Exploratory QA against your own logged-in session (Gmail, Notion,
  internal tools) where re-authing is painful.
- Recording a GIF walkthrough for a demo or bug report.
- Investigating a live console/network error in your actual browser.

### Skip it when

- CI — it requires a human Chrome instance.
- Shared/reproducible runs — the session is yours.
- Video output — GIF only, no `.webm` recording.

### Alerts warning

JS `alert`/`confirm`/`prompt` dialogs block the MCP. Don't trigger
destructive buttons. If you do, the user must dismiss manually.

---

## Dramaturg (`@playwright-repl/mcp`)

Alternative "real Chrome" MCP. Playwright runs *inside* your existing
Chrome session via a companion extension. Cookies, auth tokens, and
localStorage all intact. Two modes: bridge (default, your Chrome) and
standalone (launches Chromium with the extension loaded).

### Install

```bash
claude mcp add @playwright-repl/mcp
# or npm i @playwright-repl/mcp
```

### Reach for it when

- You want Playwright-style locators but against your real Chrome.
- You need to automate a logged-in SaaS without re-authing every run.
- You're combining agent automation with manual interactivity in the
  same window.

### Skip it when

- CI — same reason as Claude-in-Chrome.
- You don't want an extension installed.

### Docs

- https://registry.npmjs.org/@playwright-repl/mcp

---

## agent-browser (Vercel Labs, CLI)

Rust CLI designed for LLM agents. Compact text output, ref-based
accessibility snapshots, annotated screenshots, WebM video recording,
snapshot diffing, pixel diffing. ~82% less context than Playwright MCP
for equivalent tasks.

**Already registered in `registry.yaml`** (pin `4cc6ca40b76a590bb06d1ec5abc16d27bb7d43c0`)
and syncs as `vercel-agent-browser`. The companion `vercel-dogfood`
skill in the same repo teaches a repro-first bug-documentation workflow
inside a running app.

### Install

```bash
npm install -g agent-browser
# or direct binary
curl -fsSL https://agent-browser.dev/install | sh
```

### Usage

```bash
agent-browser navigate https://localhost:3000
agent-browser snapshot
agent-browser screenshot --annotate /tmp/qa/annotated.png
agent-browser record start /tmp/qa/walkthrough.webm
agent-browser record stop
agent-browser snapshot --save before.json
agent-browser snapshot --diff before.json
```

### Reach for it when

- Token budget is tight in a long agent loop.
- You need annotated screenshots (labels on interactive elements).
- You want WebM video with precise start/stop control.
- Pixel-diff visual regression without external tooling.

### Skip it when

- You need cross-browser (Chromium-only).
- You need parallel browser contexts like Playwright Test.

### Docs

- https://github.com/vercel-labs/agent-browser

---

## Chrome DevTools MCP

Diagnostic tool, not a primary driver. Exposes Chrome DevTools Protocol
via MCP: performance traces, network inspection, console filtering,
device emulation, CDP-level screenshots.

### Install

```bash
claude mcp add chrome-devtools npx @anthropic-ai/chrome-devtools-mcp@latest
```

### Reach for it when

- A page is janky and you need a perf trace.
- Network calls fail and you need request/response timing.
- Console errors need investigation with regex filtering.
- You need to understand render-path changes.

### Skip it when

- You're driving a test — use Playwright directly.
- Sensitive data — Google's CrUX API may receive trace URLs.

---

## Quick comparison

| Tool | Pyramid layer | Tool-layer role | Cost profile | Best for |
|------|---------------|-----------------|--------------|----------|
| Raw Playwright (code) | 1, 2 | driver + wrapper | **0 tokens**/action | CI gate, known flows, cross-browser |
| Playwright CLI | 2, 3 | wrapper | ~0 (disk) | Token-conscious agent loops |
| Playwright MCP | 2, 3 | wrapper (MCP) | 200–400/snapshot, accumulates | Agent-driven interactive debugging |
| Playwright Planner/Generator/Healer | 2 | authoring AI | LLM at author time, 0 at runtime | AI-generated tests, committed code |
| Stagehand atomic | 2, 3 | wrapper | ~7k tokens/step cached | Fragile steps inside Layer 1 tests |
| Stagehand `agent()` | 3 | full agent | 500k+ tokens possible | Open-ended exploration (decompose first!) |
| Browser Use | 3, 4 | full agent | $0.02–0.30/task | Autonomous Python exploration |
| agent-browser CLI | 3 | wrapper (CLI) | compact, ~82% < Playwright MCP | Token-conscious long agent loops, pixel diff |
| Claude-in-Chrome | 3 | infra (live) | free | Exploratory in your real session |
| Dramaturg | 3 | infra (live) | free | Playwright locators in real Chrome |
| Browserbase | any | infra (hosted) | $0.10–0.12/hr | Stealth, replay, scale |
| Chrome DevTools MCP | 2, 3 | wrapper (MCP) | free | Diagnostic / perf |
| QA Wolf / Octomind | 2 | SaaS authoring AI | subscription | Generate deterministic Playwright code |
| QA.tech / Mabl / Rainforest | 2, 3, 4 | SaaS compressing pyramid | subscription | Full-pyramid vendor lock-in |
| bugAgent / supaguard | 4 | bug-filing / synthetic monitoring | subscription | Continuous QA output channel |
