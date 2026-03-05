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

## Precondition Gate

Before starting, verify:

```bash
gh pr view $PR --json mergeable,statusCheckRollup,reviewDecision
```

Requirements:
- No merge conflicts
- CI green
- No unaddressed critical review feedback

**If any fail**: Tell user to run `/pr-fix` first. Do not proceed.

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

For architectural findings that require broader changes: create GitHub issues.

```bash
gh issue create --title "[Arch] Finding from PR #$PR hindsight review" --body "..."
```

### 3.5 Simplification Pass (Capability-Gated)

After Pass 2, run a focused simplification sweep.

- Preferred accelerator (if native in current harness): `/simplify`
- Portable fallback (required): run `ousterhout` agent and apply resulting module-depth simplifications manually

If native batch dispatch is available (e.g. `/batch`), use it to parallelize refine/test/docs subtasks.
Otherwise execute those subtasks sequentially.

### 4. Test Audit

Review test coverage for the PR's changed files. Look for:

- Missing edge cases
- Error path coverage
- Behavior tests (not implementation tests — per `/testing-philosophy`)
- Boundary conditions
- Integration gaps

Write missing tests. Each test should justify its existence — no coverage-padding.

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

### 7. Update PR Description with Before / After

Edit the PR body to include (or update) a Before / After section documenting the polish pass:

```bash
gh pr edit $PR --body "$(current body + before/after section)"
```

**Text (MANDATORY)**: Describe the state before polish (e.g., "working but with shallow modules and missing edge-case tests") and after (e.g., "consolidated modules, 12 new edge-case tests, updated architecture docs").

**Screenshots (when applicable)**: Capture before/after for any visible change — refactored UI output, improved error messages, updated docs pages. Use `![before](url)` / `![after](url)`.

Skip screenshots only when all polish was purely internal (refactoring with no visible output change).

### 7.5 Diagram Audit

Check PR body for visual communication:

```bash
gh pr view $PR --json body | jq -r '.body'
```

- Does the PR body have a `## What Changed` Mermaid diagram?
- If no, and the change involves logic/architecture/data flow: generate one using `~/.claude/skills/visualize/references/github-mermaid-patterns.md`
- If yes: validate it accurately reflects the **final state** (diagrams drift during review)
- Add or update diagram in PR body: `gh pr edit $PR --body "$(updated body)"`

Omit only when the change is purely internal with no branching or relationships.

### 8. Refresh Glance Summaries (Conditional)

If this PR added, removed, or significantly restructured directories:

```bash
glance   # run from repo root — skips up-to-date directories automatically
```

Do NOT pass `-force`. Glance handles intelligent regeneration based on existing `.glance.md` files. Only affects directories that changed.

Commit any updated `.glance.md` files with the PR branch.

### 9. Codify (Optional)

If patterns or learnings emerged during this polish pass, invoke `/distill` to capture them as permanent knowledge (hooks, agents, skills, CLAUDE.md entries).

Skip if nothing novel surfaced.

## Anti-Patterns

- Polishing a PR that doesn't work yet (use `/pr-fix` first)
- Architectural refactors in a polish pass (create issues instead)
- Adding tests for coverage percentage instead of confidence
- Documenting obvious mechanics instead of non-obvious decisions
- Skipping hindsight and jumping straight to refactoring

## Output

Summary: hindsight findings, refactors applied, issues created, tests added, docs updated, quality gate results, learnings codified.
