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

Deliver Issue `$ARGUMENTS` (or highest-priority eligible open issue) as a draft PR with tests passing,
a clean dogfood QA pass, and a walkthrough artifact that makes the merge case legible.

An open PR for that issue counts as the active delivery lane. Do not create a duplicate PR
for the same issue unless you first surface and justify a superseding lane.

## Latitude

- Codex writes first draft of everything (investigation, implementation, tests, docs)
- You orchestrate, review, clean up, commit, ship
- Flesh out incomplete issues yourself (spec, design)
- Never skip an issue because it's "not ready" — YOU make it ready
- `dogfood`, `agent-browser`, and `browser-use` are available in this environment; use them for user-flow validation

## LLM-First Implementation Rule (Mandatory)

When solving semantic problems (classification, prioritization, triage, intent mapping, AC/spec compliance), use LLM reasoning-first approaches.

Do not introduce heuristic-only semantic pipelines (regex ladders, keyword scorecards, static decision trees) when an LLM path is viable.

Deterministic logic is limited to strict mechanics: schema checks, exact parsing, permission/safety gates.

## Priority Selection

**Always work on the highest-priority eligible issue.**

Eligibility comes first:
- unassigned
- not already marked `In Progress`
- not already being worked by another autopilot run or open PR

1. `p0` > `p1` > `p2` > `p3` > unlabeled
2. Within tier: `horizon/now` > `horizon/next` > unlabeled
3. Within same horizon: lower issue number first
4. Scope, cleanliness, comfort don't matter after eligibility is satisfied

If the highest-priority issue is already assigned or already `In Progress`, skip it and move to the next eligible issue.
Never steal claimed work.

## Claim Discipline

Autopilot must claim work before shaping or coding.

- Auto-pick mode: only select issues with no assignees, no `In Progress` status, no open PR, and no active autopilot lane already attached
- Explicit issue mode: stop if the issue is owned by another operator, already has another open PR, or is otherwise being worked by another lane
- Explicit issue mode may resume work already claimed by you, including an issue already assigned to you or already marked `In Progress` by your lane
- Before `/issue lint`, assign the issue to yourself
- Before `/issue lint`, mark the issue's project status as `In Progress`
- If the issue is not in a project or the project has no `Status` field, attach it to the canonical delivery project first, then set `Status`
- If assignment, project attach, or status mutation fails, stop before implementation and report the blocker explicitly

The point is single ownership. One issue should map to one active autopilot lane.

## Workflow

1. **Find eligible issue** —
   - Explicit issue: inspect assignees, project status, and open PRs before doing anything else
   - Auto-pick: choose the highest-priority open issue that is unassigned, not `In Progress`, and has no open PR or active autopilot lane
   - If there are no open issues, stop and report that the queue is empty
   - If open issues exist but none are eligible, stop and report that all open work is already claimed
   - Preferred lane check: run `python3 scripts/issue_lane.py --repo <owner/name> --issue <N>` when the repo provides it
   - Fallback: query open PRs with `gh pr list --state open --json number,title,body,headRefName,url`
2. **Claim issue** —
   - Assign the issue to yourself
   - Ensure the issue is attached to the canonical delivery project
   - Mark the linked project item `Status` as `In Progress`
   - Re-read the issue and confirm the claim stuck before proceeding
   - If the issue is already claimed by your lane, treat this as resume and continue
   - If the issue is claimed by another lane, stop instead of competing
3. **Load context** — Read `project.md` for product vision, domain glossary, quality bar
4. **Readiness gate** — Run `/issue lint $1`:
   - Score >= 70: proceed
   - Score 50-69: run `/issue enrich $1` first, then re-lint
   - Score < 50: flag to user, attempt enrichment, re-lint
   - **Never skip an issue because it scored low — YOU make it ready**
5. **Intent gate** — Ensure issue has `## Product Spec` and `### Intent Contract`.
   If missing, invoke `/shape --spec-only $1` and re-check before coding.
6. **Design** — Invoke `/shape --design-only` if no `## Technical Design` section
7. **Build (TDD Enforced)** — Invoke `/build` and require RED→GREEN evidence per acceptance criterion:
   - RED: failing targeted tests before implementation
   - GREEN: same tests passing after implementation
   - If test harness is broken, stop and flag blocker (no implementation without explicit user bypass)
   - Delete compatibility scaffolding in greenfield/pre-user paths unless a real contract requires it
8. **Visual QA** — If diff touches frontend files (`app/`, `components/`, `*.css`), run `/visual-qa --fix`. Fix P0/P1 before proceeding.
9. **Agentic QA** — If diff touches prompts, model routing, tool schemas, or agent instructions, run `/llm-infrastructure` and inspect trace/eval coverage before shipping.
10. **Refine** — `/pr-fix --refactor`, update docs inline, then run simplification pass:
    - Preferred accelerator (if native in current harness): `/simplify`
    - Portable fallback (required): manual module-depth review + simplification edits using Ousterhout checks: shallow modules, information leakage, pass-throughs, and compatibility shims with no active contract
    - Optional accelerator: use an `ousterhout` persona/agent if the harness provides one
11. **Dogfood QA** — Run automated QA against local dev server (see Dogfood QA section below).
   Iterate until no P0/P1 issues remain. **Do not open a PR until QA passes.**
12. **Walkthrough** — Run `/pr-walkthrough` and produce the mandatory walkthrough package for the branch. Every PR needs an artifact, even if the change is internal or architectural.
13. **Commit** — Create semantic commits for all remaining changes:
    - Categorize files: commit, gitignore, delete, consolidate
    - Group into logical commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
    - Subject: imperative, lowercase, no period, ~50 chars. Body: why not what.
    - Run quality gates (`lint`, `typecheck`, `test`) before pushing
    - `git fetch origin && git push origin HEAD` (rebase if behind)
    - Never force push. Never push to main without confirmation.
14. **Ship** — Open a draft PR:
    - Stage and commit any uncommitted changes with semantic message
    - Read linked issue from branch name or recent commits
    - Re-run `python3 scripts/issue_lane.py --repo <owner/name> --issue <N>` immediately before opening the PR when available
    - Otherwise re-run the in-flight gate immediately before opening the PR
    - If an open PR already exists for the branch, use `gh pr edit`, not `gh pr create`
    - If another open PR already exists for the same issue, stop and surface the duplication instead of creating a second lane
    - Load `../pr/references/pr-body-template.md` and follow it
    - The `Walkthrough` section must link the artifact and name the persistent verification that protects the demonstrated path
    - PR body must contain all sections:
      - **Why This Matters**: Problem, value added, why now, issue link. This is top-of-line.
      - **Trade-offs / Risks**: Costs accepted, remaining concerns, why the trade is worthwhile.
      - **Intent Reference**: Copy/paste issue intent contract summary + link to source issue section.
      - **Changes**: Concise list of what was done. Key files/functions.
      - **Alternatives Considered**: Do nothing, credible alternative(s), and why current approach won.
      - **Acceptance Criteria**: From linked issue. Checkboxes.
      - **Manual QA**: Step-by-step verification. Commands, expected output.
      - **What Changed**: Mermaid flow chart for base branch, Mermaid flow chart for this PR, and a third Mermaid architecture/state/sequence diagram, plus explanation of why the new shape is better.
      - **Before / After**: Text description mandatory. Screenshots for UI changes. Use `<details>` for heavy evidence.
      - **Test Coverage**: Specific test files/functions. Note gaps.
      - **Merge Confidence**: Confidence level, strongest evidence, residual risk.
    - Keep deep sections under `<details>` where useful, but do not hide the topline significance/trade-off story
    - Use `--body-file` for `gh pr create`, `gh pr edit`, and PR comments
    - `gh pr create --draft --assignee phrazzld --body-file <path>`
    - Add context comment if notable decisions were made
15. **Retro** — Ensure `.groom/retro.md` exists first; initialize it with a minimal heading/template if missing. Then append implementation signals:
    ```
    mkdir -p .groom
    [ -f .groom/retro.md ] || cat > .groom/retro.md <<'EOF'
    # Retro Log

    Append one entry per delivered issue.
    EOF
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
| **Depth reviewer** | Run manual module-depth review, or `ousterhout` if available, commit |
| **Doc updater** | Update docs (README, ADRs, API docs), commit |

Lead sequences commits after all teammates finish. Then dogfood QA, then `/pr`.

Use when: substantial feature with multiple refinement needs.
Don't use when: small fix where sequential is fast enough.

If native batch dispatch is available in the harness (e.g. `/batch`), use it.
Otherwise launch teammates sequentially with normal agent calls.

## Stopping Conditions

Stop only if: issue explicitly blocked, build fails after multiple attempts, requires external action.

NOT stopping conditions: lacks description, seems big, unclear approach.

## Output

Report: issue worked, spec status, design status, TDD evidence (RED/GREEN), dogfood QA summary (issues found/fixed), walkthrough artifact summary, commits made, PR URL.

## Review Cadence

Agents accrete bloat when they keep extending stale mental models. Before each
new sprint or major chunk:

- Re-read the touched modules fully
- Look for compatibility shims added only to preserve old structure
- Simplify before adding the next layer
