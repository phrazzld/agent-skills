---
name: pr-fix
description: |
  Unblock a PR: resolve conflicts, fix CI, self-review, address feedback, refactor.
  One command takes a blocked PR to green and mergeable.
  Use when: PR blocked, CI red, unaddressed reviews, code review needed, refactoring.
  Trigger: /pr-fix, /fix-ci, /review-branch, /review-and-fix, /respond, /address-review, /refactor.
argument-hint: "[PR-number]"
---

# /pr-fix

One command takes a blocked PR to green.

## Role

Senior engineer unblocking a PR. Methodical, not reactive. Each phase resolves a class of blocker in dependency order.

## Objective

Take PR `$ARGUMENTS` (or current branch's PR) from blocked to mergeable: no conflicts, CI green, reviews addressed, and **all open conversations on the PR resolved**.
`dogfood`, `agent-browser`, and `browser-use` are available in this environment for user-flow verification.

## Dependency Order

Conflicts -> CI -> Self-Review -> Reviews. Can't run CI on conflicted code. Can't review broken code. Can't address others' reviews before fixing your own issues.

## LLM-First Implementation Rule (Mandatory)

For semantic fixes (classification/triage logic, intent inference, severity mapping, reviewer synthesis), prefer LLM reasoning over deterministic heuristics.

Do not add heuristic-only semantic classifiers (regex-only labels, keyword score trees) unless the task is strictly syntactic.

Keep deterministic code for mechanical guarantees only: schema contracts, exact format parsing, permissions/safety enforcement.

## Bounded Shell Output (MANDATORY)

- Size before detail: counts/metadata first
- Never print unbounded logs/comments
- Add explicit bounds: `--limit`, `head -n`, `tail -n`, `per_page`
- If no useful signal in 20s: abort, narrow, rerun
- Use `~/.claude/scripts/safe-read.sh` for large local files

## Workflow

### 1. Assess

```bash
gh pr view $PR --json number,title,headRefName,baseRefName,mergeable,reviewDecision,statusCheckRollup
gh pr checks $PR --json name,state,startedAt,completedAt,link
gh pr view $PR --json body --jq '.body | split("\n")[:80] | join("\n")'
```

Read PR description and linked issue. Understand **what this PR is trying to do** — semantic context drives conflict resolution and review decisions.

Fetch latest base:

```bash
BASE="$(gh pr view $PR --json baseRefName --jq .baseRefName)"
git fetch origin "$BASE"
```

Determine blockers: conflicts? CI failures? pending reviews? Build a checklist.

### 2. Resolve Conflicts

**Skip if**: `mergeable != CONFLICTING`

Rebase onto base branch:

```bash
git rebase "origin/$BASE"
```

When conflicts arise, resolve **semantically based on PR purpose**, not mechanically:

- Read both sides. Understand intent.
- Preserve the PR's behavioral changes. Integrate upstream structural changes.
- Reference `git-mastery/references/conflict-resolution.md` for strategies.
- Never blindly accept ours/theirs.

After resolution, verify locally:

```bash
git rebase --continue
# Run project's test/typecheck commands
```

### 3. Fix CI

**Skip if**: all checks passing.

Push current state and diagnose CI failures:

```bash
git push --force-with-lease
gh run list --limit 5 --json databaseId,workflowName,status,conclusion,headBranch
gh run view <run-id> --log-failed | tail -n 200
```

Classify failure type (Code Issue / Infrastructure / Flaky / Config), identify root cause,
fix the code. See `references/fix-ci.md` for the full CI diagnosis procedure.

If CI fixes create new conflicts: return to Phase 2 (max 2 full-pipeline retries).

### 4. Self-Review the Diff

**Always run this phase.** CI passing does not mean the code is good. Linters catch syntax; this catches logic.

Review the full diff against base:

```bash
BASE="$(gh pr view $PR --json baseRefName --jq .baseRefName)"
git diff "origin/$BASE"...HEAD
```

For each changed file, check for:

- **Dead code**: unused variables (especially `_`-prefixed params that signal "I know this is unused"), unreachable branches, useMemo/useCallback with values never read
- **Logic bugs**: loops that always break on first iteration, conditions that are always true/false, off-by-one errors
- **Wasted computation**: expensive operations whose results are discarded, duplicate work (e.g., running the same test suite twice in CI)
- **Wrong log levels**: success messages on stderr (`console.warn`/`console.error`), debug output on stdout in production
- **Semantic mismatches**: function names that don't match behavior, comments that contradict code

Fix every issue found. Run typecheck + tests after fixes. Commit before proceeding.

This phase catches what CI cannot: code that compiles and passes tests but is wrong, wasteful, or misleading. A PR that's "green" but ships dead code or wasted computation is not actually unblocked — it's shipping tech debt.

### 5. Address Reviews

**Exit criterion for this phase:** the PR has zero unresolved review threads and zero remaining actionable open conversations. Do not call the PR unblocked while any conversation is still open.

**Skip condition**: ALL THREE of these are zero: unresolved review threads, unreplied review comments, AND unaddressed bot issue comments. Use the queries below — never rely on `reviewDecision` alone or prior "PR Unblocked" summary comments.

```bash
OWNER="$(gh repo view --json owner --jq .owner.login)"
REPO="$(gh repo view --json name --jq .name)"

# Count unresolved review threads (inline comments)
UNRESOLVED_THREADS="$(gh api graphql -f query='
  query($owner:String!, $repo:String!, $number:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$number){
        reviewThreads(first:100){nodes{isResolved}}
      }
    }
  }' -F owner="$OWNER" -F repo="$REPO" -F number="$PR" \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)] | length')"
```

#### 5a. Bot issue comments (MANDATORY)

**Why this exists:** Some bot reviewers (Claude, CodeRabbit, etc.) post review feedback as **issue comments** (`/issues/$PR/comments`), not pull request review comments (`/pulls/$PR/comments`). These are a completely different API endpoint and are invisible to the GraphQL `reviewThreads` query. Missing them means missing actionable review feedback.

```bash
# Fetch bot issue comments — these are NOT in reviewThreads or PR comments
BOT_COMMENTS="$(gh api "repos/$OWNER/$REPO/issues/$PR/comments?per_page=100" --paginate \
  --jq '[.[] | select(.user.type == "Bot") | {id, user: .user.login, body: .body}]')"
```

Filter for comments that contain actionable review feedback (code suggestions, bug findings, security concerns). Ignore:
- Status/summary comments (CI reports, merge readiness checks)
- Comments you've already replied to with fixes
- Informational comments with no action items

For each bot comment with actionable findings:
1. **Read the FULL comment body** — no truncation
2. **Extract each finding** — bots typically number them or use headers
3. **Read the current file** to check if already addressed
4. **Fix or defer** each finding (same as review comments below)
5. **Reply to the comment** with resolution status for each finding

If an `Auto PR Feedback Digest` exists in context, use it only as triage seed. Always refresh live GitHub data before final replies.

#### 5b. Review comments and threads

**Independent verification (MANDATORY)**

**Never trust prior session comments, "PR Unblocked" summaries, or claims that feedback was addressed.** For EVERY open review comment:

1. **Read the FULL comment body** — no truncation. Use the GitHub API without `.body[:N]` limits.
2. **Read the current file at the referenced line** to verify the fix is actually present.
3. **Reply directly on the comment thread** with the specific commit SHA and line confirming the fix. An open thread without a reply = unaddressed, regardless of what a summary comment claims.

```bash
# Fetch ALL review comments with full bodies — never truncate
gh api "repos/$OWNER/$REPO/pulls/$PR/comments?per_page=100" --paginate \
  --jq '.[] | {id, user: .user.login, path, line, body, in_reply_to_id}'
```

For each comment without a reply from this PR's author:
- If **already fixed in code**: reply with commit SHA + current line reference confirming the fix
- If **needs fixing**: fix it, then reply with commit SHA
- If **deferred**: reply with follow-up issue number
- If **declined**: reply with public reasoning

Bot feedback (CodeRabbit, Gemini, Codex, and other reviewer bots) gets the same treatment as human feedback.

#### Execution

1. **Categorize feedback** — Sort into critical / in-scope / follow-up / declined. Post transparent assessment to PR. Reviewer feedback CAN be declined with public reasoning. See `references/respond.md` for the full transparency workflow.

2. **Classify and set severity** — For every actionable comment, record:
   - Classification: `bug | risk | style | question`
   - Severity: `critical | high | medium | low`
   - Decision: `fix now | defer | reject` with reason
   Policy:
   - `critical/high`: fix now by default
   - `medium`: fix now or open follow-up issue with rationale
   - `low`: optional

3. **TDD fixes** — For critical and in-scope items: write failing test, fix, verify pass, commit. Create GitHub issues for follow-up items. See `references/address-review.md` for the TDD fix procedure and `references/scope-rules.md` for in-scope vs out-of-scope guidance.

4. **Reply to every open thread** — use `gh api repos/$OWNER/$REPO/pulls/$PR/comments/$ID/replies -f body='...'` so the thread shows addressed.
   Reply format:
   - `Classification: <bug|risk|style|question>`
   - `Severity: <critical|high|medium|low>`
   - `Decision: <fix now|defer|reject>. <reason>`
   - `Change: <what changed>`
   - `Verification: <tests/checks run or N/A>`

5. **Resolve every thread via GraphQL** — Replies alone do NOT resolve threads. Non-outdated comments stay visible as open issues to reviewers even after fixing the code and replying. You MUST resolve them. The phase is incomplete until the unresolved thread count is `0`:

```bash
# Get unresolved thread IDs
gh api graphql -F owner="$OWNER" -F repo="$REPO" -F number=$PR -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes { id isResolved isOutdated }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .id'

# Resolve each thread
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "THREAD_ID"}) { thread { isResolved } } }'
```

Additive commits do NOT make comments outdated. Only changes to the diff hunk a comment is attached to trigger outdating. Resolve explicitly.

### 6. Verify and Push

```bash
git push --force-with-lease
```

Watch checks. If a phase-4 or phase-5 fix broke CI, re-run the CI diagnosis (Phase 3) again (count toward 2-retry max).

If 2 full retries exhausted: stop, summarize state, ask user.

### 6b. Dogfood + Browser Flow Verification (MANDATORY for user-facing diffs)

If fixes touch UI or user behavior (`app/`, `components/`, styles, route handlers, auth, checkout, onboarding):

1. Run `/dogfood http://localhost:3000` before calling PR mergeable
2. Fix P0/P1 findings, rerun on affected scope
3. Use `agent-browser` / `browser-use` for targeted repro, screenshot evidence, and regression checks

`/dogfood` is a skill command, not a shell binary probe.

### 7. Update PR Description with Before / After + Walkthrough

Edit the PR body to preserve the richer `/pr` structure and update the relevant sections documenting the fix.
Refresh the `## Walkthrough` section too when the fix changes the merge case, evidence, or protecting check:

```bash
# Get current body, refresh the affected sections
gh pr edit $PR --body "$(updated body)"
```

Before editing, read `../pr/references/pr-body-template.md`.

Do not only append text. Refresh:
- `Why This Matters` if the fix changed the PR's significance
- `Trade-offs / Risks` if the fix changed reviewer concerns
- `What Changed` diagrams if the final implementation shape drifted
- `Before / After` evidence for the blocked vs unblocked state

**Text (MANDATORY)**: Describe the blocked state (before) and the unblocked state (after).
Example: "Before: CI failing on type error in auth module. After: Types corrected, CI green."

**Screenshots (when applicable)**: Capture before/after for any visible change — CI status pages, error output, UI changes from review fixes. Use `![before](url)` / `![after](url)`.

Skip screenshots only when all fixes are purely internal (conflict resolution with no behavior change, CI config fixes with no visible output difference).

If the fixes materially change what reviewers should see, rerun `/pr-walkthrough` and update:

- Artifact
- Claim
- Before / After scope
- Persistent verification
- Residual gap

### 8. Signal

Post summary comment on PR:

```bash
gh pr comment $PR --body "$(cat <<'EOF'
## PR Unblocked

**Conflicts**: [resolved N files / none]
**CI**: [green / was: failure type]
**Reviews**: [N fixed, N deferred (#issue), N declined (see above)]

Ready for re-review.
EOF
)"
```

## Retry Policy

Max 2 full-pipeline retries when fixing one phase breaks another. After 2: stop and escalate to user with clear status.

## Anti-Patterns

- Mechanical ours/theirs conflict resolution
- Pushing without local verification
- Silently ignoring review feedback
- Retrying CI without understanding failures
- Fixing review comments that should be declined
- **Trusting prior "PR Unblocked" or summary comments** — always verify each comment against current code independently. A previous session claiming "fixed" means nothing until you read the file yourself.
- **Leaving review threads without direct replies** — an open thread with no reply = unaddressed, even if the code is fixed. Reviewers can't see that you checked.
- **Truncating comment bodies** — never use `.body[:N]` when fetching review comments. The actionable detail is often at the end of long comments.
- **Replying without resolving** — a reply on a thread does NOT resolve it. Non-outdated threads with replies still show as open conversations. Use `resolveReviewThread` GraphQL mutation after replying.
- **NEVER lowering quality gates to pass CI** — coverage thresholds, lint rules, type strictness, security gates. If a gate fails, write tests/code to meet it. Moving the goalpost is not a fix. This is an absolute, non-negotiable rule.
- **Skipping self-review because CI is green** — CI catches syntax and test failures. Dead code, wasted computation, wrong log levels, and semantic mismatches all pass CI. Review the diff yourself before declaring unblocked.
- **Only checking review threads and PR comments** — bot reviewers (Claude, CodeRabbit, etc.) often post feedback as issue comments (`/issues/$PR/comments`), not PR review comments (`/pulls/$PR/comments`). These are different API endpoints. You MUST check all three: GraphQL reviewThreads, REST PR comments, AND REST issue comments.

## Output

Summary: blockers found, phases executed, conflicts resolved, CI fixes applied, reviews addressed/deferred/declined, final check status, and explicit confirmation that open conversation count is zero.

## Absorbed Skills (References)

These skills are consolidated here. Their full content is in `references/`:

- **fix-ci** — [references/fix-ci.md](./references/fix-ci.md) — CI failure classification and resolution
- **review-branch** — [references/review-branch.md](./references/review-branch.md) — Multi-reviewer code review orchestration
- **code-review-checklist** — [references/code-review-checklist.md](./references/code-review-checklist.md) — Checklist for purpose, quality, correctness, security, performance, testing
- **respond** — [references/respond.md](./references/respond.md) — Transparent PR review feedback response workflow
- **address-review** — [references/address-review.md](./references/address-review.md) — TDD-based review finding resolution
- **refactor** — [references/refactor.md](./references/refactor.md) — Two-pass code refinement (clarity then architecture)
- **reviewer-prompts** — [references/reviewer-prompts.md](./references/reviewer-prompts.md) — Prompt templates for AI reviewers
- **scope-rules** — [references/scope-rules.md](./references/scope-rules.md) — In-scope vs out-of-scope guidance
- **tdd-fix-pattern** — [references/tdd-fix-pattern.md](./references/tdd-fix-pattern.md) — TDD fix workflow
- **deferred-issue** — [references/deferred-issue.md](./references/deferred-issue.md) — Template for deferred GitHub issues
