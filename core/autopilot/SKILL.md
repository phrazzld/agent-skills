---
name: autopilot
description: |
  Full autonomous delivery from issue to PR.
  Finds highest-priority issue, specs it, designs it, builds it, ships it.
  Use when: shipping an issue end-to-end, autonomous delivery, sprint execution.
  Trigger: /autopilot, "ship this issue", "build and ship", "sprint execute".
argument-hint: "[issue-id]"
---

# /autopilot

From issue to PR in one command.

## Role

Engineering lead running a sprint. Find work, ensure it's ready, delegate implementation, ship.

## Objective

Deliver Issue `$ARGUMENTS` (or highest-priority open issue) as a draft PR with tests passing
and a clean dogfood QA pass.

## Latitude

- Codex writes first draft of everything (investigation, implementation, tests, docs)
- You orchestrate, review, clean up, commit, ship
- Flesh out incomplete issues yourself (spec, design)
- Never skip an issue because it's "not ready" — YOU make it ready
- `dogfood`, `agent-browser`, and `browser-use` are available in this environment; use them for user-flow validation

## Priority Selection

**Always work on the highest priority issue. No exceptions.**

1. `p0` > `p1` > `p2` > `p3` > unlabeled
2. Within tier: `horizon/now` > `horizon/next` > unlabeled
3. Within same horizon: lower issue number first
4. Scope, cleanliness, comfort don't matter — priority is absolute

## Workflow

1. **Find issue** — `gh issue view $1` or `gh issue list --state open --limit 20`
2. **Load context** — Read `project.md` for product vision, domain glossary, quality bar
3. **Readiness gate** — Run `/issue lint $1`:
   - Score >= 70: proceed
   - Score 50-69: run `/issue enrich $1` first, then re-lint
   - Score < 50: flag to user, attempt enrichment, re-lint
   - **Never skip an issue because it scored low — YOU make it ready**
4. **Spec** — Invoke `/shape --spec-only` if no `## Product Spec` section
5. **Design** — Invoke `/shape --design-only` if no `## Technical Design` section
6. **Build (TDD Enforced)** — Invoke `/build` and require RED→GREEN evidence per acceptance criterion:
   - RED: failing targeted tests before implementation
   - GREEN: same tests passing after implementation
   - If test harness is broken, stop and flag blocker (no implementation without explicit user bypass)
7. **Visual QA** — If diff touches frontend files (`app/`, `components/`, `*.css`), run `/visual-qa --fix`. Fix P0/P1 before proceeding.
8. **Refine** — `/pr-fix --refactor`, update docs inline, then `ousterhout` agent for module depth review
9. **Dogfood QA** — Run automated QA against local dev server (see Dogfood QA section below).
   Iterate until no P0/P1 issues remain. **Do not open a PR until QA passes.**
10. **Commit** — Create semantic commits for all remaining changes:
    - Categorize files: commit, gitignore, delete, consolidate
    - Group into logical commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
    - Subject: imperative, lowercase, no period, ~50 chars. Body: why not what.
    - Run quality gates (`lint`, `typecheck`, `test`) before pushing
    - `git fetch origin && git push origin HEAD` (rebase if behind)
    - Never force push. Never push to main without confirmation.
11. **Ship** — Open a draft PR:
    - Stage and commit any uncommitted changes with semantic message
    - Read linked issue from branch name or recent commits
    - PR body must contain all sections:
      - **Summary**: What changed and why. Link to issue. `Closes #N`.
      - **Changes**: Concise list of what was done. Key files/functions.
      - **Acceptance Criteria**: From linked issue. Checkboxes.
      - **Manual QA**: Step-by-step verification. Commands, expected output.
      - **What Changed**: Mermaid diagram (graph TD for features, stateDiagram-v2 for fixes, sequenceDiagram for APIs).
      - **Before / After**: Text description mandatory. Screenshots for UI changes.
      - **Test Coverage**: Specific test files/functions. Note gaps.
    - `gh pr create --draft --assignee phrazzld`
    - Add context comment if notable decisions were made
12. **Retro** — Append implementation signals to `.groom/retro.md`:
    ```
    /retro append --issue $1 --predicted {effort_label} --actual {actual_effort} \
      --scope "{scope_changes}" --blocker "{blockers}" --pattern "{insight}"
    ```

## Dogfood QA

Run before every PR. No exceptions.

`/dogfood` is an agent skill, not a shell binary. Invoke it as `/dogfood ...`.
Do not run `dogfood --help` or declare it unavailable based on shell PATH.
Use `agent-browser` / `browser-use` for focused manual repro and follow-up verification.

### Setup

```bash
# Start dev server if not already running
# Find existing server first
PORT=$(lsof -i :3000 -sTCP:LISTEN -t 2>/dev/null | head -1)
if [ -z "$PORT" ]; then
  bun dev:next &
  DEV_PID=$!
  sleep 10  # wait for compilation
fi

# Confirm it's up
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/
```

If port 3000 is taken by another project, use `bun dev:next -- --port 3001` and adjust the
target URL accordingly.

### Run

```
/dogfood http://localhost:3000
```

Scope to the diff: if the issue only touches status pages, `/dogfood http://localhost:3000 Focus on the status page and badge changes`. For full-feature work, no scope restriction.

### Issue Severity Gate

After `/dogfood` completes, read the report:
- **P0 or P1 issues** → fix them, commit, re-run `/dogfood` on the affected area
- **P2 issues** → fix if quick (<15 min), otherwise document in PR as known and create a follow-up issue
- **P3 issues / no issues** → proceed to `/pr`

Never open a PR with unfixed P0 or P1 issues from the dogfood report.

### Iteration Cap

If the same P0/P1 issue resurfaces after two fix attempts, stop, document the blocker, and
flag to the user before proceeding. Don't loop indefinitely.

### Teardown

```bash
# Kill the dev server if we started it
[ -n "$DEV_PID" ] && kill $DEV_PID 2>/dev/null || true
```

If the user's own dev server was already running (no `$DEV_PID`), leave it alone.

## Parallel Refinement (Agent Teams)

After `/build` completes, parallelize the refinement phase:

| Teammate | Task |
|----------|------|
| **Simplifier** | Run code-simplifier agent, commit |
| **Depth reviewer** | Run ousterhout agent, commit |
| **Doc updater** | Update docs (README, ADRs, API docs), commit |

Lead sequences commits after all teammates finish. Then dogfood QA, then `/pr`.

Use when: substantial feature with multiple refinement needs.
Don't use when: small fix where sequential is fast enough.

## Stopping Conditions

Stop only if: issue explicitly blocked, build fails after multiple attempts, requires external action.

NOT stopping conditions: lacks description, seems big, unclear approach.

## Output

Report: issue worked, spec status, design status, TDD evidence (RED/GREEN), commits made, dogfood QA summary (issues found/fixed), PR URL.
