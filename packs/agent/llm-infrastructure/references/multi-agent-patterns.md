# Multi-Agent Patterns

When and how to decompose work across multiple LLM agents.

## When NOT to Multi-Agent

**80% of use cases stop at complexity levels 1-2.** Before reaching for
multi-agent, exhaust these simpler patterns:

1. **Single LLM call** — classification, generation, extraction
2. **Sequential calls** — chain prompts with code between them
3. **LLM with tools** — single agent with function calling
4. **Single agent loop** — agent iterates until task complete

Only reach for multi-agent when:
- Tasks require genuinely different capabilities or contexts
- Isolation is needed for security or reliability
- Work is parallelizable with clear boundaries
- A single context window can't hold all necessary information

## Anthropic's Workflow Patterns

### Augmented LLM (Level 0)
Single LLM enhanced with retrieval, tools, and memory.
This is NOT multi-agent — it's the foundation everything builds on.

### Prompt Chaining
Sequential LLM calls where each step's output feeds the next.
Code (not LLM) orchestrates the sequence and gates between steps.
```
LLM₁ → validate → LLM₂ → validate → LLM₃ → result
```
**Use for:** Document processing pipelines, staged analysis.

### Routing
Classifier LLM directs input to specialized handlers.
```
Input → Router LLM → { Handler_A, Handler_B, Handler_C }
```
**Use for:** Customer support (billing/technical/account), multi-language.

### Parallelization
Multiple LLMs process simultaneously, results aggregated.
- **Sectioning:** Split task into independent subtasks
- **Voting:** Same task, multiple attempts, select best
```
Task → { LLM₁, LLM₂, LLM₃ } → Aggregator → result
```
**Use for:** Code review (security + performance + style), multi-doc analysis.

### Orchestrator-Workers
Central LLM dynamically decomposes tasks and delegates to workers.
Unlike chaining, the orchestrator decides the decomposition at runtime.
```
Task → Orchestrator → { Worker₁(subtask_a), Worker₂(subtask_b) } → Orchestrator → result
```
**Use for:** Complex coding tasks, research synthesis, multi-file refactoring.

### Evaluator-Optimizer
Generator LLM produces output, evaluator LLM critiques, loop until quality met.
```
Generator → Output → Evaluator → Feedback → Generator → ... → Final
```
**Use for:** Code generation with tests, writing with style requirements.

## Google ADK Patterns

### Sequential Pipeline
Agents execute in fixed order, each receiving previous agent's output.
Differs from prompt chaining in that each step is a full agent (with
tools and loops), not a single LLM call.

### Generator-Critic
One agent generates, another critiques. Similar to evaluator-optimizer
but with full agent capabilities (tools, retrieval) in the critic role.

### Coordinator / Routing
A coordinator agent examines the request and routes to specialized
sub-agents via `AgentTool` wrapping.

### Delegation via AgentTool
Wrap any agent as a tool callable by another agent. The parent agent
decides when to delegate based on task analysis.
```python
sub_agent = Agent(name="researcher", ...)
parent = Agent(tools=[AgentTool(agent=sub_agent)])
```

### Parallel Fan-Out
Coordinator spawns multiple agents simultaneously for independent subtasks.
Results merged after all complete.

### Single-Parent Constraint
Each agent has exactly one parent. This prevents complex dependency graphs
and makes state flow unambiguous.

## OpenAI Topologies

### Manager Pattern
Central manager agent delegates to specialist agents and synthesizes results.
Manager controls flow, assigns tasks, resolves conflicts.

### Decentralized Pattern
Agents hand off to each other directly based on conversation state.
No central coordinator. Each agent decides when to hand off and to whom.

**Trade-off:** Manager is simpler to reason about; decentralized is more
flexible but harder to debug.

## State Management

### Shared Session State
All agents read/write a shared state object. Simple but creates coupling.
```
{ "user_query": "...", "search_results": [...], "analysis": "..." }
```

### Message Passing
Agents communicate through structured messages. More isolated but
requires explicit protocol design.

### Artifact Handoff
Agents produce typed artifacts (files, code, reports) that downstream
agents consume. Natural boundary — artifacts are the contract.

### Google's `temp:` Prefix
Mark turn-scoped data that should auto-expire:
```
session.state["temp:raw_search"] = results  // Gone next turn
session.state["verified_facts"] = facts     // Persists
```

## TinyAGI Fractal Decomposition

Recursive task decomposition with worktree isolation:
1. **Decompose:** Break task into subtasks recursively
2. **Isolate:** Each subtask runs in its own git worktree
3. **Execute:** Subtask agents work independently
4. **Merge:** Merger agents combine results, resolve conflicts
5. **Verify:** Parent agent validates merged output

**Key insight:** Isolation through git worktrees gives each agent a full
copy of the codebase to modify without conflicts. Merging is explicit.

## Checkpoint-Based Delegation (Devin Pattern)

Structure agent work as a series of checkpoints:
1. Plan → checkpoint
2. Implement chunk → checkpoint
3. Test → checkpoint
4. Fix failures → checkpoint
5. Review → checkpoint
6. Next chunk → repeat

At each checkpoint: assess progress, cut losses if stuck, escalate if blocked.
This prevents agents from spinning on dead-end approaches.

## OTP as Agent Runtime

When building multi-agent systems that need production fault tolerance,
Elixir/OTP maps conceptual patterns to battle-tested primitives:

| Pattern | OTP Implementation |
|---------|-------------------|
| Orchestrator-Workers | Supervisor + DynamicSupervisor |
| Parallelization | Task.async_stream / Task.Supervisor |
| State Management | GenServer + ETS |
| Circuit Breaker | GenServer state machine |
| Rate Limiting | GenServer token bucket |
| Routing | Pattern matching in message handler |
| Evaluator-Optimizer | GenServer loop with quality gate |
| Checkpoint-Based | GenServer with persistent state |

### Why OTP Over Hand-Rolled

- **Supervision trees** give automatic restart with configurable strategies
  (one_for_one, one_for_all, rest_for_one)
- **Process isolation** means one agent crashing doesn't take down others
- **Mailbox-based messaging** naturally implements async communication
- **ETS tables** provide shared read-heavy state without bottlenecks
- **Hot code reload** enables zero-downtime agent updates in production

### When to Reach for OTP

- Managing 10+ concurrent long-running agent processes
- Need fault tolerance (agents that crash and restart cleanly)
- Rate limiting across multiple agent instances
- Distributed agent coordination across nodes

When building multi-agent systems, prefer Elixir/OTP over hand-rolled orchestration
in languages without equivalent concurrency primitives.
