---
name: pr
description: |
  Tidy, commit, and open a world-class pull request.
  Organizes working directory, ensures correct branch, creates semantic
  conventional commits, then opens a high-quality PR with full evidence.
  Use when: ready to ship, "open a PR", "create PR", "commit and PR",
  "ship this", "push and PR", "prep for review", "make a PR".
disable-model-invocation: true
argument-hint: "[issue-id] [--draft] [--no-push]"
---

# /pr

From messy working directory to reviewable PR in one command.

## Role

Engineer shipping clean, well-documented work for review.

## Objective

Take the current working directory state — however messy — and produce:
1. A clean branch with semantic conventional commits
2. A PR that makes the merge case obvious to any reviewer

## Process

### 1. Orient

```bash
git status --short
git log --oneline -5
git branch --show-current
git diff --stat HEAD
```

Determine:
- **Current branch** — if on `main`/`master`, create a feature branch from the diff context
- **Linked issue** — from branch name (`feat/42-thing`), recent commits, or `$ARGUMENTS`
- **Existing PR** — `gh pr list --head $(git branch --show-current) --json number,url`

If already on a feature branch with a PR, this is an update flow.

### 2. Tidy

Clean up the working directory before committing:

- **Cruft** — remove generated files, `.DS_Store`, build artifacts not in `.gitignore`
- **Gitignore gaps** — add missing entries (e.g., `.env.local`, `node_modules/`, `*.log`)
- **Consolidate** — if scratch/temp files exist that should be deleted or merged, do it
- **Unstaged experiments** — if there are throwaway files (debug scripts, scratch notes), confirm before including

Do NOT delete anything that looks intentional without asking.

### 3. Commit

Split changes into logical, semantically meaningful conventional commits.

**Grouping rules:**
- One concern per commit. A feature addition, its tests, and its docs can be one commit.
- Separate refactors from features from fixes.
- Separate dependency changes from code changes.
- Separate formatting/linting from logic changes.

**Commit message format:**
```
<type>(<scope>): <subject>

<body — why, not what>
```

Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

Subject: imperative, lowercase, no period, ~50 chars.
Body: explain WHY. Link issue when relevant (`Closes #42`, `Part of #42`).

**Ordering:** infrastructure → refactor → feature → tests → docs → chore

### 4. Quality Gate

Run whatever quality gates the project has before pushing:

```bash
# Detect and run available gates
[[ -f package.json ]] && npm run lint 2>/dev/null; npm run typecheck 2>/dev/null; npm test 2>/dev/null
[[ -f Makefile ]] && make check 2>/dev/null
[[ -f mix.exs ]] && mix compile --warnings-as-errors && mix test 2>/dev/null
```

If gates fail: fix, amend or add a fix commit, re-run. Do not push red.

### 5. Push

```bash
git fetch origin
# Rebase onto base branch if behind
git rebase origin/main || git rebase origin/master
git push origin HEAD -u
```

Never force push. If rebase conflicts, resolve and continue.

### 6. PR Body

Write the PR body to a temp file using `--body-file`. The body is the merge case,
not a changelog. Lead with significance, not mechanics.

**Required sections (all PRs):**

#### Visible on first load:

**Reviewer Evidence** — If the PR has user-visible changes, put proof first:
- Screenshot or video link (prefer GitHub-uploaded attachments)
- One-sentence merge claim
- "Start here" pointer for reviewers

**Why This Matters**
- Problem that existed before this PR
- Value this PR adds
- Why now (what triggered this work)
- Issue link: `Closes #N` or `Part of #N`

**Trade-offs / Risks**
- What complexity or cost was added
- What risks remain
- Why the trade is worth it
- What reviewers should pressure-test

**What Changed**
- One paragraph in plain English
- Mermaid `graph TD` of base branch flow
- Mermaid `graph TD` of this-PR flow
- Third diagram (architecture/state/sequence) when meaningful
- Why the new shape is better

#### Under `<details>`:

**Changes** — File/module summary. Key functions touched.

**Acceptance Criteria** — From linked issue. Checkboxes. If no issue, derive from the diff.

**Alternatives Considered** — Do nothing + one credible alternative + why current approach won.

**Manual QA** — Exact commands, URLs, setup, expected output.

**Test Coverage** — Specific test files. Gaps called out.

**Before / After** — Text always. Screenshots for UI changes.

**Merge Confidence** — Confidence level, strongest evidence, remaining uncertainty.

### 7. Open / Update

```bash
# New PR
gh pr create --assignee phrazzld --body-file /tmp/pr-body.md --title "<title>"

# Existing PR
gh pr edit <number> --body-file /tmp/pr-body.md
```

**Title:** `<type>(<scope>): <subject>` — under 70 chars. Same format as commits.

If `--draft` flag, add `--draft` to create.

### 8. Post-Open

- Add a context comment if notable design decisions were made
- If the PR touches frontend, attach screenshots or demo video
- Report the PR URL

Do NOT claim the PR is "ready to merge" or "review-clean". Opening a PR
creates the review lane. Review settlement is a separate concern (`/pr-fix`).

## Demo Artifacts

If the change is user-visible:
- **Motion/interaction/state change** → video (screencast or terminal recording)
- **Static visual change** → screenshots (before/after)
- **Internal/API change** → text before/after is sufficient

For private repos, use GitHub-uploaded attachments, not raw URLs.

## Flags

- `--draft` — Open as draft PR
- `--no-push` — Commit but don't push or create PR
- `$ARGUMENTS` as issue number — Link to specific issue

## Anti-Patterns

- Opening a PR with uncommitted changes still in the working directory
- One giant commit for unrelated changes
- PR title that restates the diff instead of the intent
- Skipping the "why" — just listing file changes
- Burying trade-offs or risks
- Claiming merge readiness before CI and reviews settle
- Creating a duplicate PR when one already exists for the branch

## Output

PR URL. Count of commits created. Note any quality gate failures fixed.
If review automation is pending, say so explicitly.
