---
description: Render /done session retrospective as a visual report with learnings table, codification targets, and time allocation
source_skill: /done
---

# Done Retrospective

## Purpose

Transforms a session retrospective into a visual report capturing what was learned, what was codified, and what artifacts were produced. Designed for future-you: when you revisit this session, the visual should reconstruct your mental state and key decisions.

## Content Sections

1. **Session summary** — hero-depth section with:
   - Session date and duration (or "started at X") as the page title
   - One-paragraph summary of what was accomplished and the session's overall arc
   - Key outcome or deliverable
   - Use elevated styling

2. **Learnings table** — the main data table with columns:
   - Learning (what was discovered or confirmed)
   - Category (bug-fix, architecture, workflow, tooling, domain-knowledge) as colored tags
   - Source (conversation, code, debugging, research)
   - Codified? (yes/no as green/amber badge — was it written to a persistent location?)
   - Impact (how this changes future behavior)
   - Sort by category, then by impact

3. **Codification targets** — a card grid showing what was persisted:
   - Target type (hook / skill / agent / CLAUDE.md / memory) as section label with colored dot
   - Description of what was saved
   - File path (monospace)
   - Status (written / pending / skipped) as status badge
   - Use different color variants per target type
   - This section answers: "what will future sessions benefit from?"

4. **Artifacts created** — a compact data table listing session outputs:
   - Artifact name
   - Type (file / commit / PR / diagram / config) as colored tag
   - Path or reference
   - Brief description
   - Collapsible if more than 10 items

5. **Before / after comparison** — if the session changed something measurably:
   - Use the `diff-panels` pattern
   - Before state (left, red-tinted header)
   - After state (right, green-tinted header)
   - Key metrics or behaviors that changed
   - Skip this section if no meaningful before/after comparison exists

6. **Time allocation breakdown** — visual showing how session time was spent:
   - Categories: investigation, implementation, testing, debugging, review, planning, documentation
   - Rendered as a horizontal stacked bar or a set of proportional cards
   - Use colored segments matching category. Pure CSS/SVG, no Chart.js needed.
   - Approximate is fine — exact timekeeping isn't expected

7. **Key decisions and rationale** — a list of significant decisions made during the session:
   - Decision statement
   - Rationale (why this choice)
   - Alternatives considered (if any)
   - Confidence level (high/medium/low) with colored left border (green/blue/amber)
   - Use callout cards styled like the decision log from diff-review

8. **Carryover** — collapsible section listing anything not finished:
   - Task description
   - Current state
   - Suggested next step
   - Use amber-tinted callout cards

## Reference Templates

- `~/.claude/skills/visualize/templates/data-table.html` — for learnings table, artifacts table, status badges
- `~/.claude/skills/visualize/templates/architecture.html` — for card grids, section color variants, callout cards

## CSS Patterns

- **Data Tables** — for learnings and artifacts tables
- **Section / Node Cards** — hero for summary, elevated for codification cards, default for decisions
- **Status Indicators** — for codification status and confidence levels
- **Badges and Tags** — for category labels and artifact types
- **Before / After Panels** — for before/after comparison
- **Collapsible Sections** — for artifacts and carryover
- **Sparklines and Simple Charts** — for time allocation bar (horizontal stacked bar via inline SVG or CSS widths)
- **Background Atmosphere** — warm gradient mesh, reflective/retrospective tone
- **Animations** — `fadeUp` for sections, `fadeScale` for codification cards

## Output

`~/.agent/diagrams/done-{project}-{timestamp}.html`
