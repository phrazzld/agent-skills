---
name: pr
description: |
  Full PR workflow from working directory to live PR.
  Commits uncommitted changes, analyzes diff, writes description, opens the PR.
  Use when: opening a pull request, shipping to review, creating PR.
  Trigger: /pr, "open PR", "create pull request", "ship to review".
disable-model-invocation: true
---

# /pr

Open a pull request from current branch state.

## Role

Engineer shipping clean, well-documented PRs.

## Objective

Create a live PR from current branch. Link to issue, make the significance obvious, give reviewers the value/trade-off context they need at a glance, and attach the walkthrough package that proves the merge case.

`/pr` opens or updates the review lane. It does not certify that the live PR is review-clean after async reviewer automation runs.

## Latitude

- Stage and commit any uncommitted changes with semantic message
- Read linked issue from branch name or recent commits
- Write PR body that explains significance, value, trade-offs, and alternatives, not just changes
- Run `/pr-walkthrough` and treat its output as required PR evidence
- Own ship blockers surfaced by the required gates; fix adjacent repo debt when it is the only thing keeping the lane from opening cleanly
- `dogfood`, `agent-browser`, and `browser-use` are available here; use them for flow QA evidence
- Load [references/pr-body-template.md](./references/pr-body-template.md) before writing the PR body
- Treat an existing PR for the same branch or issue as the lane to update, not a reason to create another PR

## PR Body Requirements (MANDATORY)

Every PR body must follow [references/pr-body-template.md](./references/pr-body-template.md).
A PR missing template sections is not ready.

Use `<details>/<summary>` to collapse larger sections such as Alternatives,
Manual QA, Acceptance Criteria, Test Coverage, Walkthrough evidence, and screenshot-heavy Before / After evidence.
Keep `Why This Matters`, `Trade-offs / Risks`, and the opening `What Changed` explanation visible.

## Workflow

1. **Duplicate PR Gate** — Before writing anything to GitHub:
   - Detect the linked issue from branch name, commit messages, or diff context
   - Preferred: run `python3 scripts/issue_lane.py --repo <owner/name> --issue <N>` when the repo provides it
   - Check for an existing PR from the current branch
   - Check for other open PRs already referencing the same issue number
   - If the current branch already has a PR, update it with `gh pr edit` instead of creating a new one
   - If another branch already has an open PR for the same issue, stop and surface the duplicate lane unless you are explicitly superseding it
2. **Clean** — Commit any uncommitted changes with semantic message
3. **Context** — Read linked issue, diff branch against main, identify relevant tests
4. **Visual QA** — If diff touches frontend files (`app/`, `components/`, `*.css`), run `/visual-qa`. Fix any P0/P1 issues before opening PR. Capture screenshots for Before/After section.
5. **Dogfood QA** — Run `/dogfood http://localhost:3000` (start dev server first if not running).
   `/dogfood` is a skill command (not a PATH CLI check). Use `agent-browser` / `browser-use` for focused repro as needed.
   Fix all P0/P1 issues found. Iterate until clean. **Do not open a PR until this passes.**
   Include dogfood summary (issues found, fixed) in PR body under Manual QA section.
6. **Walkthrough** — Run `/pr-walkthrough`. Every PR needs a walkthrough package, even when the change is not user-facing. Use browser, terminal, diagram, Remotion, or mixed media as appropriate.
7. **Describe** — Title from issue, body follows [references/pr-body-template.md](./references/pr-body-template.md). Lead with significance/value/trade-offs, not the diff recap.
8. **Before/After** — Use screenshots or evidence from visual QA, dogfood, and `/pr-walkthrough`. For non-UI changes, describe behavioral or architectural difference in text. If the PR body gets long, move heavy evidence into `<details>`.
9. **Open / Update** — Use `gh pr create --assignee phrazzld --body-file <path>` for new PRs. Use `gh pr edit --body-file <path>` when the branch already has a PR.
10. **Review Settlement Handoff** — If the final push, `gh pr ready`, or PR update triggered async reviewers:
   - do not post `PR Unblocked` or claim the PR is review-clean
   - route live review reconciliation through `/pr-fix`
   - only treat the PR as unblocked after `/pr-fix` closes the post-settlement review inventory
11. **Comment** — Add context comment if notable decisions were made, and use `--body-file` for comment bodies.
12. **Retro** — If this PR closes a GitHub issue, append implementation feedback:
   ```bash
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

PR URL. Retro entry appended to `.groom/retro.md` (if issue-linked). If review automation is pending or unresolved, say that explicitly instead of implying the PR is unblocked.
