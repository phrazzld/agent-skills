# The Browser Automation Pyramid

The same shape as the classic test pyramid (unit → integration → E2E →
manual), specialized for browser work in the AI-agent era. Each layer
has a different cost profile, a different reliability promise, and a
different kind of bug it catches.

```
        Layer 4 — Continuous QA (staging/prod)
       ┌──────────────────────────────────────┐
       │  Scheduled agents, autonomous bug     │
       │  filing, synthetic monitoring         │
       └──────────────────────────────────────┘
      Layer 3 — Exploratory / Persona-driven
     ┌────────────────────────────────────────┐
     │  Charters, SBTM/PROOF, UX-gap discovery │
     │  Stagehand agent(), Browser Use,        │
     │  agent-browser, custom persona harness  │
     └────────────────────────────────────────┘
    Layer 2 — Hybrid / AI-assisted
   ┌──────────────────────────────────────────┐
   │  Playwright + AI helpers: Planner/         │
   │  Generator/Healer, Stagehand atomic on     │
   │  fragile steps, AI-authored tests          │
   │  committed to repo, visual regression      │
   └──────────────────────────────────────────┘
  Layer 1 — Deterministic Playwright E2E
 ┌────────────────────────────────────────────┐
 │  Critical user journeys, CI gate, 99%+      │
 │  reliable. `getByRole` first, fixtures,     │
 │  `storageState`, parallel shards.            │
 └────────────────────────────────────────────┘
```

## Invariants

- **Layer 1 is the CI gate.** If Layer 1 fails, the build is broken.
  No other layer has enough determinism to hold this role.
- **Findings flow down, not up.** Layers 3 and 4 are discovery
  instruments. Every real bug or UX gap they find is a candidate for
  hardening into a Layer 1 or Layer 2 test. "Exploration found X → we
  added a deterministic test for X" is the healthy loop.
- **AI shows up twice.** Authoring-time AI (Layer 2, commits code) and
  runtime AI (Layer 3/4, pays LLM cost every run). They have opposite
  cost profiles and opposite reliability profiles. Mix them on purpose.
- **Never use runtime agents as release gates.** Stochastic execution +
  stochastic assertions = flaky gates that train the team to ignore
  them. Runtime agents file bugs; deterministic tests gate releases.

---

## Layer 1 — Deterministic Playwright E2E

**Goal:** 99%+ reliable assertions on the user journeys the business
cannot ship broken. Login, checkout, core data-entry, permissions.

**Stack:** Raw Playwright code, `@playwright/test`, local Chromium per
CI runner, fixtures, `getByRole` locators, `storageState` for auth,
`trace: 'on-first-retry'`.

**Locator hierarchy (in order of preference):**

1. `getByRole('button', { name: 'Submit' })` — accessibility-aligned,
   survives visual redesigns that keep semantics.
2. `getByLabel`, `getByPlaceholder`, `getByText`.
3. `getByTestId('checkout-submit')` — stable but requires discipline
   (someone has to add the `data-testid`).
4. CSS/XPath — last resort. A selector here is a future flake.

**What this layer catches:** functional regressions. Assertion-level
bugs. "Does clicking X cause Y." Does not catch: UX legibility, "can a
real user figure this out," novel flows.

**Cost:** near-zero at runtime. Build cost is engineering time to write
and maintain the suite. Figure 15–25%/month maintenance overhead on a
fast-moving UI without AI help, <5% with Layer 2 self-healing.

**Red flags you're at the wrong layer:**
- You keep writing "retry 3 times if this flakes" — the test is unstable;
  fix the selector or push the flaky step to Layer 2.
- You're spending more time maintaining selectors than shipping — add
  Playwright's Healer agent (Layer 2) or Stagehand atomic primitives
  on the specific fragile steps.

---

## Layer 2 — Hybrid / AI-Assisted

**Goal:** reduce maintenance cost of Layer 1 without giving up its
reliability. AI helps *author* or *repair* tests; execution stays
deterministic.

### Playwright's built-in agents (1.56+)

Three specialized agents ship with Playwright:

- **Planner** — reads the app, produces a structured test plan in
  Markdown.
- **Generator** — turns a plan into runnable Playwright code with
  validated locators and assertions.
- **Healer** — reads failing tests, inspects the live UI, patches
  broken locators.

These are **authoring-time** agents. Their output is committed code.
You review the PR like any other diff. Zero runtime LLM cost.

### Stagehand atomic primitives on fragile steps

When one specific step keeps breaking (for example, a date picker that
changes its DOM every redesign), wrap just that step in Stagehand's
atomic `act`/`extract`/`observe`. The rest of the test stays in raw
Playwright code. You pay LLM cost only on the problem step.

### AI-generating commercial platforms

- **QA Wolf** — subscription service, generates and maintains
  Playwright code for you; outputs are deterministic, committed code.
- **Octomind** — similar; generates maintainable Playwright tests from
  natural-language intent.

Both of these belong at Layer 2 because their *output* is deterministic
code. Contrast with Layer 3/4 tools whose runtime is stochastic.

### Visual regression

Playwright's `toHaveScreenshot()` with baseline images committed to the
repo, or Applitools/Percy for AI-assisted diffing that tolerates
intentional UI changes. Layer 2 because it runs deterministically in
CI, but AI-assisted diffing reduces false positives.

**What this layer catches:** the regressions Layer 1 would also catch,
plus the regressions Layer 1 *missed* because the selector silently
drifted.

---

## Layer 3 — Exploratory / Persona-Driven

**Goal:** find the bugs Layers 1 and 2 cannot find — UX gaps, legibility
failures, flows no one thought to test.

A test asserts that clicking a button triggers an event. It does not
assert that a user understood what the button was for before clicking
it. That gap lives here.

### The charter pattern

Give the agent a **charter** — a short brief of what to explore, for
how long, as whom. Not a script. Examples:

- "Explore the onboarding flow as a first-time user who doesn't know
  what the product does. Stop after 10 minutes or when you've completed
  sign-up, whichever comes first."
- "Explore the basket flow on a mobile viewport. Try to buy something."
- "You are an administrator setting up a new team. Spend 15 minutes."

### The persona pattern

Load the agent with a specific user identity. Three orthogonal
dimensions (from the PersonaTester paper):

- **Testing mindset** — cautious vs aggressive, reads everything vs
  skims.
- **Exploration strategy** — depth-first vs breadth-first, happy-path
  vs edge-case.
- **Interaction habit** — keyboard-driven vs mouse-driven, mobile vs
  desktop, tech-savvy vs novice.

Combine dimensions into named personas ("Sarah — water utility director,
Excel-literate, not a developer, patient but not technical") and run
them separately. Run the same charter as 3–5 personas to build coverage.

### The expectation-check protocol

Before every click, the agent states **what it expects to happen**.
After the click, it records **what actually happened**. Any mismatch is
a flag.

This catches legibility bugs: a button that does the right thing but
isn't obvious about it. Functional tests will never find these because
the button works — the problem is it doesn't read as what it does.

### SBTM + PROOF reporting

**Session-Based Test Management** structures each run as a session:
charter + time-boxed duration + notes.

**PROOF** structures the report:
- **Past** — what the agent tried.
- **Results** — what actually happened.
- **Obstacles** — what got in the way (confusing copy, missing
  affordance, dead-end flow).
- **Outlook** — what the agent would try next.
- **Feelings** — how the persona felt (frustrated, confused, confident).
  Sounds soft; catches the real UX gaps.

### Tool choice at this layer

- **Browser Use (Python)** — full-agent autonomy, best for open-ended
  charters where decomposition would be more work than letting the
  agent plan.
- **Stagehand `agent()` (TypeScript)** — same shape for TS codebases.
  Budget for the token cost; cap step count.
- **agent-browser CLI** — compact snapshots, lowest token budget per
  step. Good when a run is long (hundreds of steps).
- **Custom persona harness** — alexop.dev's site-agnostic pattern: the
  harness reads `--help` at runtime so swapping the browser CLI
  doesn't change the prompt. Persona lives in the system prompt, the
  charter lives in the user prompt.

### The `/agent-battle` trick

Run the same charter as 2–3 parallel agents, same prompt hash,
different models (Claude + GPT + Gemini). Compare their reports.
Disagreements are triage signals — either the agents perceived
different things (UX ambiguity) or one of them hallucinated.

### What this layer catches

- Legibility bugs (buttons that work but aren't obvious).
- Dead-end flows (user gets stuck, no retry or help).
- Permission mismatches (admin page lets a non-admin through).
- Empty-state bugs (what does the screen look like when there are no
  records? Most teams never test this).
- Consent/GDPR banners that block the real content.
- Accessibility gaps that assertion-based tests don't flag.

### What this layer does NOT catch

- Regressions on known flows — Layer 1 does that.
- Cross-run consistency — the agent is stochastic, so the same run
  twice is not the same test twice. This is the feature, not the bug,
  but it means: **do not gate releases on Layer 3**.

---

## Layer 4 — Continuous QA (staging / production)

**Goal:** catch issues that only surface against the real deployment.
Data dependencies, third-party integrations, actual latency, real
auth, production-specific config.

### Scheduled agent runs

A Layer 3 agent + persona + charter, but scheduled: post-deploy,
every hour, every night. Runs against staging (safer) or a
production-mirror tenant (more realistic). Findings land in Slack,
Jira, Linear, or git-bug with screenshots, repro steps, and severity.

### Autonomous bug filing

Commercial tools in this space:

- **bugAgent** — MCP-native, integrates with Claude Code, files to
  Jira/Linear/GitHub with auto-classification.
- **QA.tech** — builds an app knowledge graph from exploration, runs
  prompt-defined tests, excels at edge cases and empty states.
- **supaguard** — AI-generated Playwright tests run from global
  locations with smart retries to eliminate false alerts.

### DIY pattern

If you don't want a SaaS dependency:

- Browser Use or Stagehand `agent()` in a scheduled CI job.
- Agent runs the charter, captures screenshots + console + network +
  screen recording on any flagged finding.
- A second agent (or a classifier prompt) triages the finding:
  severity, repro confidence, reproducible vs flake.
- Confident findings post as issues; low-confidence findings go to a
  review queue.

### Production-safety considerations

Running agents against production is not free. Risks:

- **Side effects** — the agent *will* click buttons. Use read-only
  personas or a QA tenant. Never run a write-capable agent against a
  production account that matters.
- **Rate limits** — agents are noisy; you'll hit rate limits and
  trigger your own monitoring.
- **Cost** — a persistent Layer 4 agent running hourly is a real LLM
  bill. Budget explicitly.
- **Attribution** — a bug found by an agent against production may be
  racing a real user. Timestamp everything.

### What this layer catches

- Environment-specific breakage (staging-only config drift, prod-only
  feature flags).
- Third-party regressions (a vendor pushed a breaking change and
  nobody emailed).
- Canary-style signals before real users hit the issue.
- Synthetic monitoring uptime, not just HTTP-200 but "can a user
  actually sign up."

---

## Commercial landscape (as of 2026)

Platforms that compress the whole pyramid into one vendor. Worth
knowing; not blanket-recommended. Lock-in and export-path matter more
than feature lists.

| Platform | Layer emphasis | Outputs | Escape hatch |
|----------|---------------|---------|--------------|
| **QA Wolf** | 1, 2 | Deterministic Playwright code | Yes — committed to your repo |
| **Octomind** | 2 | Deterministic Playwright code | Yes — committed to your repo |
| **Mabl** | 1, 2 | Low-code, ML self-healing | Limited — platform-specific tests |
| **QA.tech** | 3, 4 | App knowledge graph, autonomous agent | Limited |
| **Rainforest QA** | 1, 2, 3 | No-code + visual/DOM/AI signals, human-in-loop review | Limited |
| **Momentic** | 2, 3 | Intent-based, no stored selectors | Limited |
| **testRigor** | 3, 4 | Plain-English tests, observes prod users | Limited |
| **Applitools/Percy** | 2 | Visual AI diffing on top of your framework | Yes — plugs into Playwright |
| **bugAgent** | 4 | MCP-native bug filing | N/A — it's an output channel, not a test suite |
| **supaguard** | 4 | AI-generated Playwright + smart retries | Partial |

**Prefer "outputs deterministic Playwright" vendors** (QA Wolf, Octomind,
Applitools) if you want to own what you paid for.

---

## Anti-patterns

- **Skipping Layer 1.** "We have AI agents doing QA" without a
  deterministic regression suite is not a QA strategy. It's a
  discovery program running without a foundation. The regressions will
  still happen; you'll just find out from customers.
- **Using Layer 3 as a release gate.** Stochastic outputs + a CI gate =
  a team that quickly learns to rerun until green. Eventually the gate
  stops meaning anything.
- **Letting Layer 3 findings sit.** Discovery is cheap; hardening is
  what compounds. If an agent keeps finding the same UX gap and nobody
  turns it into a test, the agent is a bug report generator, not a
  QA system.
- **Hand-writing Layer 2 prompt-driven Playwright tests.** If every
  test body is prompt-driven (`page.act("click login")` everywhere),
  every run is a Layer 3 run wearing a Layer 1 costume. You'll pay
  runtime LLM cost for regressions a selector could have caught for
  free.
- **Running write-capable agents against production.** Agents will do
  things. Plan for it — read-only personas, dedicated QA tenants, and
  cleanup hooks.
- **Same-model self-critique.** If the `/agent-battle` is three runs
  of the same Claude model, you'll get correlated failures. Mix
  foundations (Claude + GPT + Gemini) for real cross-validation.

---

## References

- alexop.dev — https://alexop.dev/posts/exploratory-qa-ai-agents-site-agnostic-harness/
- Christian Potvin on persona testing — https://dev.to/christian_potvin_73438f37/persona-based-testing-with-ai-agents-find-the-ux-gaps-your-e2e-tests-cant-see-n7i
- Ashita Orbis persona-probe — https://app.ashitaorbis.com/posts/024-testing-through-the-eyes-of-real-users
- PersonaTester (arxiv) — https://www.arxiv.org/pdf/2603.24160
- Scrolltest autonomous QA — https://scrolltest.com/autonomous-testing-agent-playwright-llm-ollama-2026/
- Playwright Test Agents 1.56+ — https://playwright.dev/docs/test-agents
- QA Wolf — https://www.qawolf.com/
- Octomind — https://www.octomind.dev/
- bugAgent — https://bugagent.com/
- supaguard — https://www.supaguard.app/docs
