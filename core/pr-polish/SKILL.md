---
name: pr-polish
description: |
  Elevate a working PR: hindsight review, code refinement, test audit, docs, quality gates.
  Use when: PR works but could be better, pre-merge quality pass, retrospective review.
  Trigger: /pr-polish, "polish this PR", "elevate quality", "hindsight review".
argument-hint: "[PR-number]"
---

# /pr-polish

Holistic quality elevation for a PR that already works.

## Role

Staff engineer doing a retrospective pass. Not finding bugs — asking "would we build it the same way starting over?"

## Objective

Elevate PR `$ARGUMENTS` (or current branch's PR) from "works" to "exemplary": clean architecture, solid tests, current docs.
Secondary question: **"How confident are we that merging this will not break existing behavior?"**
Treat confidence as an explicit deliverable, not a vibe.

## Precondition Gate

Before starting, verify:

```bash
gh pr view $PR --json mergeable,statusCheckRollup,reviewDecision
```

Requirements:
- No merge conflicts
- CI green for any relevant existing checks
- No unaddressed critical review feedback

If mergeability is broken, relevant CI is red, or critical review feedback is still open:
- run `/pr-fix` first
- do not proceed with polish

If the repo simply lacks the relevant CI checks, continue. Missing CI is a polish target and must be called out in the merge-confidence ledger.

## Workflow

### 1. Context

Read everything about this PR:

```bash
gh pr view $PR --json body,commits,files
gh pr diff $PR
```

Read linked issue(s). Read commit history. Understand the full arc of what was built and why.

### 2. Hindsight Review

Launch `hindsight-reviewer` agent via Task tool.

Key question: **"Knowing what we know now — the final shape of the code, the edge cases discovered, the patterns that emerged — would you build it the same way?"**

Feed it: full diff against main, PR description, linked issue.

Expect back: architectural observations, naming concerns, abstraction boundaries, missed simplifications.

### 3. Refine

Address hindsight findings using two-pass refinement (see `pr-fix/references/refactor.md`):

**Pass 1 — Clarity:** Naming improvements, reduced nesting, consolidated logic, removed obvious comments.

**Pass 2 — Architecture:** Shallow module consolidation, unnecessary abstraction removal, information hiding improvements.

Delete compatibility layers that only exist to preserve agent-added structure.
Passing tests do not justify bloat.

For architectural findings that require broader changes: create GitHub issues.

```bash
gh issue create --title "[Arch] Finding from PR #$PR hindsight review" --body "..."
```

### 3.5 Simplification Pass (Capability-Gated)

After Pass 2, run a focused simplification sweep.

- Preferred accelerator (if native in current harness): `/simplify`
- Portable fallback (required): consult the `ousterhout` persona guidance and apply resulting module-depth simplifications manually

If native batch dispatch is available (e.g. `/batch`), use it to parallelize refine/test/docs subtasks.
Otherwise execute those subtasks sequentially.

### 4. Test Audit

Review test coverage for the PR's changed files. Look for:

- Missing edge cases
- Error path coverage
- Behavior tests (not implementation tests — per `/testing-philosophy`)
- Module-boundary tests over internal call choreography
- Boundary conditions
- Integration gaps

Write missing tests. Each test should justify its existence — no coverage-padding.

If tests are mock-heavy or fail on refactor-only changes, rewrite them as developer tests against exports/public behavior.

### 4.25 Merge Confidence Audit

Ask directly: **"What evidence says this merge will not break existing behavior, and what evidence is still missing?"**

Build a short confidence ledger:
- `Evidence` — passing tests, typechecks, builds, lint, manual QA, dogfood runs, screenshots, production-safe invariants
- `Gaps` — missing regression tests, no CI, weak smoke tests, unverified migration paths, untouched error paths, missing browser/runtime verification
- `Risk` — what could still break despite current green checks

Then remediate the highest-leverage gaps you can within polish scope:
- Add or strengthen regression/smoke tests for changed behavior
- Add or tighten CI when checks are missing or too weak
- Run build/typecheck/lint/test commands that cover the changed surface
- Run targeted manual QA or browser QA for user-facing diffs
- Verify compatibility paths explicitly when multiple entrypoints exist (`npm` vs `bun`, web vs mobile, API vs UI)

Rules:
- If there is **no CI** for the relevant checks, add it or document precisely why it cannot be added in this pass
- If confidence depends on a manual assumption, turn it into an automated check when feasible
- Do not claim "high confidence" while major evidence gaps remain
- If a gap is too broad for polish, create a follow-up issue and call out the residual risk in the PR

### 4.5 Agentic Audit

If the PR touches prompts, model routing, tool schemas, or agent instructions:

- Run `/llm-infrastructure`
- Review real traces before changing prompts again
- Add eval cases for observed confusions/regressions
- Remove irrelevant prompt bulk discovered in traces

### 5. Documentation

Update docs for anything the PR affects:

- ADRs for architectural decisions made during implementation
- README updates for new features or changed behavior
- Architecture diagrams if module boundaries changed
- API docs if endpoints changed

### 6. Quality Gates

Invoke `/check-quality` and run project verification:

```bash
pnpm typecheck && pnpm lint && pnpm test
```

All gates must pass. Fix anything that doesn't.
If repo-wide gates are already red from unrelated debt, still add the strongest PR-scoped automated checks you can and record the residual gap.

### 7. Update PR Description with Before / After + Walkthrough

Edit the PR body to preserve the richer `/pr` structure and update the sections affected by the polish pass.
Refresh the `## Walkthrough` section too if the polish changes the strongest merge evidence:

```bash
gh pr edit $PR --body "$(updated body)"
```

Before editing, read `../pr/references/pr-body-template.md`.

Refresh:
- `Why This Matters` if the polish changed the meaning or significance of the PR
- `Trade-offs / Risks` if the polish removed or introduced reviewer concerns
- `What Changed` diagrams if the final architecture/flow drifted during review
- `Before / After` to document what the polish improved
- `Merge Confidence` to reflect the new evidence level after polish

**Text (MANDATORY)**: Describe the state before polish (e.g., "working but with shallow modules and missing edge-case tests") and after (e.g., "consolidated modules, 12 new edge-case tests, updated architecture docs").

**Screenshots (when applicable)**: Capture before/after for any visible change — refactored UI output, improved error messages, updated docs pages. Use `![before](url)` / `![after](url)`.

Skip screenshots only when all polish was purely internal (refactoring with no visible output change).

If polish changes the story reviewers should trust, rerun `/pr-walkthrough` and update:

- Artifact
- Claim
- Before / After scope
- Persistent verification
- Residual gap

### 7.5 Diagram Audit

Check PR body for visual communication:

```bash
gh pr view $PR --json body | jq -r '.body'
```

- Does it include base-branch and PR-branch flow charts plus the deeper architecture/state diagram when the change has meaningful flow?
- If no, and the change involves logic/architecture/data flow: generate them using `~/.claude/skills/visualize/references/github-mermaid-patterns.md`
- If yes: validate they accurately reflect the **final state** and make the improvement legible
- Add or update diagram in PR body: `gh pr edit $PR --body "$(updated body)"`

Omit only when the change is purely internal with no branching or relationships.

### 8. Refresh Context Artifacts (Conditional)

If this PR added, removed, or significantly restructured directories:

Refresh the relevant context artifacts if the repo uses them:

- `docs/CODEBASE_MAP.md`
- `docs/context/INDEX.md`
- `docs/context/ROUTING.md`
- `docs/context/DRIFT-WATCHLIST.md`

Commit any updated context artifacts with the PR branch.

### 9. Codify (Optional)

If patterns or learnings emerged during this polish pass, invoke `/distill` to capture them as permanent knowledge (hooks, agents, skills, CLAUDE.md entries).

Skip if nothing novel surfaced.

## Anti-Patterns

- Polishing a PR that doesn't work yet (use `/pr-fix` first)
- Architectural refactors in a polish pass (create issues instead)
- Adding tests for coverage percentage instead of confidence
- Claiming merge confidence without listing concrete evidence and residual risk
- Leaving missing CI unaddressed when the PR depends on local-only verification
- Documenting obvious mechanics instead of non-obvious decisions
- Skipping hindsight and jumping straight to refactoring
- Preserving unnecessary backward-compat shims in greenfield or pre-user code

## Output

Summary: hindsight findings, refactors applied, issues created, tests added, docs updated, quality gate results, merge-confidence evidence/gaps, learnings codified.
