---
description: Render /pr-fix review output as a visual code review report with severity-organized findings, file heatmap, and reviewer breakdown
source_skill: /pr-fix
---

# Review Findings

## Purpose

Transforms a branch code review into a visual report organized by severity and reviewer perspective. Makes it easy to triage review findings: what must be fixed before merge, what should be addressed, and what is informational.

## Content Sections

1. **Review summary** — hero-depth section with:
   - Branch name and target branch as the page title (e.g., "feat/auth-flow -> main")
   - One-paragraph summary of what the changes do and the overall review verdict
   - Review date and scope (files reviewed, lines changed)
   - Use elevated styling

2. **KPI summary row** — top-level metrics:
   - Total issues found
   - Critical count (red)
   - Warning count (orange)
   - Info count (blue)
   - Files reviewed
   - Use the `kpi-card` pattern with `fadeScale` animation

3. **Findings table** — the main data table organized by severity:
   - Severity (critical / warning / info) as status badges with dot indicators
   - Category (security, performance, architecture, correctness, style)
   - Finding description
   - File and line reference (monospace)
   - Reviewer agent (which perspective caught it: security-sentinel, perf, arch, etc.)
   - Resolution status (open / fixed / wontfix) as status badges
   - Sort by severity (critical first), then by category within severity

4. **File impact heatmap** — a visual showing change density per file:
   - File path
   - Lines changed (as a horizontal bar or numeric value)
   - Issues found in that file (count, color-coded by max severity)
   - Use a compact data table with inline progress bars or sparklines for change density
   - Files with the most issues should visually stand out

5. **Reviewer breakdown cards** — one card per reviewer agent/perspective:
   - Reviewer name (Security, Performance, Architecture, Correctness, etc.)
   - Issue count found by this reviewer
   - Top finding summary
   - Severity distribution (mini count badges)
   - Use the card grid pattern with colored accent borders per reviewer

6. **Resolution tracking** — summary of which findings have been addressed:
   - Total open vs fixed vs wontfix
   - Progress bar showing resolution percentage
   - Remaining critical items highlighted
   - Use a compact section, collapsible if all items are resolved

7. **Detailed findings** — collapsible section with full details per finding:
   - Grouped by reviewer agent
   - Each finding as a callout card with colored left border (red=critical, orange=warning, blue=info)
   - Code context or snippet if relevant
   - Suggested fix

## Reference Templates

- `~/.claude/skills/visualize/templates/data-table.html` — primary reference for table styling, KPI cards, status badges
- `~/.claude/skills/visualize/templates/architecture.html` — for card grids, section color variants

## CSS Patterns

- **Data Tables** — for findings table and file heatmap
- **KPI / Metric Cards** — for summary row
- **Status Indicators** — for severity badges and resolution status
- **Section / Node Cards** — hero for summary, default for reviewer cards
- **Badges and Tags** — for category labels
- **Sparklines and Simple Charts** — for file change density bars
- **Collapsible Sections** — for detailed findings and resolution tracking
- **Background Atmosphere** — subtle radial glow
- **Animations** — `fadeScale` for KPIs, staggered `fadeUp` for table rows

## Output

`~/.agent/diagrams/review-{project}-{timestamp}.html`
