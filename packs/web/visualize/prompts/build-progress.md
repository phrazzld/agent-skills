---
description: Render /build output as a visual build report with delegation timeline, test results, and file change map
source_skill: /build
---

# Build Progress

## Purpose

Transforms a build session report into a visual showing what was delegated, what passed, what failed, and what files were touched. Captures the full lifecycle of a multi-agent or multi-step build process.

## Content Sections

1. **Build summary** — hero-depth section with:
   - Build scope as the page title (feature name or task description)
   - One-paragraph summary of what was built and the overall result
   - Build status badge (success / partial / failed)
   - Use elevated styling. Green tint for success, amber for partial, red for failed.

2. **KPI summary row** — top-level build metrics:
   - Tasks completed (count)
   - Tests passed / total
   - Files touched (count)
   - Build duration (if available)
   - Use the `kpi-card` pattern with color coding (green for all pass, amber for partial, red for failures)

3. **Delegation batch timeline** — a vertical or horizontal timeline showing the build phases:
   - Each batch: which tasks were delegated to which agent (Codex, Claude, etc.)
   - Task description
   - Agent name as a colored tag
   - Result status (success / failed / skipped) as status badge
   - Duration per batch if available
   - Use the `pipeline` pattern for simple linear builds, or a vertical timeline with flow arrows for complex multi-agent builds
   - This is the visual anchor — shows the orchestration story

4. **Test results dashboard** — structured display of test outcomes:
   - Pass / fail / skip counts as KPI cards (green / red / amber)
   - Failing test names and error summaries in a data table
   - Test file paths in monospace
   - If all tests pass, show a simple success card instead of a full table
   - Collapsible test detail section for large test suites

5. **Files touched map** — data table showing all files changed during the build:
   - File path
   - Change type (created / modified / deleted) as status badges (green / orange / red)
   - Lines changed (if available)
   - Which build task touched this file
   - Group by directory. Collapsible via `<details>` if more than 20 files.

6. **Build verification checklist** — a styled checklist of verification steps:
   - Type check passed
   - Lint passed
   - Tests passed
   - Build succeeded
   - Each item with a green check or red X indicator
   - Use a compact card with a list inside

7. **Commit history** — if the build produced commits, list them:
   - Commit hash (short, monospace)
   - Commit message
   - Files in commit
   - Use a compact data table or styled list. Collapsible.

## Reference Templates

- `~/.claude/skills/visualize/templates/architecture.html` — for pipeline pattern, flow arrows, section cards
- `~/.claude/skills/visualize/templates/data-table.html` — for tables, KPI cards, status badges
- `~/.claude/skills/visualize/templates/mermaid-flowchart.html` — optional for complex delegation graphs

## CSS Patterns

- **Pipeline** — for delegation timeline (horizontal or vertical)
- **KPI / Metric Cards** — for build metrics and test counts
- **Data Tables** — for test failures, file map, commit history
- **Status Indicators** — for pass/fail/skip badges and change type badges
- **Section / Node Cards** — hero for summary, default for verification checklist
- **Badges and Tags** — for agent name tags
- **Connectors** — flow arrows between delegation phases
- **Collapsible Sections** — for file map, test details, commit history
- **Background Atmosphere** — radial glow, tinted to match build outcome
- **Animations** — staggered `fadeUp` for timeline entries

## Output

`~/.agent/diagrams/build-{project}-{timestamp}.html`
