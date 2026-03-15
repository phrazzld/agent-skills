---
description: Render /shape output as a combined product + technical plan with issue breakdown, dependency graph, and implementation timeline
source_skill: /shape
---

# Shape Plan

## Purpose

Transforms a shaped plan (product + technical spec combined) into a visual that shows what gets built, in what order, with what dependencies. Bridges the gap between product thinking and implementation logistics.

## Content Sections

1. **Plan overview** — hero-depth section with:
   - Project or feature name as the page title
   - One-paragraph summary bridging the product goal and the technical approach
   - Scope statement: what ships in this batch
   - Use elevated styling with accent-tinted background

2. **Issue breakdown table** — the main data table with columns:
   - Issue title
   - Type (feature / task / bug / chore) as colored tags
   - Labels (area tags, e.g., frontend, api, infra)
   - Estimate (points or T-shirt size) as small tags
   - Dependencies (references to other issue titles or numbers)
   - Status (ready / blocked / in-progress) as status badges
   - Sort by implementation sequence. Group by milestone or batch if applicable.

3. **Dependency graph** — Mermaid flowchart showing issue dependencies:
   - Each node is an issue (short title)
   - Edges show "blocks" relationships
   - Critical path highlighted with thick edges (`==>`)
   - Blocked issues styled distinctly (e.g., dashed border via classDef)
   - Wrap in `.mermaid-wrap` with zoom controls
   - Use `graph LR` for timeline-like left-to-right flow

4. **Risk assessment cards** — a card grid (2-3 columns) for identified risks:
   - Risk description
   - Likelihood (low/medium/high as colored badge)
   - Impact (low/medium/high as colored badge)
   - Mitigation strategy
   - Use color-coded left borders: red for high-risk, orange for medium, green for low

5. **Implementation sequence timeline** — a styled vertical timeline showing the build order:
   - Phase or batch number
   - Issues included in that phase
   - Key milestone or deliverable at each phase
   - Dependencies resolved at each transition
   - Use the `pipeline` pattern oriented vertically, or a custom timeline with flow arrows between phases

6. **Acceptance criteria summary** — collapsible section listing all acceptance criteria grouped by issue. Use checkbox-style list items.

## Reference Templates

- `~/.claude/skills/visualize/templates/architecture.html` — for section cards, inner grids, flow arrows, pipeline pattern
- `~/.claude/skills/visualize/templates/data-table.html` — for issue breakdown table, status badges, KPI cards
- `~/.claude/skills/visualize/templates/mermaid-flowchart.html` — for dependency graph with zoom controls

## CSS Patterns

- **Data Tables** — for issue breakdown (primary data surface)
- **Mermaid Zoom Controls** — for dependency graph
- **Section / Node Cards** — hero depth for overview, default for risk cards
- **Status Indicators** — for issue status and risk levels
- **Badges and Tags** — for type labels, area labels, estimates
- **Pipeline** — adapted vertically for implementation timeline
- **Connectors** — flow arrows between timeline phases
- **Collapsible Sections** — for acceptance criteria
- **Background Atmosphere** — gradient mesh

## Output

`~/.agent/diagrams/shape-{project}-{timestamp}.html`
