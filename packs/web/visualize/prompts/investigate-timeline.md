---
description: Render /investigate output as a visual investigation report with evidence timeline, hypothesis cards, and root cause analysis
source_skill: /investigate
---

# Investigate Timeline

## Purpose

Transforms an investigation report into a visual narrative showing the chain of evidence, hypothesis testing, and root cause analysis. Optimized for post-incident reviews and complex debugging sessions where the discovery sequence matters.

## Content Sections

1. **Investigation summary** — hero-depth section with:
   - Issue or incident title as the page title
   - One-paragraph summary: what was investigated, what was found, what the root cause is
   - Severity and impact scope
   - Resolution status (resolved / mitigated / open)
   - Use elevated styling with accent-tinted background

2. **Evidence timeline** — a vertical chronological timeline showing the discovery chain:
   - Each entry: timestamp or sequence number, evidence description, source (log, code, test, user report)
   - Key discoveries highlighted with accent border
   - Dead ends shown with muted/struck styling
   - Use flow arrows between entries. Each entry is a section card with a colored dot label indicating source type (code=teal, logs=orange, tests=green, external=plum).
   - This is the visual anchor — it tells the story of how understanding evolved

3. **Hypothesis status cards** — a card grid showing each hypothesis explored:
   - Hypothesis statement
   - Status badge: confirmed (green), rejected (red), open (amber)
   - Supporting evidence (brief, referencing timeline entries)
   - For rejected hypotheses: why it was ruled out
   - The confirmed hypothesis should be visually prominent (hero depth or accent border)
   - Rejected hypotheses should be visually recessed

4. **System dependency map** — Mermaid diagram showing the components related to the incident:
   - Affected components highlighted (accent or red styling)
   - Causal path shown with thick edges (`==>`)
   - Unaffected but investigated components shown with muted styling
   - Wrap in `.mermaid-wrap` with zoom controls

5. **Root cause analysis flow** — either a Mermaid flowchart or styled pipeline showing:
   - Symptom (what was observed)
   - Proximate cause (what directly caused the symptom)
   - Root cause (the underlying issue)
   - Contributing factors
   - Use flow arrows between levels, with each level as a section card. Red-to-orange-to-yellow gradient from symptom to root cause.

6. **Impact assessment** — KPI-style metrics:
   - Users affected (count or percentage)
   - Duration of impact
   - Services affected
   - Data integrity status
   - Use the `kpi-card` pattern with red/amber/green coloring based on severity

7. **Remediation** — collapsible section with:
   - Immediate fix applied
   - Long-term fix needed
   - Prevention measures (how to avoid recurrence)

## Reference Templates

- `~/.claude/skills/visualize/templates/architecture.html` — for section cards, flow arrows, inner grids, color variants
- `~/.claude/skills/visualize/templates/mermaid-flowchart.html` — for system dependency map with zoom controls
- `~/.claude/skills/visualize/templates/data-table.html` — for KPI cards, status badges

## CSS Patterns

- **Section / Node Cards** — hero for summary and confirmed hypothesis, default for timeline entries, recessed for rejected hypotheses
- **Connectors** — vertical flow arrows for evidence timeline and root cause flow
- **Status Indicators** — confirmed/rejected/open badges on hypothesis cards
- **Mermaid Zoom Controls** — for system dependency map
- **KPI / Metric Cards** — for impact assessment
- **Collapsible Sections** — for remediation details
- **Background Atmosphere** — asymmetric gradient mesh, darker/more dramatic than other prompts to match incident tone
- **Animations** — staggered `fadeUp` for timeline entries (tells the story sequentially)

## Output

`~/.agent/diagrams/investigate-{project}-{timestamp}.html`
