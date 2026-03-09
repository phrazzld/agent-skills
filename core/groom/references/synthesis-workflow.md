# Synthesis Workflow

Use this reference once directions are locked. This is where `/groom` turns
exploration into a reduced, coherent backlog.

## Phase 5: Synthesis

### Step 1: Reduce Before Create

Reduce the backlog before creating anything new.

Use four buckets:
- **Keep** — current, high-leverage, aligned with locked themes
- **Merge** — overlapping issues collapsed into one canonical issue
- **Defer** — valid, but outside the current strategic window
- **Close** — stale, duplicate, vague, obsolete, or better captured elsewhere

Guidance:
- prefer one deep canonical issue over several shallow siblings
- screenshot-only or vibe-only issues are not backlog-ready; rewrite or close
- refactor issues without clear strategic leverage usually merge into a parent
- future ideas without active priority usually move to docs/notes, not stay open

Present the reduction proposal before creating net-new issues:

```markdown
## Backlog Reduction Proposal

### Keep
- #N — why it survives

### Merge
- #N + #N -> #N canonical issue

### Defer
- #N — why later

### Close
- #N — why it leaves the backlog
```

The outcome should be a backlog that can be scanned in minutes and understood as the current roadmap.

### Step 2: Create Issues Only For Missing Strategic Gaps

Create issues only when they fill a real gap in the reduced roadmap.

Use the org-standards format:
- Problem
- Context
- Intent Contract
- Acceptance Criteria (`[test]`, `[command]`, `[behavioral]`)
- Affected Files
- Verification
- Boundaries
- Approach
- Overview

For domain-specific findings from `/audit --all`, use `/audit {domain} --issues`.

### Step 3: Quality Gate

Run `/issue lint` on every created issue.

- `>= 70`: pass
- `50-69`: run `/issue enrich`
- `< 50`: rewrite manually

No issue ships below 70.

### Step 4: Organize

Apply org-wide standards from `org-standards.md`:
- canonical labels
- issue type
- milestone assignment
- project linking

Close stale issues with user confirmation. Migrate legacy labels.

### Step 5: Deduplicate

Deduplicate across:
1. user observations vs automated findings
2. audit-created issues vs each other
3. new issues vs issues kept in the reduced set

Keep the strongest canonical issue. Close the rest with links.

### Step 6: Summarize

Use this summary shape:

```text
GROOM SUMMARY
=============

Themes Explored: [list]
Directions Locked: [list]
Backlog Before: N open
Backlog After: N open

Issues by Priority:
- P0 (Critical): N
- P1 (Essential): N
- P2 (Important): N
- P3 (Nice to Have): N

Readiness Scores:
- Excellent (90-100): N
- Good (70-89): N
- All issues scored >= 70 ✓

Recommended Execution Order:
1. [P0] ...
2. [P1] ...

Ready for /autopilot: [issue numbers]
View all: gh issue list --state open
```

Add one verdict:
- `Backlog is focused`
- `Backlog still too large`
- `Backlog reduced but needs one more slash pass`

## Phase 6: Plan Artifact

Write `.groom/plan-{date}.md`:

```markdown
# Grooming Plan — {date}

## Themes Explored
- [theme]: [direction locked]

## Issues Created
- #N: [title] (score: X/100)

## Reduced / Closed / Merged
- keep: [list]
- merged: [list]
- deferred: [list]
- closed: [list]

## Deferred
- [topic]: [why deferred, when to revisit]

## Research Findings
[Key findings from Phase 3 worth preserving]

## Retro Patterns Applied
[How past implementation feedback influenced this session's scoping]
```

This keeps a visible before/after record of backlog reduction, not just issue creation.

## Visual Deliverable

If the session is substantial, generate a visual HTML summary:
1. Read `~/.claude/skills/visualize/prompts/groom-dashboard.md`
2. Read the referenced template(s)
3. Read `~/.claude/skills/visualize/references/css-patterns.md`
4. Generate self-contained HTML
5. Write to `~/.agent/diagrams/groom-{repo}-{date}.html`
6. Open it
7. Tell the user the path

Skip when the session is trivial, the user opts out, or no browser is available.
