---
description: Render /groom audit findings as a visual dashboard with priority heatmap, domain grid, and recommendations table
source_skill: /groom
---

# Groom Dashboard

## Purpose

Transforms a codebase grooming audit into a scannable visual dashboard. The audit covers multiple domains (Frontend, Backend, Infrastructure, Testing, Security, etc.) with findings rated by priority. The visual makes it easy to see where the biggest gaps are and what to fix first.

## Content Sections

1. **KPI summary row** — top-level numbers at hero depth:
   - Total findings count
   - Critical (P0) count, colored red
   - High (P1) count, colored orange
   - Coverage score (percentage of areas meeting standards)
   - Use the `kpi-card` pattern with `fadeScale` animation

2. **Priority heatmap** — a grid showing P0/P1/P2/P3 distribution across domains. Each cell is color-coded by severity (red P0, orange P1, yellow P2, green P3). Use the `inner-grid` pattern from the architecture template, with each cell containing a domain label and finding count. Empty cells (no findings) should be subtly styled to show the domain was audited but clean.

3. **Findings table** — the main data table with columns:
   - Domain (Frontend, Backend, etc.)
   - Finding (description of the issue)
   - Priority (P0/P1/P2/P3 as status badges)
   - Status (gap / partial / met as status badges using `status--gap`, `status--warn`, `status--match`)
   - Effort estimate (S/M/L/XL as small tags)
   - Group rows by domain using a subtle domain header row spanning all columns. Sort by priority within each domain.

4. **Domain breakdown cards** — a card grid (2-3 columns) with one card per audited domain. Each card shows:
   - Domain name as section label with colored dot
   - Mini bar or count of findings by priority
   - One-sentence summary of the domain's health
   - Use different color variants per domain (accent, green, orange, sage, teal, plum)

5. **Recommendations table** — prioritized action items derived from findings:
   - Action description
   - Priority (inherited from the finding)
   - Effort estimate
   - Expected impact (brief)
   - Use a compact data table, sorted by priority then effort. Collapsible via `<details>` if the page has many sections.

6. **Methodology note** — a recessed callout explaining what was audited and how (e.g., "Audited against project CLAUDE.md standards, language-specific best practices, and OWASP top 10"). Collapsible.

## Reference Templates

- `~/.claude/skills/visualize/templates/data-table.html` — primary reference for table styling, KPI cards, status badges, collapsible sections
- `~/.claude/skills/visualize/templates/architecture.html` — reference for inner-grid cards, section color variants, dot labels

## CSS Patterns

- **KPI / Metric Cards** — for the summary row
- **Data Tables** — for findings and recommendations tables
- **Status Indicators** — for priority and status badges
- **Section / Node Cards** — for domain breakdown cards (depth tiers: elevated for KPIs, default for tables, recessed for methodology)
- **Badges and Tags** — for effort estimate labels (S/M/L/XL)
- **Collapsible Sections** — for recommendations and methodology
- **Background Atmosphere** — gradient mesh with 2-3 positioned radials
- **Animations** — `fadeScale` for KPI cards, `fadeUp` for table rows with staggered `--i`

## GitHub-Ready Blocks

At the bottom of the generated HTML, include a `<section class="github-ready">` section:

```html
<section class="github-ready">
  <h2>GitHub-Ready Blocks</h2>
  <p>Copy-paste into GitHub issues/PR comments:</p>
  <pre><code>## Theme Relationships

```mermaid
graph LR
    [theme relationship diagram reflecting this groom session's strategic themes]
```</code></pre>
</section>
```

Generate actual Mermaid source from the session's strategic themes — not a placeholder. Show dependencies, shared components, and compounding effects between themes. This block should be copy-paste ready for posting as a synthesis message or issue comment on GitHub.

## Output

`~/.agent/diagrams/groom-{project}-{timestamp}.html`
