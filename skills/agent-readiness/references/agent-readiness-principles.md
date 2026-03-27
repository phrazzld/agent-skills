# Agent-Readiness Principles

The deeper "why" behind each pillar. Use this when explaining recommendations
to the user or when a subagent needs to prioritize between competing fixes.

## The Core Thesis

"The agent is not broken. The environment is." — Factory AI

Agent effectiveness is bounded by three things:
1. **Environment** — the agent can use the system autonomously
2. **Intent** — the agent understands what you want and why
3. **Feedback loops** — the agent can verify its own work, fast

Every pillar maps to one or more of these. Fixes that improve feedback loops
have the highest ROI because they compound across every agent interaction.

Source: [Christian Houmann, "The agent-ready codebase"](https://bagerbach.com/blog/agent-ready-codebase)

## Why Each Pillar Matters

### Style & Validation → Feedback Loops

Without linters and formatters, agents waste cycles on style drift. They
submit code, wait for CI, get style failures, fix blindly, repeat. Pre-commit
hooks give instant feedback — seconds instead of minutes. This is often the
single highest-leverage fix.

**Factory's observation:** "Missing pre-commit hooks mean the agent waits
ten minutes for CI feedback instead of five seconds."

Lint rules also encode architectural intent. Named exports, explicit DTOs,
predictable file naming, and import restrictions teach agents your conventions
through enforcement rather than documentation.

Source: [Factory AI, "Using Linters to Direct Agents"](https://factory.ai/news/using-linters-to-direct-agents)

### Build & CI → Feedback Loops + Environment

Deterministic builds ensure the agent can verify its work. If the build
requires tribal knowledge from Slack threads, the agent has no idea how to
verify. A single build command that works on clone is table stakes.

CI speed matters as much as CI existence. A pipeline that takes 20 minutes
is nearly as bad as no pipeline for agent workflows. The agent can't iterate
if each cycle takes 20 minutes.

### Testing → Feedback Loops

Testing is the single biggest lever for agent output quality. With tests,
the agent has an oracle: change code, run tests, see if it broke something.
Without tests, the agent is flying blind.

**Key insight:** Coverage percentage matters less than assertion density and
behavior coverage. 80% line coverage with shallow tests (`expect(true)`) is
worse than 50% coverage with real assertions. The agent needs tests that
actually catch regressions.

**Speed matters:** If the suite takes 20 minutes, the agent can't do TDD.
Target <5 minutes for the full local suite. For larger suites, make it easy
to run a subset.

Source: [Damian Galarza, "Four Dimensions of Agent-Ready Codebase Design"](https://www.damiangalarza.com/posts/2026-03-25-four-patterns-that-separate-agent-ready-codebases/)

### Documentation → Intent

CLAUDE.md and AGENTS.md are the most important files for agent effectiveness.
They are loaded into context at startup. A perfect README that agents don't
read is worth less than a scrappy CLAUDE.md they always load.

What to document for agents:
- How to build, test, lint, deploy
- Architectural conventions and why they exist
- Common gotchas and failure modes
- Environment variables and their purpose
- Style guide and naming conventions

Architecture Decision Records (ADRs) help agents understand WHY choices
were made, not just WHAT the code does. This prevents agents from
"improving" things that are intentionally designed that way.

### Dev Environment → Environment

"Could you launch a hundred agents in your codebase right now? If not,
figure out what's stopping you. It's a bottleneck in your factory."

Reproducible environments eliminate "works on my machine." Devcontainers,
Docker Compose, and setup scripts ensure agents (and new developers) can
go from clone to running in one command.

Isolated workspaces (git worktrees, multiple checkouts) let multiple agents
work in parallel without stepping on each other.

Source: [Christian Houmann, "The agent-ready codebase"](https://bagerbach.com/blog/agent-ready-codebase)

### Code Quality & Architecture → Intent + Feedback Loops

Modular code with clear interfaces lets agents work on one piece without
understanding the whole system. Deep modules (complex internals, simple
interfaces) are ideal — the agent interacts through the simple interface
and doesn't need to understand the internals.

Large files, circular dependencies, and god classes force agents to load
massive context to make any change. Keep files focused. Keep coupling low.
Keep the blast radius of any change small.

File organization should be predictable. An agent should be able to guess
where a file lives based on its purpose. Feature-based organization
(`features/auth/`, `features/billing/`) is more agent-friendly than
type-based organization (`controllers/`, `models/`, `services/`).

### Observability → Feedback Loops

Agents need to diagnose failures, not just detect them. Structured logging,
error tracking, and health checks let agents understand what went wrong
after a change. Without observability, a failing deployment is a black box.

Give agents read access to telemetry. If they can query logs and metrics,
they can self-diagnose and self-correct.

### Security & Governance → Environment + Guardrails

Branch protection, CODEOWNERS, and review gates are guardrails that prevent
agents from shipping bad changes. They're not obstacles — they're safety nets.

Secret scanning prevents agents from accidentally committing credentials.
Dependency auditing prevents agents from introducing vulnerable dependencies.

## Maturity Level Philosophy

Levels are gated, not averaged. A codebase at L3 has solid foundations
(L1-L2) plus standardized automation. Skipping foundations to chase
advanced features creates a hollow score.

**L3 is the target for most teams.** It represents the minimum bar for
agents to handle routine maintenance autonomously: bug fixes, tests, docs,
dependency upgrades.

| Level | What agents can do |
|-------|-------------------|
| L1 | Agent needs constant hand-holding. Every change requires human verification. |
| L2 | Agent can make changes but needs human to verify and integrate. |
| L3 | Agent handles routine maintenance: bugs, tests, docs, deps. |
| L4 | Agent handles feature work with fast iteration cycles. |
| L5 | Agent handles complex tasks with minimal human oversight. |

## Prioritization Framework

When recommending fixes, prioritize by:

1. **Feedback loop speed** — pre-commit hooks, fast tests, local-first CI
2. **Agent context** — CLAUDE.md, architecture docs, env var documentation
3. **Verification ability** — test coverage, type safety, lint rules
4. **Environment access** — reproducible setup, isolated workspaces
5. **Governance** — branch protection, code owners, secret scanning

The first three categories account for ~80% of agent effectiveness improvement.

## Reference Implementations

Open-source tools for automated assessment:
- **Kodus agent-readiness**: `npx @kodus/agent-readiness .` — 39 checks, 7 pillars, TypeScript, MIT
- **AgentReady**: `pip install agentready` — Python, research-backed, HTML reports
- **AIReady**: `getaiready.dev` — web-based scanning with cognitive load analysis
