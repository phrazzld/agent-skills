---
name: otp-agent-orchestration
description: |
  Elixir/OTP patterns for concurrent AI agent orchestration services. Use when
  designing systems that manage many concurrent, long-running LLM agent processes
  (10-60+ min each) with fault tolerance, rate limiting, and webhook-driven dispatch.
  Covers: DynamicSupervisor for agent pools, GenServer rate limiters, Phoenix webhook
  ingestion, Port-based CLI agent dispatch, ETS state registries, telemetry.
  Keywords: Elixir, OTP, supervision tree, GenServer, agent service, concurrent agents,
  rate limiting, webhook, long-running process, fault tolerance, DynamicSupervisor.
user-invocable: false
---

# OTP Agent Orchestration

When a service manages many concurrent, long-running, failure-prone AI agent processes,
OTP supervision trees are the natural architecture.

## Signal: Use This Pattern When

- Webhook-driven: external events spawn agent work
- Concurrent: tens to hundreds of agent processes simultaneously
- Long-running: each process runs 10-60+ minutes (not request/response)
- Failure-prone: agent processes may crash, hang, or timeout
- Rate-limited: shared LLM API budget across all agents
- Persistent: deployed on dedicated hardware, not ephemeral CI

## Signal: Don't Use When

- One-shot scripts or CLI tools
- Single-agent, single-user prototyping
- Serverless / ephemeral execution (Lambda, GitHub Actions)
- The concurrency is I/O-bound HTTP, not process-bound agents

## Core OTP Mapping

| Agent Concept | OTP Primitive |
|---|---|
| Agent pool | DynamicSupervisor |
| Single agent run | GenServer (or Task) |
| Rate limiter | GenServer with token bucket |
| Repo/attempt registry | ETS table |
| Webhook handler | Phoenix Endpoint |
| Agent CLI dispatch | Port (for pi, aider, codex) |
| Metrics/cost tracking | :telemetry |
| Config hot reload | Application.get_env + runtime config |

## Supervision Tree

```
Application
├── Web.Endpoint (Phoenix — webhook ingestion)
├── Agent.Supervisor (DynamicSupervisor — agent pool)
│   ├── Agent.Run (GenServer — one per fix/review/task)
│   └── ...hundreds concurrent
├── RateLimiter (GenServer — token bucket per model)
├── Registry (ETS — repo → active runs, cooldowns)
└── Telemetry (cost, latency, outcomes)
```

## Key Design Decisions

See `references/architecture-decisions.md` for details on:
- Port vs System.cmd for CLI agent dispatch
- GenServer vs Task for agent runs
- ETS vs GenServer for state
- Rate limiter design
- Graceful shutdown and worktree cleanup
