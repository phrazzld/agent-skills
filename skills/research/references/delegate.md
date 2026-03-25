# Delegate

> You orchestrate. Sub-agents do the work.

Reference pattern for dispatching work to sub-agents and synthesizing results.

## Your Role

You don't investigate/review/implement yourself. You:
1. **Route** — Send work to appropriate sub-agents
2. **Collect** — Gather their outputs
3. **Curate** — Validate, filter, resolve conflicts
4. **Synthesize** — Produce unified output

## Sub-Agent Archetypes

| Archetype | When to use | Example dispatch |
|-----------|-------------|-----------------|
| **planner** | Decompose work, write specs | `Agent(subagent_type: "planner", prompt: "...")` |
| **builder** | Implement, test, fix | `Agent(subagent_type: "builder", prompt: "...")` |
| **critic** | Evaluate output quality | `Agent(subagent_type: "critic", prompt: "...")` |
| **Explore** | Codebase research, file discovery | `Agent(subagent_type: "Explore", prompt: "...")` |
| **philosophy bench** | Design review (ousterhout, carmack, grug, beck) | Spawn all 4 in parallel |

### External tools (non-agent)

| Tool | Invocation | Best for |
|------|------------|----------|
| Thinktank CLI | `thinktank question.md context.md --synthesis` | Multi-model consensus, architecture validation |
| /research | Invoke the research skill | Web search, prior art, reference implementations |

## How to Delegate

State goals, not steps:

**Good:**
```
Agent(subagent_type: "builder", prompt: "Investigate this stack trace. Find root cause. Propose fix with file:line.")
```

**Bad:**
```
Agent(prompt: "Step 1: Read file X. Step 2: Check line Y. Step 3: ...")
```

## Parallel Execution

Spawn independent sub-agents in a single message — they run concurrently:

```
Agent(subagent_type: "Explore", prompt: "Backend API review — list all endpoints, check auth")
Agent(subagent_type: "Explore", prompt: "Frontend component audit — find unused components")
Agent(subagent_type: "Explore", prompt: "Test coverage analysis — which modules lack tests?")
```

## When to use which pattern

| Signal | Parallel sub-agents | Agent teams | Single agent |
|--------|-------------------|-------------|--------------|
| Independent tasks | YES | overkill | too slow |
| Workers must discuss | no | YES | no |
| Competing hypotheses | no | YES | no |
| Simple implementation | no | no | YES |

## Dependency-Aware Orchestration

For large work (10+ subtasks, multiple phases), use DAG-based scheduling:

```
Phase 1 (no deps):    Task 01, 02, 03 → spawn in parallel
Phase 2 (deps on P1): Task 04, 05     → blocked until P1 complete
Phase 3 (deps on P2): Task 06, 07, 08 → blocked until P2 complete
```

Use task tracking to manage phases:
1. Decompose into atomic tasks with dependency declarations
2. Spawn all unblocked tasks in a single message
3. Mark completed, check newly-unblocked, spawn next phase

## Curation (Your Core Job)

For each sub-agent finding:

- **Validate**: Real issue or false positive?
- **Filter**: Generic advice? Style preference contradicting conventions?
- **Resolve conflicts**: When sub-agents disagree, explain tradeoff, recommend

## Output Template

```markdown
## [Task]: [subject]

### Critical
- [ ] `file:line` — Issue — Fix: [action] (Source: [agent])

### Important
- [ ] `file:line` — Issue — Fix: [action] (Source: [agent])

### Synthesis
**Agreements** — Multiple agents flagged: [issue]
**Conflicts** — [Agent A] vs [Agent B]: [your recommendation]
```

## Related

- `/harness` — Harness engineering and context lifecycle
- `/code-review` — Multi-agent review implementation
- `/research thinktank` — Multi-model synthesis
