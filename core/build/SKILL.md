---
name: build
description: |
  Implement GitHub issue with semantic commits.
  Delegate implementation, review output, ship tested code.
  Use when: building a feature, implementing an issue, writing code, shipping.
  Trigger: /build, /implement, "build this", "implement this", "start coding".
argument-hint: <issue-id>
---

# /build

Stop planning. Start shipping.

## Role

Senior engineer. Codex is your software engineer.

## Objective

Implement Issue #`$ARGUMENTS`. Ship working, tested, committed code on a feature branch.

## Latitude

- Delegate ALL work to Codex by default (investigation AND implementation)
- Keep only trivial one-liners where delegation overhead > benefit
- If Codex goes off-rails, re-delegate with better direction
- `dogfood`, `agent-browser`, and `browser-use` are available; use them to validate user-facing flows

## LLM-First Implementation Rule (Mandatory)

When building semantic behavior (classification, ranking, triage, intent interpretation, compliance judgment), use LLM-first designs.

Avoid heuristic-only semantic logic (regex ladders, keyword scoring, brittle decision trees) unless the problem is purely syntactic.

Use deterministic logic for strict mechanics only: schema/type validation, exact parsing, safety/permission gates.

## Startup

```bash
gh issue view $1 --comments
gh issue edit $1 --remove-label "status/ready" --add-label "status/in-progress" --add-assignee phrazzld
```

Intent gate before coding:
- Issue must include `## Product Spec` and `### Intent Contract`.
- If missing, run `/shape --spec-only $1` to lock intent before implementation.

If on `master`/`main`, branch: `feature/issue-$1` or `fix/issue-$1`.

Before adding new code, read the touched module end-to-end. Do not stack new
layers on a partial mental model.

## TDD Gate (MANDATORY)

TDD is enforced, not optional.

For each acceptance-criteria chunk:
1. Write/adjust a behavior test first.
2. Run targeted test command and confirm failure (RED).
3. Implement minimal code.
4. Re-run same targeted test and confirm pass (GREEN).
5. Refactor with tests still green.

Do not write production implementation before at least one relevant failing test exists.

Tests should target module exports, public interfaces, and observable behavior.
Avoid mock-heavy "unit tests" that pin internal structure.
Default against backward-compat scaffolding that exists only to keep current
tests green. Remove a compatibility layer only if one of these is true:
- the spec/design explicitly allows the break
- usage is proven dead or internal-only
- the user explicitly approved the removal

If evidence is missing, keep the behavior stable and log the cleanup separately.

If tests cannot run (harness/env failure), stop and report blocker. Do not continue implementation unless user explicitly approves bypass.

## Pre-Delegation Checklist

Before delegating any chunk:
- Existing tests? Warn: "Don't break tests in [file]"
- Add or replace? Be explicit
- Pattern to follow? Include reference file path
- Boundary to test? State the module export/public behavior explicitly
- Mocks needed? Only for external boundaries and nondeterminism
- Compatibility path safe to remove? Cite spec, usage evidence, or user approval
- Quality gates? Include verify command

## Execution Loop

For each logical chunk:

1. **Understand** — Read issue/spec, find existing patterns to follow
   Re-read touched modules before each major chunk if the design shifted.
2. **Delegate** — Clear spec + pattern reference + verify command
3. **Review** — capture RED→GREEN evidence + `git diff --stat && pnpm typecheck && pnpm lint && pnpm test`
4. **Commit** — `feat: description (#$1)` if tests pass
5. **Repeat** until complete

Final commit: `feat: complete feature (closes #$1)`

## Multi-Module Mode (Agent Teams)

When the issue spans 3+ distinct modules (e.g., API + UI + tests):

1. Create team with one teammate per module
2. Shared task list tracks dependencies (API must land before UI integration)
3. Each teammate runs its own Codex delegation loop on its module
4. Lead coordinates commit sequencing

Use when: cross-layer features, 3+ modules, clear boundaries.
Don't use when: single module, sequential dependencies dominate.

## Post-Implementation

1. `code-simplifier:code-simplifier` agent for clarity
2. `ousterhout` agent for module depth review
3. Commit simplifications separately

## Visual QA (Frontend Changes)

If the diff touches `app/`, `components/`, or `*.css` files:

1. Run `/visual-qa --fix` with affected routes
2. Fix P0/P1 issues, commit separately (`fix: visual QA — [description]`)
3. Note any P2 findings for the PR body

Skip if: pure backend, pure config, no user-facing changes.

## Dogfood QA (User-Facing Changes)

If the issue changes user flows (UI, route handlers, auth, checkout, onboarding, coach UX):

1. Run `/dogfood http://localhost:3000` after implementation and before final ship step
2. Fix P0/P1 findings, then rerun dogfood on the affected scope
3. Use `agent-browser` / `browser-use` for targeted repro and verification screenshots

`/dogfood` is a skill command. Do not gate on `dogfood` shell binary availability.

## Issue Comments

Leave breadcrumbs: starting work, decision points, scope creep, completion. Concise, high-context, useful, human.
Always include the intent reference in completion comment: `Intent Source: #$1`.

## Output

Commits made, files changed, verification status, and explicit TDD evidence:
- RED command + failing test names
- GREEN command + passing test names

## Visual Deliverable

After completing the core workflow, generate a visual HTML summary:

1. Read `~/.claude/skills/visualize/prompts/build-progress.md`
2. Read the template(s) referenced in the prompt
3. Read `~/.claude/skills/visualize/references/css-patterns.md`
4. Generate self-contained HTML capturing this session's output
5. Write to `~/.agent/diagrams/build-{issue}-{date}.html`
6. Open in browser: `open ~/.agent/diagrams/build-{issue}-{date}.html`
7. Tell the user the file path

Skip visual output if:
- The session was trivial (single finding, quick fix)
- The user explicitly opts out (`--no-visual`)
- No browser available (SSH session)
