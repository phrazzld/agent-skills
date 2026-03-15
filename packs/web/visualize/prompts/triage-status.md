---
description: Render /triage output as a multi-source status dashboard with severity breakdown, health sparklines, and action items
source_skill: /triage
---

# Triage Status

## Purpose

Transforms a triage report (aggregating signals from Sentry, Vercel, PostHog, and other monitoring sources) into a unified status dashboard. Gives a single-glance view of system health across all observed services.

## Content Sections

1. **System health summary** — hero-depth section with:
   - Overall status verdict (healthy / degraded / critical) as a large status badge
   - One-sentence summary of the current state
   - Triage timestamp
   - Use elevated styling. Green/amber/red background tint matching overall status.

2. **Multi-source status grid** — a card grid with one card per monitored source:
   - Source name (Sentry, Vercel, PostHog, GitHub Actions, etc.) as section label with colored dot
   - Status badge (healthy / degraded / down)
   - Key metric (error rate, p95 latency, uptime %, etc.) as a hero number
   - Sparkline showing recent trend (pure SVG polyline, see css-patterns.md)
   - Last checked timestamp
   - Use the card grid pattern with colored accent borders. Green for healthy, orange for degraded, red for down.

3. **Severity breakdown** — KPI summary row showing:
   - P0 (critical) count, red
   - P1 (high) count, orange
   - P2 (medium) count, yellow/amber
   - Total active incidents
   - Use the `kpi-card` pattern

4. **Active incidents table** — data table of current issues:
   - Source (which service)
   - Issue title or error message
   - Severity (P0/P1/P2) as status badge
   - First seen / last seen
   - Event count or frequency
   - Status (new / investigating / mitigated)
   - Sort by severity, then by event count

5. **Health sparklines panel** — a compact grid showing trend lines per service:
   - Service name
   - 24h or 7d sparkline (pure SVG)
   - Current value vs baseline
   - Trend direction indicator (up/down arrow with color)
   - Use a compact layout — this is supplementary detail, not the main view

6. **Active incidents timeline** — a vertical timeline showing recent incidents chronologically:
   - Timestamp
   - Service affected
   - Incident description
   - Current status
   - Use flow arrows between entries with colored dot labels per service

7. **Action items table** — prioritized next steps:
   - Action description
   - Priority (P0/P1/P2)
   - Owner (team or person if known)
   - Related incident reference
   - Status (pending / in-progress / done) as status badges
   - Use the `data-table` pattern, compact

## Reference Templates

- `~/.claude/skills/visualize/templates/data-table.html` — for tables, KPI cards, status badges
- `~/.claude/skills/visualize/templates/architecture.html` — for card grids, section color variants, flow arrows

## CSS Patterns

- **KPI / Metric Cards** — for severity breakdown and hero numbers in source cards
- **Data Tables** — for incidents table and action items
- **Status Indicators** — for severity and status badges throughout
- **Section / Node Cards** — hero for overall status, elevated for source cards, default for tables
- **Sparklines and Simple Charts** — SVG polylines for health trends
- **Connectors** — vertical flow arrows for incident timeline
- **Badges and Tags** — for source labels and priority tags
- **Background Atmosphere** — gradient mesh. Tint the atmosphere color to match overall status (greenish if healthy, warm if degraded, reddish if critical)
- **Animations** — `fadeScale` for KPIs and source cards, `fadeUp` for table rows

## Output

`~/.agent/diagrams/triage-{project}-{timestamp}.html`
