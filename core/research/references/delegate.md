# Delegate

> You orchestrate. Specialists do the work.

Reference pattern for invoking multiple AI tools and synthesizing their outputs.

## Your Role

You don't analyze/review/audit yourself. You:
1. **Route** — Send work to appropriate specialists
2. **Collect** — Gather their outputs
3. **Curate** — Validate, filter, resolve conflicts
4. **Synthesize** — Produce unified output

Before routing, consult the repo's encoded context if it exists:
- `AGENTS.md`
- `CLAUDE.md`
- `docs/context/ROUTING.md`
- `docs/context/INDEX.md`

Do not rely on memory for specialist selection when the repo has a routing table.

## Your Team

### Codex CLI — Implementation Agent

**Fire-and-forget delegation for implementation work:**

```bash
codex exec --full-auto "Implement X following the pattern in Y. Run pnpm typecheck after." \
  --output-last-message /tmp/codex-out.md 2>/dev/null
```

| Task | Reasoning Effort |
|------|-----------------|
| Boilerplate, CRUD | `medium` |
| Features, tests | `high` (default) |
| Complex debug, security | `xhigh` |

```bash
codex exec --full-auto -c model_reasoning_effort=xhigh "Debug this race condition"
```

### Task Tool — Parallel Agent Spawning

For parallel work within the agent:

```
Task({ subagent_type: "general-purpose", prompt: "Backend API review" })
Task({ subagent_type: "general-purpose", prompt: "Frontend component audit" })
Task({ subagent_type: "general-purpose", prompt: "Test coverage analysis" })
```

Multiple Task calls in a single message run in parallel.

### Gemini CLI — Researcher, deep reasoner
- Web grounding, thinking_level control, agentic vision
- Best at: current best practices, pattern validation, design research
- Invocation: `gemini "..."` (bash)

### Non-Agentic (Opinions Only)

**Thinktank CLI** — Expert council
- Multiple models respond in parallel, synthesis mode
- Best at: consensus, architecture validation, second opinions
- Invocation: `thinktank instructions.md ./files --synthesis` (bash)
- **Note**: Cannot take action. Use for validation, not investigation.

### Agent Teams — Full Agent Teammates

When workers need to communicate, challenge each other, or coordinate across layers.

**Start a team:** Describe the task and team structure in natural language. Claude handles spawning.

**Lead in delegate mode:** Shift+Tab after team creation. Lead coordinates only.

**Plan approval:** For risky work, require teammates to plan before implementing.
Lead reviews and approves/rejects plans.

**When to use over Codex CLI / Task tool:**

| Signal | Teams | Codex CLI / Task |
|--------|-------|-----------------|
| Workers must discuss findings | YES | no |
| Competing hypotheses / debate | YES | no |
| Cross-layer (FE+BE+tests) | YES | no |
| "Implement this spec" | no | YES |
| Result-only, no coordination | no | YES |

### Internal Agents (Task tool)

Domain specialists for focused review:
- `go-concurrency-reviewer`, `react-pitfalls`, `security-sentinel`
- `data-integrity-guardian`, `architecture-guardian`, `config-auditor`

## How to Delegate

Apply `/llm-communication` principles — state goals, not steps:

### To Codex (via CLI)

Give it latitude to investigate:
```
"Investigate this stack trace. Find root cause. Propose fix with file:line."
```

NOT:
```
"Step 1: Read file X. Step 2: Check line Y. Step 3: ..."
```

### To Thinktank (Non-Agentic)

Provide context, ask for judgment:
```
"Here's the code and proposed fix. Is this approach sound?
What are we missing? Consensus and dissent."
```

### Parallel Execution

Run independent reviews in parallel:
- Multiple Task tool calls in same message
- Gemini + Thinktank can run concurrently (both bash)

## Dependency-Aware Orchestration

For large work (10+ subtasks, multiple phases), use DAG-based scheduling:

### The Pattern

```
Phase 1 (no deps):    Task 01, 02, 03 → run in parallel
Phase 2 (deps on P1): Task 04, 05     → blocked until P1 complete
Phase 3 (deps on P2): Task 06, 07, 08 → blocked until P2 complete
```

Key principles:
1. **Task decomposition** — Break feature into atomic subtasks
2. **Dependency graph** — DAG defines execution order
3. **Parallel execution** — Independent tasks run simultaneously
4. **Fresh context** — Each subagent starts clean (~40-75k tokens)

### Step 1: Decompose

Split feature into atomic tasks. Ask:
- What can run independently? → Same phase
- What requires prior output? → Blocked

### Step 2: Declare Dependencies

Use TaskCreate/TaskUpdate primitives:
```
TaskCreate({subject: "Install packages", activeForm: "Installing packages"})
TaskCreate({subject: "cRPC builder", activeForm: "Building cRPC"})
TaskUpdate({taskId: "2", addBlockedBy: ["1"]})  # Task 2 waits for Task 1
```

### Step 3: Execute Phases

Spawn all unblocked tasks in single message:
```
# Phase 1 - all parallel via Task tool
Task({ subagent_type: "general-purpose", prompt: "Task 1: ..." })
Task({ subagent_type: "general-purpose", prompt: "Task 2: ..." })
Task({ subagent_type: "general-purpose", prompt: "Task 3: ..." })
```

### Step 4: Progress

After each phase:
1. Mark completed tasks: `TaskUpdate({taskId: "1", status: "completed"})`
2. Check newly-unblocked: `TaskList()`
3. Spawn next phase

### When to Use DAG Orchestration

| Scenario | Use DAG? |
|----------|----------|
| Large migration (10+ files, phases) | Yes |
| Multi-feature release | Yes |
| Single feature (1-5 files) | Overkill |
| Quick fix | Overkill |

For typical feature work, simple parallel spawning is sufficient.

## Curation (Your Core Job)

For each finding:

**Validate**: Real issue or false positive? Applies to our context?
**Filter**: Generic advice, style preferences contradicting conventions
**Resolve Conflicts**: When tools disagree, explain tradeoff, make recommendation

If no specialist or spec exists for a risky area, call that out as a context gap.

## Output Template

```markdown
## [Task]: [subject]

### Action Plan

#### Critical
- [ ] `file:line` — Issue — Fix: [action] (Source: [tool])

#### Important
- [ ] `file:line` — Issue — Fix: [action] (Source: [tool])

#### Suggestions
- [ ] [improvement] (Source: [tool])

### Synthesis

**Agreements** — Multiple tools flagged:
- [issue]

**Conflicts** — Differing opinions:
- [Tool A] vs [Tool B]: [your recommendation]

**Research** — From Gemini:
- [finding with citation]
```

## When to Use

- **Code review** — Multiple perspectives on changes
- **Incident investigation** — Agentic tools investigate, Thinktank validates fix
- **Architecture decisions** — Thinktank for consensus
- **Audit/check tasks** — Parallel investigation across domains

## Note

Codex delegation uses the CLI (`codex exec`). For parallel work within the agent,
use the Task tool with `subagent_type: "general-purpose"`.

## Related

- `/llm-communication` — Prompt writing principles
- `/pr-fix` — Example implementation
- `/research thinktank` — Multi-model synthesis
