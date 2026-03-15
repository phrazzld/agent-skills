---
description: Render /shape --spec-only output as a visual feature specification with user journey, approach comparison, and success metrics
source_skill: /shape
---

# Spec Overview

## Purpose

Transforms a feature specification into a visual overview that communicates the what, why, and how of a planned feature. Focuses on user impact, scope boundaries, and measurable success criteria.

## Content Sections

1. **Feature summary** — hero-depth section with:
   - Feature name as the page title
   - One-paragraph description of what this feature does and why it matters
   - Target user/persona
   - Link to issue or source document if available
   - Use elevated styling with accent-tinted background

2. **User journey flow** — a Mermaid flowchart showing the user's path through the feature:
   - Entry points (how the user arrives)
   - Key interaction steps
   - Decision branches
   - Success and error endpoints
   - Wrap in `.mermaid-wrap` with zoom controls. Use `graph LR` or `graph TD` depending on flow complexity.

3. **Approach comparison** — if the spec explored multiple approaches, render a comparison table:
   - Approach name
   - Pros (green-tinted)
   - Cons (red-tinted)
   - Effort estimate
   - Selected approach highlighted with a status badge or accent border
   - If only one approach, skip this section

4. **Feature breakdown cards** — a card grid showing each sub-feature or component:
   - Component name as section label
   - Brief description
   - Acceptance criteria as a checklist (styled list with check/empty markers)
   - Dependencies on other components
   - Use the `inner-grid` or `three-col` pattern with colored accent borders

5. **Success metrics dashboard** — KPI-style cards for each measurable outcome:
   - Metric name
   - Target value (large hero number)
   - Current baseline (if known)
   - Measurement method (small text below)
   - Use the `kpi-card` pattern

6. **Scope boundary** — two-column layout:
   - **In scope** (green-tinted left border): bullet list of what this feature covers
   - **Out of scope** (red-tinted left border): bullet list of explicitly excluded items
   - Use the `diff-panels` or side-by-side comparison pattern

7. **Open questions** — if the spec has unresolved questions, render as amber-tinted callout cards. Collapsible if more than 3.

## Reference Templates

- `~/.claude/skills/visualize/templates/architecture.html` — for card grids, flow arrows, section layout, color variants
- `~/.claude/skills/visualize/templates/mermaid-flowchart.html` — for user journey Mermaid diagram with zoom controls
- `~/.claude/skills/visualize/templates/data-table.html` — for comparison table and KPI cards

## CSS Patterns

- **Section / Node Cards** — hero depth for summary, default for feature cards
- **Grid Layouts** — card grid for feature breakdown, comparison panels for scope
- **Mermaid Zoom Controls** — for user journey flowchart
- **KPI / Metric Cards** — for success metrics
- **Before / After Panels** — adapted for in-scope/out-of-scope
- **Status Indicators** — for selected approach badge
- **Collapsible Sections** — for open questions
- **Background Atmosphere** — radial glow behind the hero section

## GitHub-Ready Blocks

At the bottom of the generated HTML, include a `<section class="github-ready">` section:

```html
<section class="github-ready">
  <h2>GitHub-Ready Blocks</h2>
  <p>Copy-paste into GitHub issues/PR comments:</p>
  <pre><code>## Flow

```mermaid
flowchart LR
    [user journey diagram reflecting this spec's primary flow]
```</code></pre>
</section>
```

Generate the actual Mermaid source from the spec content — not a placeholder. This block should be copy-paste ready for posting to a GitHub issue comment.

## Output

`~/.agent/diagrams/spec-{project}-{timestamp}.html`
