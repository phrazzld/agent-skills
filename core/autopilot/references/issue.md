# /issue

Issue quality tooling. Three subcommands for different needs.

## Subcommands

### `/issue lint [#N|--all]`

Score issues against org-standards readiness rubric.

#### Process

1. Load `groom/references/org-standards.md` for scoring rubric
2. Fetch issue(s): `gh issue view N --json title,body,labels,milestone`
3. Score each section per rubric (0-100 total)
4. Classify findings as errors (blocking) or warnings (informational)
5. Report score and findings

#### Scoring Rubric

| Section | Points | Criteria |
|---------|--------|----------|
| **Acceptance Criteria** | 25 | 25: Given/When/Then with 2+ criteria. 15: checkboxes without GWT. 5: vague. 0: missing. |
| **Problem** | 20 | 20: specific with evidence. 10: clear but no evidence. 0: vague/missing. |
| **Affected Files** | 15 | 15: paths with descriptions. 8: paths only. 0: missing. |
| **Verification** | 15 | 15: executable commands. 8: described not executable. 0: missing. |
| **Labels** | 10 | 2 per required label (priority, type, horizon, effort, domain). |
| **Effort** | 5 | 5: effort label present. 0: missing. |
| **Diagram** | 5 | 5: appropriate. 3: wrong type. 0: missing (unless chore/dep bump). |
| **Milestone** | 5 | 5: assigned. 0: missing. |

#### Error Classification

**Errors** (block agent execution):
- Missing priority label
- No acceptance criteria (score 0)
- No problem statement (score 0)
- Missing affected files for code-change issues

**Warnings** (flag, don't block):
- No diagram (unless exempt)
- No effort label
- No verification commands
- No boundaries section
- Missing milestone

#### Output

```
ISSUE LINT: #42 "Add session token refresh"
Score: 78/100 (Good — ready for execution)

  Acceptance Criteria:  25/25 ✓
  Problem:              20/20 ✓
  Affected Files:       15/15 ✓
  Verification:          8/15 ⚠ described but not executable
  Labels:                6/10 ⚠ missing effort label
  Effort:                0/5  ⚠ no effort label
  Diagram:               0/5  ⚠ no diagram
  Milestone:             5/5  ✓

Errors: 0
Warnings: 3
  - verification: Add executable commands (pnpm test -- --grep "session")
  - labels: Add effort/s|m|l|xl label
  - diagram: Add flowchart for token refresh flow
```

#### `--all` mode

Lint all open issues. Output summary table:

```
BACKLOG LINT SUMMARY

Score | Status    | Issue
------|-----------|------
  92  | Excellent | #42 Add session token refresh
  78  | Good      | #38 Fix webhook retry logic
  45  | Needs work| #35 Improve error handling
  23  | Incomplete| #31 Make things better

Ready: 2 | Needs enrichment: 1 | Incomplete: 1
```

#### `--fix` mode

After linting, run `/issue enrich` on issues scoring < 70.

---

### `/issue enrich [#N]`

Fill missing issue sections using sub-agent research.

#### Process

1. Fetch issue: `gh issue view N --json title,body,labels,milestone`
2. Run `/issue lint N` to identify gaps
3. For each missing section, spawn appropriate sub-agent:

| Missing Section | Agent | Prompt |
|----------------|-------|--------|
| Affected Files | Codebase explorer | "Find files related to [issue topic]. Check docs/context/INDEX.md, docs/context/ROUTING.md, and CODEBASE_MAP.md." |
| Verification | Codebase explorer | "Find test commands and verification steps for [affected area]." |
| Acceptance Criteria | General-purpose | "Write Given/When/Then acceptance criteria for: [problem statement]" |
| Approach | Web researcher + codebase explorer | "Research best practices for [topic]. Find existing patterns in codebase." |
| Context | General-purpose | "Read project.md and summarize relevant vision/domain context for [issue]." |
| Diagram | General-purpose | "Generate appropriate Mermaid diagram for [issue type]: [summary]" |

4. Rewrite issue body with all sections populated
5. Apply missing labels
6. Re-run `/issue lint N` to confirm score >= 70

#### Issue Update

```bash
gh issue edit N --body "$(cat <<'EOF'
[enriched issue body]
EOF
)"
```

Add labels:
```bash
gh issue edit N --add-label "effort/m"
```

#### Output

```
ISSUE ENRICH: #35 "Improve error handling"
Before: 45/100 (Needs work)
After:  82/100 (Good)

Added:
  + Acceptance Criteria (Given/When/Then)
  + Affected Files (5 files identified)
  + Verification commands
  + Approach with code examples
  + Boundaries
  + effort/m label
```

---

### `/issue decompose [#N]`

Split oversized issues into atomic sub-issues.

#### When to Decompose

- Issue has `effort/xl` label
- Issue touches 5+ files across 3+ directories
- Issue has 5+ acceptance criteria spanning different concerns
- Issue mixes feature work with refactoring

#### Process

1. Fetch issue: `gh issue view N --comments`
2. Analyze scope: file count, directory spread, acceptance criteria clusters
3. Identify natural boundaries (by module, by concern, by dependency)
4. Create child issues, each:
   - References parent: "Part of #N"
   - Has own acceptance criteria (subset of parent)
   - Has own affected files (subset)
   - Has dependency links where order matters
   - Inherits parent's priority and domain labels
   - Gets appropriate effort label (should be s or m)
5. Update parent issue:
   - Convert to epic type
   - Add `epic` label
   - Add checklist linking child issues
   - Remove `effort/xl` (children have own estimates)

#### Dependency Links

When child issues have ordering dependencies:

```markdown
## Dependencies
- Blocked by: #N1 (API must exist before UI can call it)
```

#### Output

```
ISSUE DECOMPOSE: #28 "Implement payment retry system"
Original: effort/xl, 8 acceptance criteria, 12 files

Created 4 sub-issues:
  #45 [P1] Add retry queue schema (effort/s, blocked by: none)
  #46 [P1] Implement retry worker (effort/m, blocked by: #45)
  #47 [P1] Add webhook retry handler (effort/m, blocked by: #45)
  #48 [P1] Add retry monitoring dashboard (effort/s, blocked by: #46, #47)

Parent #28 converted to epic with sub-issue checklist.
```

## Related

- `groom/references/org-standards.md` — Scoring rubric and issue format
- `/groom` — Phase 5 uses `/issue lint` as quality gate
- `/autopilot` — Runs `/issue lint` before starting work
- `/tidy` — Runs `/issue lint --all --fix`
