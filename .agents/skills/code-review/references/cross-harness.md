# Cross-Harness Review

Invoke other AI coding CLIs for harness-diverse review. Each CLI brings its
own system prompt, tools, and AGENTS.md context — genuinely different from
the same model accessed via API. On Spellbook specifically this matters:
the thing being reviewed is often harness-scoped (Claude settings, Codex
plugins, Pi skills[] globs), and having a reviewer running *inside* a
different harness surfaces parity issues the marshal can't see from one
harness alone.

## Codex

```
codex review --base $BASE
```

Native review command. Runs GPT-5-codex with Codex's harness context
(`config.toml`, `AGENTS.md`, sandbox tools). Returns structured review
output.

Options:
- `--base BRANCH` — review changes against this branch.
- `--uncommitted` — review staged + unstaged + untracked changes.
- Custom instructions can be appended as a prompt argument.

For Spellbook: Codex is especially useful as a reviewer on diffs that
touch `harnesses/claude/` or `harnesses/pi/`, because Codex will flag
parity violations the Claude marshal is liable to miss.

## Gemini

```
gemini -p "Review the changes on this branch against $BASE. Report blocking findings (correctness, cross-harness parity, self-containment, lowered quality gates, broken frontmatter) with file:line references." --approval-mode plan
```

Headless mode (`-p`), read-only (`--approval-mode plan`). Runs Gemini with
its own harness context (`~/.gemini/GEMINI.md`, skills, settings).

## Harness Detection

Skip whichever CLI you ARE — you already have that model's perspective as
the marshal. The model knows which harness it's running in. If you're
Claude, run Codex + Gemini. If you're Codex, run Gemini (and optionally
Claude). If you're Pi, run Codex + Gemini.

## Consuming Output

Both CLIs produce text output. Read the full output. Extract findings with
file:line references and severity. Feed into the marshal's synthesis
alongside thinktank and philosophy-bench results.

## Gotchas

- If a CLI is not installed or fails, skip it gracefully. Don't block the
  review on one provider.
- Cross-harness CLIs run in the current repo directory — they see the same
  files. No need to pipe the diff as stdin.
- Don't pipe the entire diff as stdin for large diffs. Let the CLI read
  the repo directly.
- A cross-harness reviewer flagging a parity issue the marshal missed is
  load-bearing signal — upgrade its severity, don't dismiss it as
  "different harness, different opinion."
