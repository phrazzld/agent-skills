# Synthesis Workflow

Use this reference once directions are locked. This is where `/groom` turns
exploration into a reduced, coherent backlog.

## Phase 5: Synthesis

### Step 1: Reduce Before Create

Reduce the backlog before creating anything new.

Use six buckets:
- **Keep** — current, high-leverage, aligned with locked themes, scores >= 70
- **Merge** — overlapping issues collapsed into one canonical issue
- **Demote** — valid idea, but outside the active window → move to `.groom/BACKLOG.md`
- **Close** — stale, duplicate, vague, obsolete, or better captured elsewhere
- **Redundant** — proposes building what an existing platform feature, integration, or CLI already handles. Close with an explanation of the existing solution (e.g., "Sentry already files issues for this", "GitHub Actions handles this natively")
- **Promote** — idea from `.groom/BACKLOG.md` that now warrants an active issue

Guidance:
- prefer one deep canonical issue over several shallow siblings
- screenshot-only or vibe-only issues are not backlog-ready; rewrite or demote
- refactor issues without clear strategic leverage usually merge into a parent
- future ideas without active priority → demote to BACKLOG.md, not open issues
- **hard cap: 20-30 open issues.** If over, demote lowest-priority until under cap

Present the reduction proposal before creating net-new issues:

```markdown
## Backlog Reduction Proposal

### Keep (N issues)
- #N — why it survives

### Merge
- #N + #N -> #N canonical issue

### Demote to BACKLOG.md
- #N — "reason" (will close issue, add entry to BACKLOG.md)

### Close
- #N — why it leaves entirely

### Promote from BACKLOG.md
- "idea title" — why it's now active (will create issue, remove from BACKLOG.md)
```

**Post-reduction invariant:** GitHub backlog has 20-30 issues, all scoring >= 70.
Every deferred idea has a home in `.groom/BACKLOG.md`, not lost.

### Step 1b: Update BACKLOG.md

After the reduction proposal is approved:

1. **Demoted issues** → close on GitHub with comment "Moved to .groom/BACKLOG.md", add entry to BACKLOG.md with original issue context
2. **Promoted ideas** → remove from BACKLOG.md (they'll become issues in Step 2)
3. **Stale BACKLOG.md entries** → review and prune ideas that are no longer relevant
4. **New ideas from session** → add to BACKLOG.md if not making the active cut

BACKLOG.md format:

```markdown
# Backlog Ideas

Last groomed: {date}

## High Potential (promote next session if capacity)
- **idea title** — one-line context. Source: #{issue} / user / audit / thinktank.
- ...

## Someday / Maybe
- **idea title** — one-line context. Source: ...
- ...

## Research Prompts
- **question** — what we'd need to learn before this becomes actionable
- ...

## Archived This Session
- ~~idea title~~ — why removed (done, obsolete, absorbed into #N)
```

### Step 2: Create Issues Only For Missing Strategic Gaps

Create issues only when they fill a real gap in the reduced roadmap.
Check `.groom/BACKLOG.md` "High Potential" section first — promote before inventing.

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

GitHub Backlog:
  Before: N open → After: N open (cap: 20-30)
  Demoted to BACKLOG.md: N
  Promoted from BACKLOG.md: N
  Merged: N
  Closed: N

BACKLOG.md:
  High Potential: N ideas
  Someday/Maybe: N ideas
  Archived this session: N

Issues by Priority:
- P0 (Critical): N
- P1 (Essential): N
- P2 (Important): N
- P3 (Nice to Have): N

Readiness Scores:
- All issues scored >= 70 ✓ (REQUIRED)
- Excellent (90-100): N
- Good (70-89): N

Recommended Execution Order:
1. [P0] ...
2. [P1] ...

Ready for /autopilot: [issue numbers]
View all: gh issue list --state open
```

Add one verdict:
- `Backlog is focused` (20-30 issues, 100% groomed)
- `Backlog over cap` (>30 — needs another slash pass)
- `BACKLOG.md needs triage` (too many High Potential items without clear priority)

## Phase 6: Plan Artifact

Write `.groom/plan-{date}.md`:

```markdown
# Grooming Plan — {date}

## Themes Explored
- [theme]: [direction locked]

## Issues Created
- #N: [title] (score: X/100)

## Reduced / Closed / Merged / Demoted
- keep: [list]
- merged: [list]
- demoted to BACKLOG.md: [list]
- closed: [list]
- promoted from BACKLOG.md: [list]

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
