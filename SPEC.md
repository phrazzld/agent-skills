# SPEC.md — The Spellbook Philosophy

> **"The only limit to my progress now is understanding. Because if I understand how things work, I know what is fundamentally possible. I am solely a creative."**
> — yacine, "being a human in the singularity"

---

## What Spellbook Is

Spellbook is a unified operating philosophy for building software with AI agents, expressed as portable skills, agents, and enforcement infrastructure that any project can install. One repo. All harnesses. Every stage of the software lifecycle covered.

It is not a library of prompts. It is the codified judgment of a senior engineer — the constraints, invariants, feedback loops, and quality gates that make agents produce correct software instead of plausible software.

The north star: **every system we build should be fully autonomous — testable, observable, self-maintaining, and continuously improving — with humans providing judgment and taste, not labor.**

### Core Beliefs

**1. The harness is the product, the model is a commodity.**

Models converge. Claude, GPT, Gemini — the gap narrows every quarter. What differentiates output is the persistent context infrastructure: skills that encode judgment, tests that verify correctness, hooks that enforce invariants, monitors that detect drift. OpenAI built a million lines of code with zero manually-written lines — the leverage came entirely from the harness, not the model (OpenAI, "Harness Engineering," 2026-02-11).

**2. Mechanical enforcement over prose instructions.**

A rule in CLAUDE.md is a suggestion. A lint rule is a law. A test is physics. "Teams with solid verification culture get leverage; teams without it get a chaos multiplier" (Sunil Pai, "where good ideas come from," 2026-01-02). OpenAI's team encodes taste as custom linters with remediation instructions in error messages. When documentation falls short, they promote the rule into code (OpenAI harness article). Factory AI calls this Lint-Driven Development: "Lint green = definition of done" (@alvinsng thread, 2026-03-20).

**3. Everything must be observable and interactable by agents.**

"From the agent's point of view, anything it can't access in-context while running effectively doesn't exist. Knowledge that lives in Google Docs, chat threads, or people's heads are not accessible to the system" (OpenAI). If agents can't see your logs, can't run your tests, can't drive your UI, can't query your metrics — you have an incomplete harness. Ramp's system gives agents access to the full observability surface: logs, metrics, traces, monitors, production behavior (Ramp, "How we made Ramp Sheets self-maintaining," 2026-03-23).

**4. Fix the system, not the instance.**

When an agent produces bad output, the fix is systemic: update the skill, add the lint rule, add the test, extend the gotcha. Never just fix the code and move on. "When the agent struggles, we treat it as a signal: identify what capability is missing, and how do we make it both legible and enforceable for the agent?" (OpenAI). The calibrate skill embodies this: `type system > lint rule > hook > test > CI > skill > AGENTS.md > memory` — fix at the highest-leverage point.

**5. Agents make code cheap but do not make judgment cheap.**

"If you ask an agent for a vibe, it will give you a vibe-shaped completion" (Sunil Pai). A 576,000-line LLM-generated SQLite rewrite was 20,171x slower because one performance invariant was missing — an invariant that exists because someone profiled a real workload 20 years ago ("Your LLM Doesn't Write Correct Code. It Writes Plausible Code."). Skills encode the invariants that come from real experience, not training data.

**6. Beware tool-shaped objects.**

"I have seen teams of very smart engineers build agent systems of breathtaking complexity whose primary output is the existence of the system itself" (Will Manidis, "Tool Shaped Objects," 2026-02-10). Agent logs analyzed by other agents producing dashboards populated by more agents. The question that must be answered for every skill, every workflow, every system: **"What is the number, before you make it go up?"** Every output must be measurable. If you can't define "done," the skill is suspect.

---

## The Full Software Lifecycle

Spellbook covers every stage. Each stage has: portable skills that encode best practices, quality gates that enforce them mechanically, and agent-accessible tooling that makes the stage fully autonomous.

### 1. Design & Specification

Before an agent writes a single line of code, the human's judgment is encoded as explicit constraints.

**The context packet** (from Sunil Pai) is the unit of specification:
- Goal (1 sentence) — what outcome, not what mechanism
- Non-goals — the "helpful creativity" kill switch
- Constraints / invariants — the laws of physics for this change
- Authority order — when sources disagree, what wins? (default: tests > code > docs > lore)
- Repo anchors — the 3-10 files that define truth for this change
- Prior art / blessed patterns — what to copy, what to reuse
- Oracle (definition of done) — the checks that decide success
- Risk + rollout — how it could fail, how to undo it

"This turns 'senior intuition' into explicit constraints and executable truth. Agents stop guessing, juniors learn faster, reviews become about invariants instead of vibes" (Sunil Pai).

**Skills:** `shape`, `context-packet` (new), `harness-engineering`

**Quality gate:** No implementation starts without a context packet. The oracle IS the acceptance criteria.

### 2. Build & Implementation

TDD is the default. Red → Green → Refactor. The agent writes failing tests first, then implements, then cleans up.

**The implementation loop:**
```
spec → failing test → implementation → passing test → lint check → repeat
```

"We require Codex to parse data shapes at the boundary, but are not prescriptive on how. We enforce invariants, not implementations" (OpenAI). Architecture is enforced by rigid layers with validated dependency directions (Types → Config → Repo → Service → Runtime → UI) and custom linters.

**Lint-Driven Development** encodes architecture as lint rules, not prose:
- Ban patterns mechanically (useEffect in conditionals, deep imports past barrel files, etc.)
- Custom linters with remediation instructions in error messages — the agent self-corrects against lint output
- "Linter + a light skill file — even smaller models produce correct code" (@chaaai responding to @alvinsng)

**Night-shift pattern:** Humans write specs during the day. Agents implement overnight in autonomous sessions that run for hours. "I do not want to read agent plans. I do not want to sit and prompt and reprompt agents" (Jamon Holmgren, "Night Shift Agentic Workflow," 2026-03-14). OpenAI regularly sees "single Codex runs work on a single task for upwards of six hours, often while the humans are sleeping."

**Skills:** `autopilot`, `debug`, `lint-driven-development` (new), `night-shift` (new), `scaffold`, `ralph-patterns`

**Quality gate:** All tests pass. All lints pass. Test coverage ≥ target (100% for critical paths). No implementation without a failing test first.

### 3. Testing & QA

100% test coverage is the target, not the aspiration. Tests are the primary quality gate and the agent's primary feedback loop.

**Three testing layers:**

**Unit/integration tests** — the agent writes and runs these in the implementation loop. TDD makes them inherent, not afterthought.

**Agent-driven browser QA** — agents drive the UI directly. Not unit testing the frontend — actually clicking, typing, navigating, and validating visual output. Skills like `agent-browser`, `dogfood`, and `visual-qa` give agents the ability to boot the app per worktree, navigate with Chrome DevTools Protocol, take screenshots, compare against expected states, and record videos of test runs. OpenAI wired CDP into the Codex runtime so agents could "reproduce bugs, validate fixes, and reason about UI behavior directly."

**Fuzz testing and edge case discovery** — agents systematically probe for edge cases: upload weird files, submit malformed inputs, test concurrent operations, exercise failure modes. Ramp's system does exactly this: "subtle failure modes are rarely apparent from static code review" — agents need to run code against live sandboxes to find them.

**Skills:** `assess-tests`, `dogfood`, `visual-qa`, `agent-browser`, `webapp-testing`

**Quality gate:** Tests pass. Coverage meets target. Agent-driven QA finds no regressions. Browser-based smoke tests pass.

### 4. Code Review

Multi-perspective automated review before any human sees the code.

**The Cerberus pattern:** Multiple independent review agents running in parallel, each with a different lens. The current Cerberus implementation runs 5 KimiCode agents per PR. Each finds different things — performance issues, security holes, style violations, architectural drift, missing tests.

**The Triad:** Ousterhout (deep modules, information hiding), Carmack (pragmatic shippability), and Grug (complexity demon hunting) review every significant change. They don't agree with each other — that's the point. Convergence across opinionated reviewers is a strong quality signal.

**The assess-* pipeline:** Structured assessment skills with JSON output contracts:
- `assess-depth` — code depth, abstraction quality, module boundaries
- `assess-tests` — test coverage, quality, edge cases
- `assess-docs` — documentation freshness, accuracy
- `assess-drift` — architectural consistency
- `assess-simplify` — unnecessary complexity
- `assess-review` — comprehensive review synthesis

These compose mechanically because they output structured JSON, not prose. The orchestrator (autopilot/settle) can parse results and make proceed/fix/escalate decisions without reading paragraphs.

**Skills:** `assess-*` family, `settle`, Cerberus (external), Triad agents (ousterhout, carmack, grug)

**Quality gate:** All assess-* skills pass. Cerberus review has no critical findings. Triad consensus is "ship" (or issues are addressed).

### 5. Deployment

Gradual, observable, reversible.

**The canary pattern:** Deploy to a small percentage of traffic. Monitor error rates, latency, key business metrics. Auto-rollback on regression. Expand traffic only after the canary period shows no degradation.

"Agents can query logs with LogQL and metrics with PromQL. With this context available, prompts like 'ensure service startup completes in under 800ms' become tractable" (OpenAI). Agents should be able to verify their own deployments.

**Skills:** `canary`, `deploy-*` (per-service patterns)

**Quality gate:** Canary passes. No error rate regression. Latency within SLA. Feature flags enable instant rollback.

### 6. Monitoring & Observability

This is where the Ramp article transforms everything. The goal: **agent-first observability where the system monitors itself and proposes its own fixes.**

**The Ramp pattern, as a portable skill:**
- On PR merge, an agent reads the diff and generates monitors instrumenting the new code
- When a monitor fires, an agent is dispatched with the alert context
- The agent reproduces the issue in a sandbox, pushes a fix, and notifies the team
- If the alert is noise, the agent tunes or deletes the monitor
- State stored on the monitor itself prevents duplicate work

"In a few weeks, we scaled Ramp Sheets from ten hand-written monitors to over a thousand, one for every 75 lines of code. Our manual monitors were broad-strokes. The AI-generated ones are far more granular, acting like a tight mesh over the exact shape of the code" (Ramp).

**Key principle:** "Detect everything, notify selectively." The system watches every signal but each alert reaching a human should mean something. "Teams ignore noisy monitors, and they'll ignore noisy agents too" (Ramp).

**The Canary project** is the platform for this. Currently: open-source, self-hosted observability. Target state: the Ramp pattern — agent-generated monitors, agent-driven triage, autonomous fix proposals. Canary-watch already synthesizes incidents into GitHub issues via LLM. The next step: closing the loop so the agent that receives the issue also proposes the fix.

**Skills:** `autonomous-maintenance` (new — the Ramp pattern as a portable skill), `observability`, `canary`

**Quality gate:** Monitoring coverage proportional to code complexity. Alert-to-fix time measured. False positive rate decreasing over time.

### 7. Maintenance & Improvement

Software decays. Documentation drifts. Dependencies age. Patterns established early get violated later. The maintenance stage prevents entropy.

**Doc-gardening** (from OpenAI): A recurring agent that scans for stale documentation, validates cross-links, checks freshness, and opens fix-up PRs. "A monolithic manual turns into a graveyard of stale rules. Agents can't tell what's still true, humans stop maintaining it, and the file quietly becomes an attractive nuisance" (OpenAI). OpenAI's team spent 20% of every week cleaning "AI slop" before automating this.

**Session learning extraction** (from @doodlestein's CASS pattern): After work sessions, mine session logs for learnings. Extract gotchas, patterns that should be codified, skills that misfired. Feed learnings back into the project's harness. "It's so powerful to take learnings from agent sessions and feed them back into the skills agents use. This is sort of 'in-context recursive self-improvement'" (@doodlestein, 2026-03-20). Multiple practitioners are independently discovering this loop — @a13v's Learn/Evolve workflow, @ai_embracing's 6-month session capture pipeline.

**Clanker-discipline** (from @garybasin): Complexity cleanup that deletes more code than it adds. Derive don't store. Make wrong states impossible. Enforce function contracts. Data over procedure. "In a busy codebase, I run this often as a cleanup refactor" (@garybasin, 2026-03-22).

**Calibrate** with the Tool Shaped Objects diagnostic: When something goes wrong, don't just fix the code. Ask: is this skill producing work or the sensation of work? Fix the harness before fixing the instance.

**Skills:** `doc-gardening` (new), `session-learning-extraction` (new), `clanker-discipline` (evaluate — already exists externally), `calibrate`, `reflect`, `groom`

**Quality gate:** Documentation matches code (automated freshness checks). Session learnings are captured (not lost when context ends). Complexity trending down, not up.

### 8. Backlog & Swarm Orchestration

For addressing large backlogs, technical debt, or parallel feature development: agent swarms.

**Bitterblossom** is the declarative sprite factory for provisioning and orchestrating Claude Code agent fleets on Fly.io. Each agent gets an isolated dev environment (a Firecracker microVM), picks up an issue, implements, creates a PR, and moves to the next one.

The pattern: human grooms and prioritizes the backlog (using `/groom`). Agent swarms execute the backlog items in parallel. Each agent has the full Spellbook harness available — skills, enforcement, quality gates. The output is PRs, not code — humans review and merge.

**Related approaches:** Factory AI's Droid Missions (long-running complex tasks), OpenAI's Symphony pattern, the Ralph Wiggum Loop (iterate until all reviewers are satisfied).

**Skills:** `groom`, `autopilot`, `ralph-patterns`, Bitterblossom (external)

**Quality gate:** Each PR passes all gates independently. Swarm throughput measured. Backlog velocity tracked.

---

## The Project Constellation

Spellbook is the center. Each project in the constellation handles a specific concern. Together they form a complete autonomous development infrastructure.

| Project | Role | Spellbook Connection |
|---------|------|---------------------|
| **Spellbook** | Skills, agents, harness definitions, enforcement | The source of truth for how agents work |
| **Cerberus** | Multi-agent code review council | Runs as a review gate in the SDLC. Skills tell agents how to invoke it. |
| **Bitterblossom** | Agent fleet orchestration on Fly.io | Executes backlog items in parallel. Each agent loads Spellbook skills. |
| **Canary** | Agent-first observability + incident synthesis | Evolving toward Ramp-style autonomous monitoring. Skills teach agents how to generate/triage monitors. |
| **Canary-watch** | Webhook → GitHub issue synthesis | Closes the loop: alert → issue → agent fix → PR → review → merge |

### Browser & QA Tools
- **agent-browser** — Chrome DevTools Protocol for agent-driven UI interaction
- **dogfood** — agents use the product they're building (visual QA)
- **visual-qa** — screenshot comparison, DOM inspection
- **Playwright / browser-use** — headless browser automation for end-to-end testing

### Orchestration Patterns
- **Ralph Loop** — iterate until all reviewers are satisfied (used by OpenAI internally)
- **Flywheel** — automated backlog processing pipeline
- **Droid Missions** (Factory AI) — long-running complex tasks with mission-specific context

---

## Infrastructure: One Repo, All Harnesses

### The Fragmentation Problem

Today, agent configuration is scattered:
- `~/.claude/` — Claude Code global skills, settings, hooks
- `~/.codex/` — Codex config, agents
- `~/.pi/` — Pi runtime config
- `pi-agent-config/` — separate Git repo for Pi globals
- `~/.agents/` — shared agents (ambiguous ownership)

### The Solution: Spellbook Absorbs Everything

```
spellbook/
├── skills/              # Harness-agnostic skills (the shared core)
│   ├── autopilot/       # Works on any harness
│   ├── debug/
│   ├── shape/
│   └── ...
├── agents/              # Harness-agnostic agent definitions
│   ├── ousterhout.md
│   ├── grug.md
│   └── ...
├── claude/              # Claude Code specific
│   ├── settings.json    # Hooks, permissions (Claude-only feature)
│   ├── skills/          # Claude-only skills (if any)
│   └── agents/          # Claude-only agents (if any)
├── codex/               # Codex specific
│   ├── AGENTS.md        # Codex's routing document
│   └── agents/          # TOML-format agents
├── pi/                  # Pi specific (absorb pi-agent-config)
│   ├── settings.json
│   ├── context/         # Pi's context hierarchy
│   │   └── global/
│   │       ├── AGENTS.md
│   │       └── APPEND_SYSTEM.md
│   ├── skills/          # Pi-specific skills
│   └── agents/          # Pi-specific agent decomposition
├── scripts/
│   ├── bootstrap.sh     # Links spellbook → all harness dirs
│   └── ...
└── registry.yaml
```

### Harness-Specific Enforcement

Hooks are a Claude Code feature. Codex doesn't support them. Pi has its own model. Therefore:

- **Shared enforcement logic** lives in `skills/*/scripts/` as plain executables (Python, shell). These work everywhere.
- **Claude Code** wires enforcement scripts as hooks in `claude/settings.json` or SKILL.md `hooks:` frontmatter.
- **Codex** references enforcement via AGENTS.md prose ("run this script after changes").
- **Pi** wires enforcement via its own mechanism in `pi/`.

A skill that wants enforcement provides the script. Each harness wires it up in its own way. The "enforced vs guidelines" distinction in SKILL.md is load-bearing: the agent knows which rules have mechanical backing and which rely on its judgment.

### Distribution: How Changes Reach Runtime

The repo IS the config. Bootstrap links it to the right places:

```bash
# bootstrap.sh (conceptual)
ln -sf $SPELLBOOK/skills/* ~/.claude/skills/
ln -sf $SPELLBOOK/agents/* ~/.claude/agents/
ln -sf $SPELLBOOK/claude/settings.json ~/.claude/settings.json

ln -sf $SPELLBOOK/skills/* ~/.codex/skills/
cp $SPELLBOOK/codex/AGENTS.md ~/.codex/AGENTS.md

ln -sf $SPELLBOOK/pi/* ~/.pi/agent/
```

For project-level skill selection, `.spellbook.yaml` manifests may still make sense — declaring which subset of the catalog a specific project uses. But the global story is just symlinks from one repo.

The `/focus` skill's current GitHub-download mechanism is overengineered for personal use. Evaluate whether it should become a simpler "manage the links between spellbook repo and runtime dirs" or be replaced entirely by bootstrap.sh.

---

## Research Sources

This document was synthesized from processing 86 clippings (March 24, 2026) plus deep analysis of the Spellbook repo by 7 parallel research agents.

### Core Articles (Deep-Read)

| Article | Author | Key Contribution |
|---------|--------|-----------------|
| Harness Engineering: Leveraging Codex in an Agent-First World | Ryan Lopopolo (OpenAI) | "Give Codex a map, not a 1,000-page manual." AGENTS.md as router. Custom linters as enforcement. Doc-gardening agents. 1M LOC, 0 human-written. |
| The Coding Agent Harness | Julián (MercadoLibre) | Four levers: rules, MCP, skills, specs. Context rot at 60%. Skills as "programmable, context-aware, composable units of agent behavior." 20,000 developers. |
| How we made Ramp Sheets self-maintaining | Ramp Labs | Monitor-driven maintenance. One monitor per 75 LOC. 40 real bugs in first week. "Detect everything, notify selectively." |
| Lessons from Building Claude Code: How We Use Skills | Thariq (Anthropic) | Nine skill categories. Gotchas as highest-signal content. Description field as model trigger. On-demand hooks. Plugin marketplace lifecycle. |
| where good ideas come from (for coding agents) | Sunil Pai | Context packet template. Authority order. "If you ask for a vibe, you get a vibe-shaped completion." Seven innovation patterns mapped to agent strengths. |
| The File System Is the New Database | Muratcan Koylan | 3-level progressive disclosure. Format-function mapping. Append-only as safety mechanism. Episodic memory. |
| The Claude-Native Law Firm | Zack Shapiro | Skills encode individual judgment, not templates. 2-person firm vs 100-lawyer firms. The Spellbook thesis in practice. |
| Tool Shaped Objects | Will Manidis | "Ask what the number is before making it go up." Agent systems whose primary output is the existence of the system itself. |
| Night Shift Agentic Workflow | Jamon Holmgren | Strict spec/implement separation. 6 review personas. Postmortem-first: fix the system before fixing the code. |
| Your LLM Doesn't Write Correct Code | (various) | 20,171x slower SQLite from one missing invariant. METR RCT: devs 19% slower with AI but believed 20% faster. |
| being a human in the singularity | yacine (@yacineMTB) | Personal sovereignty through custom software. "The only limit is understanding." |
| A sufficiently detailed spec is code | (Haskell for All) | Counter-argument: specs detailed enough to generate code ARE code. Skills should encode WHY (invariants), not WHAT (pseudocode). |

### Key Threads

| Thread | Author | Key Contribution |
|--------|--------|-----------------|
| Recursive self-improvement | @doodlestein | CASS system: mine session logs → extract learnings → feed back into skills. "In-context recursive self-improvement, cyborg style." |
| Lint-Driven Development | @alvinsng (Factory AI) | Linters as agent guardrails. Ban useEffect. Agent readiness. Context compression. Missions. |
| Clanker-discipline | @garybasin | Derive don't store. Make wrong states impossible. Deletes more code than it adds. |
| LLM fallback code is toxic | @Aaronontheweb | Agents add silent fallbacks that hide bugs. Fail-fast principle. |
| Codex vs Claude Code skills | @emollick | Judgment-based skills outperform procedural skills in novel situations. |
| MCP for skill distribution | @RhysSullivan | MCP as executor pattern. Contrarian: MCP is underrated. |
| GStack sprint pipeline | @Voxyz_ai | /office-hours → /qa → /ship. Agent with browser-based QA. |
| Overnight Ralph session | @ryancarson | Feature completed while sleeping. Proof of concept for autonomous night-shift. |

---

*Written 2026-03-24, revised 2026-03-25. This is a living document.*
