---
description: Render /shape --design-only output as a visual architecture diagram with component graph, data flow, file impact map, and tradeoffs
source_skill: /shape
---

# Architect Diagram

## Purpose

Transforms an architecture plan into a visual diagram showing how components connect, how data flows between them, which files are impacted, and how the chosen approach compares to alternatives.

## Content Sections

1. **Architecture summary** — hero-depth section with:
   - System or feature name as the page title
   - One-paragraph architectural intent: what problem this architecture solves and the core design principle
   - Key constraints that shaped the design
   - Use elevated styling, larger type (20-24px body text)

2. **Component architecture diagram** — Mermaid graph showing the component structure:
   - Use `graph TD` or `graph LR` depending on the system shape
   - Group related components in `subgraph` blocks
   - Label edges with the type of communication (HTTP, event, import, etc.)
   - Use `classDef` with semi-transparent fills for visual grouping (see libraries.md classDef rules)
   - Wrap in `.mermaid-wrap` with zoom controls
   - This is the visual anchor of the page — use hero depth on the container

3. **Data flow** — either a Mermaid sequence diagram or a styled pipeline showing how data moves through the system:
   - Entry point (user action, API call, event)
   - Transformation steps
   - Storage points
   - Output/response
   - Use the `pipeline` pattern from the architecture template for simple linear flows, or a Mermaid `sequenceDiagram` for complex multi-actor flows

4. **File impact map** — a data table showing which files change and how:
   - File path
   - Change type (new / modified / deleted) as status badges
   - Description of what changes in that file
   - Group by module or directory. Use the `data-table` pattern.
   - Collapsible via `<details>` if more than 15 files

5. **Approach tradeoffs table** — comparison of the chosen approach vs alternatives:
   - Approach name
   - Strengths (green text or badge)
   - Weaknesses (red text or badge)
   - Complexity rating
   - Chosen approach row highlighted with accent border or background
   - Use the `data-table` pattern with a highlighted row

6. **API surface / interface definitions** — if the architecture defines public APIs or interfaces:
   - Endpoint or function signature in monospace
   - Description
   - Input/output types
   - Use a compact table or styled code blocks within cards

7. **Dependency graph** — a Mermaid graph showing external and internal dependencies:
   - External services, packages, APIs as distinctly styled nodes
   - Internal modules as default nodes
   - Edges showing dependency direction
   - Wrap in `.mermaid-wrap` with zoom controls
   - Collapsible via `<details>` if the page is already diagram-heavy

## Reference Templates

- `~/.claude/skills/visualize/templates/architecture.html` — primary reference for section cards, inner grids, flow arrows, pipeline pattern, color variants
- `~/.claude/skills/visualize/templates/mermaid-flowchart.html` — for Mermaid diagrams with zoom controls, theming, ELK layout
- `~/.claude/skills/visualize/templates/data-table.html` — for file impact table and tradeoffs comparison

## CSS Patterns

- **Mermaid Zoom Controls** — for component diagram and dependency graph
- **Section / Node Cards** — hero depth for summary and main diagram, default for others
- **Pipeline** — for linear data flow visualization
- **Data Tables** — for file impact map and tradeoffs
- **Status Indicators** — for change type badges (new=green, modified=orange, deleted=red)
- **Collapsible Sections** — for file map and dependency graph when page is long
- **Background Atmosphere** — dot grid or gradient mesh
- **Animations** — staggered `fadeUp` for sections, draw-in for Mermaid

## GitHub-Ready Blocks

At the bottom of the generated HTML, include a `<section class="github-ready">` section with two blocks:

```html
<section class="github-ready">
  <h2>GitHub-Ready Blocks</h2>
  <p>Copy-paste into GitHub issues/PR comments:</p>
  <pre><code>## Components

```mermaid
graph TD
    [component diagram reflecting this architecture]
```

## Sequence

```mermaid
sequenceDiagram
    [sequence diagram for the primary async/API flow, if applicable]
```</code></pre>
</section>
```

Generate actual Mermaid source from the architecture content — not placeholders. Omit the Sequence block if the design has no async interactions or API calls. Both blocks should be copy-paste ready for posting to a GitHub issue comment.

## Output

`~/.agent/diagrams/architect-{project}-{timestamp}.html`
