---
name: verify-ac
user-invocable: false
description: |
  Machine-verify acceptance criteria against implementation by reading issue AC tags and running per-tag checks.
  Use from autopilot/pr-fix/pr-polish when gating commits or PRs against issue acceptance criteria.
---

# verify-ac

Machine-verifies `## Acceptance Criteria` from a GitHub issue body.

## Inputs

- Issue number (`#N`)
- Repository root path
- Optional scope notes (what changed in this diff)

## AC Tag Contract

Every AC line should be checkbox + tag:

```md
- [ ] [test] Given ..., when ..., then ...
- [ ] [command] Given ..., when ..., then ...
- [ ] [behavioral] Given ..., when ..., then ...
```

If an AC has no known tag, report `SKIPPED` with remediation text.

## Workflow

1. Read issue body:
   - `gh issue view N --json number,title,body`
2. Extract AC lines from `## Acceptance Criteria`.
3. Classify by tag.
4. Verify each AC via strategy table below.
5. Retry UNVERIFIED checks once (2 total attempts).
6. Emit report + gate decision.

## Verification Strategies

### `[test]`

- Build query keywords from the AC statement.
- Search tests only (`**/*test*`, `**/__tests__/**`, `**/*.spec.*`) with `rg`.
- Look for concrete assertion signal (`expect(`, `assert`, matcher names) aligned to AC intent.
- Output:
  - `VERIFIED` with file:line evidence
  - `UNVERIFIED` when no credible assertion evidence exists

### `[command]`

- Parse command and expected result from AC text.
- Run command with bounded execution (`timeout` required).
- Check:
  - exit status
  - expected output fragment(s) if specified
- Output:
  - `VERIFIED` with command + key output
  - `UNVERIFIED` with exit code/output mismatch

### `[behavioral]`

- Spawn an explore-style subagent to trace changed code paths and call sites.
- Ask for strict verdict with evidence:
  - path reached?
  - edge cases covered?
  - contradicting behavior found?
- Output:
  - `VERIFIED` only on high-confidence direct evidence
  - `PARTIAL` when path exists but confidence/coverage is incomplete
  - `UNVERIFIED` when behavior is absent or contradicted

## Hard Gate Policy

- Run up to 2 attempts for `UNVERIFIED` items.
- If any AC remains `UNVERIFIED` after attempt 2:
  - mark run as `FAILED`
  - return blocking message
  - caller (`/autopilot`, `/pr-fix`, `/pr-polish`) must not proceed to commit/ship

`PARTIAL` does not hard-fail by default, but must be reported.

## Output Format

```md
## AC Verification Report (#N)
- ✅ VERIFIED: [test] ... — evidence: path/to/file.test.ts:42
- ❌ UNVERIFIED: [command] ... — attempt 2/2, exit=1, expected="..."
- ⚠️ PARTIAL: [behavioral] ... — path exists, edge case coverage unclear
- ⏭️ SKIPPED: [unknown] ... — unsupported tag

Gate: FAILED
Reason: 1 AC remained UNVERIFIED after 2 attempts.
```

## Integration Points

- `/autopilot`: run after build/QA, before commit.
- `/pr-fix`: run in self-review phase before final push.
- `/pr-polish`: run before final PR handoff.

## Non-Goals

- Generating tests from ACs
- Auto-modifying product code to satisfy failed ACs
