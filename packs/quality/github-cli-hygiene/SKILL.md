---
name: github-cli-hygiene
description: Safe, well-formatted GitHub CLI writes for PRs/issues/reviews using body files and post-write validation.
---

# GitHub CLI Hygiene Skill

Use this skill whenever writing content to GitHub via CLI:
- PR title/body creation or edits
- PR comments
- issue comments
- review submissions/replies

## Invocation intent for PR work

If the user asks to "open/create/make/update the PR" (or invokes a PR prompt/skill), execute the write action — do not stop at drafting content.
- No existing PR for branch: run `gh pr create ... --body-file <path>`
- Existing PR: run `gh pr edit ... --body-file <path>`
- Only skip write when user explicitly requests draft-only output

## Core policy (non-negotiable)

1. Never use inline `--body/-b` for Markdown content.
2. Always write Markdown to a temp file first.
3. Use `--body-file/-F <path>` for write commands.
4. Fetch back the posted content and verify formatting quality.

## Canonical write flow

1. Draft content in file
   - `/tmp/pr-body.md`, `/tmp/pr-comment.md`, `/tmp/review-reply.md`
2. Execute GitHub command with body file
3. Re-fetch and lint output quality
   - no escaped `\n`
   - no ANSI artifacts or pasted logs
   - no empty bullets
4. If malformed, immediately edit and re-post via body file

## Safe command patterns

### Create PR
```bash
gh pr create --title "<title>" --body-file /tmp/pr-body.md
```

### Edit PR body
```bash
gh pr edit <number> --body-file /tmp/pr-body.md
```

### PR comment
```bash
gh pr comment <number> --body-file /tmp/pr-comment.md
```

### Issue comment
```bash
gh issue comment <number> --body-file /tmp/issue-comment.md
```

### PR review
```bash
gh pr review <number> --comment --body-file /tmp/review.md
```

## Quality checklist before submit

- Title is specific and <= 72 chars
- Body has clear sections and concise bullets
- Verification includes commands + pass/fail summaries only
- Includes `Closes #N` when applicable
- No raw stdout/stderr pasted
