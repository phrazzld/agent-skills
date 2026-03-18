---
name: shape
description: |
  Shape a raw idea into something buildable. Product + technical exploration
  in one interactive session. Spec, design, critique, plan.
  Use when: "shape this", "write a spec", "design this feature",
  "plan this", "spec out", "technical design", "product exploration".
  Trigger: /shape, /spec, /plan.
argument-hint: "[idea|issue] [--spec-only] [--design-only] [--critique persona] [--plan]"
---

# /shape

## Routing

| Mode | When | Reference |
|------|------|-----------|
| **Full** (default) | Interactive product + technical exploration | Core workflow below |
| `--spec-only` | Product exploration only (WHAT and WHY) | — |
| `--design-only` | Technical exploration only (HOW). Needs existing spec. | — |
| `--critique <persona>` | Adversarial expert review | `references/critique-personas.md` |
| `--plan` | Implementation plan from existing spec+design | `references/writing-plans.md` |
| Shape Up methodology | R/S notation, fit checks, spikes, slicing | `references/shaping-methodology.md` |
| Breadboarding | Affordance mapping, vertical slicing | `references/breadboarding.md` |

## Workflow

### Phase 1: Understand

Accept: raw idea (string), issue ID, or observation.

1. If no issue exists → create skeleton immediately
2. If issue exists → `gh issue view $1 --comments`
3. Read codebase context — adjacent features, existing patterns, constraints

**All web research MUST use `/research`** (routes through Exa for code context).

### Phase 2: Product Exploration

**GATE: Do NOT write any code or take implementation actions until product direction is locked.**

1. **Investigate** — Problem space, user impact, prior art.

2. **Brainstorm** — 2-3 product approaches with tradeoffs. For each:
   - Concrete interaction flow (what the user experiences)
   - Value delivered, scope (S/M/L), downstream enablement
   - **Recommend one.** Lead with recommendation.

3. **Discuss** — One question at a time. Multiple choice preferred.
   Iterate until product direction is locked.

4. **Cheapest test** — If uncertainty is real, define the fastest experiment
   that would change the decision. Prefer probes over speculation.

5. **Draft spec** — Post on issue:

   ```markdown
   ## Product Spec

   ### Problem
   [2-3 sentences]

   ### Intent Contract
   - Intent: [What must be true after shipping]
   - Success Conditions: [Measurable outcomes]
   - Hard Boundaries: [What must never change]
   - Non-Goals: [Explicitly out of scope]

   ### Acceptance Criteria
   - [ ] Given [precondition], when [action], then [expected]

   ### Open Questions for Architect
   [Technical unknowns]
   ```

### Phase 3: Technical Exploration

1. **Investigate** — Read locked spec, codebase, research patterns.

2. **Explore** — 3-5 technical approaches. For each:
   - Architecture sketch, files to modify/create
   - Pattern alignment with existing codebase
   - Tradeoffs (complexity, performance, deletability)
   - Effort: S/M/L/XL
   - **Recommend one.**

3. **Validate** — For effort M or larger:
   - Run `/research thinktank` with design + spec + codebase context
   - Spawn the Triad for design review:

   | Agent | Focus |
   |-------|-------|
   | `ousterhout` | Deep modules? Information hidden? |
   | `carmack` | Simplest thing that works? |
   | `grug` | Too many layers? |

4. **Discuss** — No limit on rounds. Design isn't ready until user says so.

5. **Draft design** — Post on issue:

   ```markdown
   ## Technical Design

   ### Approach
   [Strategy and key decisions]

   ### Files to Modify/Create
   - `path/file.ts` — [what changes]

   ### Implementation Sequence
   1. [First chunk]
   2. [Second chunk]

   ### Risks & Mitigations
   [Technical risks]
   ```

### The Interweaving

During technical exploration, product decisions can be revisited.
"This architecture would be simpler if we scoped differently" →
return to product discussion → refine → continue.

No phase is final until everything is locked.

### Phase 4: Synthesis

1. Verify alignment — do spec and design tell a coherent story?
2. Break down — if scope warrants, yield multiple atomic issues
3. Stress-test — run critique (`references/critique-personas.md`)
4. Prefer probe issues first if uncertainty remains high
5. Signal readiness — `status/ready` for `/build` or `/autopilot`

## Effort Calibration

When scoping, show both scales:

| Task type | Human team | Agent | Compression |
|-----------|-----------|-------|-------------|
| Scaffolding | 2 days | 15 min | ~100x |
| Tests | 1 day | 15 min | ~50x |
| Feature implementation | 1 week | 30 min | ~30x |
| Bug fix + regression | 4 hours | 15 min | ~20x |
| Architecture / design | 2 days | 4 hours | ~5x |

Use this to calibrate "is this worth splitting?" A feature that takes a human
team a week is 30 minutes of agent time — probably one issue, not three.

## Completeness Principle

AI makes the marginal cost of completeness near-zero. When presenting options:

- If Option A is complete (all edge cases, full coverage) and Option B saves
  modest effort — **recommend A.** The delta between 80 and 150 lines is noise.
- **Lake vs ocean:** A lake is boilable (100% coverage for a module, full feature).
  An ocean is not (rewrite entire system, multi-quarter migration).
  Recommend boiling lakes. Flag oceans as out of scope.

## Principles

- Minimize touch points (fewer files = less risk)
- Design for deletion (easy to remove later)
- Favor existing patterns over novel ones
- YAGNI ruthlessly
- One question at a time — don't overwhelm
- Explore alternatives — always 2-3+ before settling

## Completion

"Shape complete. {N} issue(s) ready for `/build` or `/autopilot`."
