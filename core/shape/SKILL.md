---
name: shape
description: |
  Full interactive planning for a single idea. Product spec, technical design,
  breadboarding, and implementation planning in one conversational session.
  Use when: planning a feature, shaping an idea, writing specs, designing architecture.
  Trigger: /shape, /spec, /architect, /brainstorm, /breadboard, /shaping, /critique.
disable-model-invocation: true
argument-hint: <issue-id-or-idea>
---

# SHAPE

> Take a raw idea and shape it into something buildable.

## Role

You are both product lead and technical lead. Shape an idea from raw concept
to implementation-ready issue(s) in one interactive session.

## When to Use

| Situation | Use |
|-----------|-----|
| Full backlog session, many issues | `/groom` |
| Full planning for one idea: product + technical + discussion | **`/shape`** |
| Just need quick autonomous delivery | `/autopilot` |

## Modes

### Full Shape (default)
Interactive product + technical exploration with user. Phases 1-4 below.

### Spec Only (`/shape --spec-only`)
Product exploration only (WHAT and WHY). Skip technical design.

### Design Only (`/shape --design-only`)
Technical exploration only (HOW). Requires existing product spec on issue.

### Critique (`/shape --critique <persona>`)
Adversarial expert review. See `references/critique-personas.md`.

### Plan Only (`/shape --plan`)
Generate implementation plan from existing spec+design. See `references/writing-plans.md`.

## Workflow

### Phase 1: Understand

Accept input: raw idea (string), issue ID, or observation.

1. If no issue exists: create skeleton immediately
2. If issue exists: `gh issue view $1 --comments`
3. Load `project.md` if present (falls back to `vision.md`)
4. Read relevant codebase context — adjacent features, existing patterns, constraints
5. If `docs/context/` is missing, bootstrap `INDEX.md`, `ROUTING.md`, and `DRIFT-WATCHLIST.md` from `codified-context-architecture/references/templates.md` or explicitly note that repo context is not tuned yet. Do not cite cold-memory docs that do not exist.

Present: "Here's what I understand. Let me explore the problem space."

### Phase 2: Product Exploration

**Gate: Do NOT write any code or take implementation actions until product direction is locked.**

1. **Investigate** — Problem space, user impact, prior art (parallel agents)

   | Agent | Focus |
   |-------|-------|
   | Problem explorer | What's the real problem? Who has it? How painful? |
   | Web research agent | How do others solve this? Current best practices |
   | Codebase explorer | Existing patterns, affected files, reusable utilities |
   | User impact analyst | Who's affected, how much, cost of inaction |

2. **Brainstorm** — Propose 2-3 product approaches with tradeoffs. For each:
   - What the user experiences (concrete interaction flow)
   - What value it delivers
   - Scope: Small / Medium / Large
   - What it enables downstream

   **Recommend one.** Lead with recommendation and reasoning.
   If ideas become polished variants or the room goes flat, invoke `break-the-frame`.

3. **Discuss** — User steers. One question at a time. Multiple choice preferred.
   Iterate until product direction is locked.

4. **Find the cheapest test** — If uncertainty is real, define the fastest cheap
   experiment that would change the decision. Prefer probes over speculation.

5. **Draft spec** — Post on issue:

   ```markdown
   ## Product Spec

   ### Problem
   [Validated problem — 2-3 sentences]

   ### Users
   **Primary**: [Role] — [context, pain, goal]

   ### Recommended Approach
   [Chosen direction and why]

   ### Intent Contract
   - Intent: [What must be true after shipping]
   - Success Conditions: [Measurable outcomes]
   - Hard Boundaries: [What must never change]
   - Non-Goals: [Explicitly out of scope]

   ### Acceptance Criteria
   - [ ] [test] Given [precondition], when [action], then [expected assertion in tests]
   - [ ] [command] Given [precondition], when `[shell command]`, then [expected output]
   - [ ] [behavioral] Given [precondition], when [user action], then [observable behavior]

   ### User Stories
   - As [persona], I want [action] so that [value]

   ### Success Metrics
   | Metric | Target | How Measured |

   ### Non-Goals
   - [What we're NOT building]

   ### Boundaries
   - Do NOT modify [X]

   ### Verification
   [commands to verify the implementation works]

   ### Open Questions for Architect
   [Technical unknowns surfaced during exploration]

   ### PR Intent Reference
   - Every implementation PR must link this issue and include an "Intent Reference" section.

   ## Flow
   [Mermaid diagram — flowchart LR for user journeys, flowchart TD for decision trees, sequenceDiagram for integrations]
   ```

### Phase 3: Technical Exploration

1. **Absorb** — Read locked product spec, investigate codebase, research patterns.

   | Agent | Focus |
   |-------|-------|
   | Codebase explorer | Existing patterns, touch points, docs/context + CODEBASE_MAP context |
   | Web researcher | Best practices, framework docs, how others solve this |
   | Cross-repo investigator | Prior art in org repos, shared patterns |

2. **Explore** — Generate 3-5 technical approaches. For each:
   - Architecture sketch (components, data flow, interfaces)
   - Files to modify/create
   - Pattern alignment with existing codebase
   - Tradeoffs (complexity, performance, maintainability, deletability)
   - Effort estimate: S/M/L/XL

   **Recommend one.** Present all with clear reasoning.

3. **Discuss** — User pushes back, questions, proposes alternatives.
   No limit on rounds. Design isn't ready until user says it is.

4. **Draft design** — Post on issue:

   ```markdown
   ## Technical Design

   ### Approach
   [Strategy and key decisions — 1-2 paragraphs]

   ### Files to Modify/Create
   - `path/file.ts` — [what changes]

   ### Interfaces
   [Key types, APIs, data structures — actual code blocks]

   ### Implementation Sequence
   1. [First chunk]
   2. [Second chunk]

   ### Testing Strategy
   [What to test, how, which patterns]

   ### Risks & Mitigations
   [Technical risks and how to handle them]

   ## Components
   [Mermaid graph TD — always required]

   ## Sequence
   [Mermaid sequenceDiagram — when async/API/multi-step flows involved]
   ```

### The Interweaving

Key difference from running spec then architect sequentially:

During technical exploration, product decisions can be revisited.
"This architecture would be simpler if we scoped the feature differently"
-> return to product discussion -> refine -> continue.

The skill explicitly allows looping back. Technical constraints inform product
decisions and vice versa. No phase is final until everything is locked.

### Phase 4: Synthesis

Once both product and technical directions are locked:

1. **Verify alignment** — Do spec and design tell a coherent story?
2. **Break down** — If scope warrants, yield multiple atomic issues
3. **Enrich each issue** — Product spec + technical design on every issue
4. **Apply standards** — Labels, milestones, org-wide standards (see `groom/references/org-standards.md`)
5. **Signal readiness** — `status/ready` for `/build` or `/autopilot`
6. **Stress-test** — Run critique (see `references/critique-personas.md`) to find gaps
7. **Prefer probe issues first** — if uncertainty remains high, create a cheap experiment issue before the full build issue

Post spec + design as comments on each issue.

### Optional: Implementation Plan

If the user wants detailed implementation planning:

1. Write plan to `docs/plans/YYYY-MM-DD-<feature>.md`
2. See `references/writing-plans.md` for the full procedure

## Shape Up Methodology

For formal Shape Up methodology (requirements/shapes notation, fit checks,
breadboarding, slicing), see:
- `references/shaping-methodology.md` — R/S notation, fit checks, phases
- `references/breadboarding.md` — Affordance mapping and vertical slicing

## Agent Teams Mode

For ambitious ideas (multiple issues expected):

| Teammate | Role |
|----------|------|
| Product explorer | Product exploration for the idea |
| Technical explorer | Architecture exploration in parallel |
| Research agent | Best practices, competitive analysis |

Lead synthesizes and presents unified view. User steers both product and
technical directions simultaneously rather than sequentially.

Use when: large feature, greenfield module, multiple valid approaches.
Don't use when: small idea, clear direction, single issue output.

## Principles

- Minimize touch points (fewer files = less risk)
- Design for deletion (easy to remove later)
- Favor existing patterns over novel ones
- YAGNI ruthlessly — remove unnecessary features from all designs
- One question at a time — don't overwhelm the user
- Explore alternatives — always propose 2-3 approaches before settling
- Incremental validation — present design, get approval before moving on

## Completion

"Shape complete. {N} issue(s) ready for `/build` or `/autopilot`."

List issues with links. Summarize: product direction, technical approach,
implementation sequence, estimated effort.
