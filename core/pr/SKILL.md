---
name: pr
description: |
  Full PR workflow from working directory to draft PR.
  Commits uncommitted changes, analyzes diff, writes description, opens draft.
  Use when: opening a pull request, shipping to review, creating PR.
  Trigger: /pr, "open PR", "create pull request", "ship to review".
disable-model-invocation: true
---

# /pr

Open a pull request from current branch state.

## Role

Engineer shipping clean, well-documented PRs.

## Objective

Create a draft PR from current branch. Link to issue, make the significance obvious, and give reviewers the value/trade-off context they need at a glance.

## Latitude

- Stage and commit any uncommitted changes with semantic message
- Read linked issue from branch name or recent commits
- Write PR body that explains significance, value, trade-offs, and alternatives, not just changes
- `dogfood`, `agent-browser`, and `browser-use` are available here; use them for flow QA evidence
- Load [references/pr-body-template.md](./references/pr-body-template.md) before writing the PR body

## PR Body Requirements (MANDATORY)

Every PR body must follow [references/pr-body-template.md](./references/pr-body-template.md).
A PR missing these sections is not ready.

```
## Why This Matters
Top-line significance first:
- what problem existed
- what value this adds
- why this is worth doing now
- link to issue

## Trade-offs / Risks
State the value gained, the costs/risks incurred, and why the trade is still worth it.

## What Changed
Show the delta, not just the end state:
- Mermaid flow chart for the base branch
- Mermaid flow chart for this PR
- Mermaid architecture/state/sequence diagram for the deeper structural change
- Short explanation of why this is an improvement

## Changes
Concise mechanical summary. Reference key files/functions.

## Intent Reference
Link to the issue/spec/intent contract that justifies the work.

## Alternatives Considered
At minimum: do nothing, one credible alternate approach, and why the chosen approach won.

## Acceptance Criteria
Copied or derived from the linked issue. Checkboxes.

## Manual QA
Step-by-step instructions a reviewer can follow to verify the change works.
Include: setup steps, exact commands, expected output, URLs to visit.

## Before / After
Show the state before and after this PR. MANDATORY for every PR.

**Text**: Describe the previous behavior/state and the new behavior/state.
**Screenshots**: Include before and after screenshots for any user-facing change
(UI, CLI output, error messages, dashboards). Use `![before](url)` / `![after](url)`.

Skip screenshots ONLY when the change is purely internal (no visible output difference).
When in doubt, screenshot.

## Test Coverage
Pointers to specific test files and test functions that cover this change.
Note any gaps: what ISN'T tested and why.

## Merge Confidence
State confidence level, strongest evidence, and residual risk.
```

Use `<details>/<summary>` to collapse larger sections such as Alternatives,
Manual QA, Acceptance Criteria, Test Coverage, and screenshot-heavy Before / After evidence.
Keep `Why This Matters`, `Trade-offs / Risks`, and the opening `What Changed` explanation visible.

## Workflow

1. **Clean** — Commit any uncommitted changes with semantic message
2. **Context** — Read linked issue, diff branch against main, identify relevant tests
3. **Visual QA** — If diff touches frontend files (`app/`, `components/`, `*.css`), run `/visual-qa`. Fix any P0/P1 issues before opening PR. Capture screenshots for Before/After section.
4. **Dogfood QA** — Run `/dogfood http://localhost:3000` (start dev server first if not running).
   `/dogfood` is a skill command (not a PATH CLI check). Use `agent-browser` / `browser-use` for focused repro as needed.
   Fix all P0/P1 issues found. Iterate until clean. **Do not open a PR until this passes.**
   Include dogfood summary (issues found, fixed) in PR body under Manual QA section.
5. **Describe** — Title from issue, body follows [references/pr-body-template.md](./references/pr-body-template.md). Lead with significance/value/trade-offs, not the diff recap.
6. **Before/After** — Use screenshots from visual QA + dogfood steps. For non-UI changes, describe behavioral difference in text. If the PR body gets long, move heavy evidence into `<details>`.
7. **Open** — `gh pr create --draft --assignee phrazzld`
8. **Comment** — Add context comment if notable decisions were made
9. **Retro** — If this PR closes a GitHub issue, append implementation feedback:
   ```
   /retro append --issue $ISSUE --predicted {effort_label} --actual {actual_effort} \
     --scope "{what_changed_from_spec}" --blocker "{blockers}" --pattern "{insight}"
   ```
   This feeds the grooming feedback loop — `/groom` reads retro.md to calibrate
   future effort estimates and issue scoping.

## Comment Style

Like a colleague leaving context for future-you:
- **Concise** — No fluff
- **High-context** — Reference files, functions, decisions
- **Useful** — What's not obvious from the diff?
- **Human** — Some wit welcome

## Output

PR URL. Retro entry appended to `.groom/retro.md` (if issue-linked).
