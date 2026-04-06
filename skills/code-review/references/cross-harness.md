# Cross-Harness Review

Invoke other AI coding CLIs for harness-diverse review. Each CLI brings its own
system prompt, tools, and AGENTS.md context — genuinely different from the same
model accessed via API.

## Codex

```
codex review --base $BASE
```

Native review command. Runs GPT-5-codex with Codex's harness context (config.toml,
AGENTS.md, sandbox tools). Returns structured review output.

Options:
- `--base BRANCH` — review changes against this branch
- `--uncommitted` — review staged + unstaged + untracked changes
- Custom instructions can be appended as a prompt argument

## Gemini

```
gemini -p "Review the changes on this branch against $BASE. Report blocking findings (correctness, security, architecture, test coverage) with file:line references." --approval-mode plan
```

Headless mode (`-p`), read-only (`--approval-mode plan`). Runs Gemini with its
own harness context (~/.gemini/GEMINI.md, skills, settings).

## Harness Detection

Skip whichever CLI you ARE — you already have that model's perspective as the
marshal. The model knows which harness it's running in.

## Consuming Output

Both CLIs produce text output. Read the full output. Extract findings with
file:line references and severity. Feed into the marshal's synthesis alongside
thinktank and internal bench results.

## Gotchas

- If a CLI is not installed or fails, skip it gracefully. Don't block the review.
- Cross-harness CLIs run in the current repo directory — they see the same files.
- Don't pipe the entire diff as stdin for large diffs. Let the CLI read the repo.
