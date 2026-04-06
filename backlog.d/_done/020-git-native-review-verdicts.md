# Git-native review verdicts — replace PR approval state

Priority: high
Status: done
Estimate: M

## Goal

Create a git-native mechanism for storing code review verdicts as Git objects,
replacing GitHub PR approval as the proof-of-review. This is the keystone
primitive that unlocks Dagger-only CI, default swarm review, and offline
development.

## Design

Store verdicts under `refs/verdicts/<branch>`:
```json
{
  "branch": "feat-foo",
  "base": "master",
  "verdict": "ship",
  "reviewers": ["critic", "ousterhout", "carmack", "grug", "beck"],
  "scores": {"correctness": 8, "depth": 7, "simplicity": 9, "craft": 8},
  "sha": "abc123",
  "date": "2026-04-06T15:00:00Z",
  "evidence": ".evidence/feat-foo/2026-04-06/"
}
```

### Implementation

```bash
# Write verdict
echo '<json>' | git hash-object -w --stdin  # → blob SHA
git update-ref refs/verdicts/feat-foo <blob-sha>

# Read verdict
git cat-file -p refs/verdicts/feat-foo

# Sync
git push origin 'refs/verdicts/*'
git fetch origin 'refs/verdicts/*:refs/verdicts/*'

# Validate before merge
verdict_sha=$(git cat-file -p refs/verdicts/feat-foo | jq -r .sha)
head_sha=$(git rev-parse feat-foo)
[ "$verdict_sha" = "$head_sha" ] || echo "HEAD moved since review"
```

### Helper Script

`scripts/lib/verdicts.sh` — thin shell library (like `claims.sh`):
- `verdict_write <branch> <json>` — create/update verdict ref
- `verdict_read <branch>` — print verdict JSON
- `verdict_validate <branch>` — check verdict exists and SHA matches HEAD
- `verdict_delete <branch>` — clean up after merge
- `verdict_list` — list all verdict refs

## Integration Points

- `/code-review` writes verdict ref after synthesizing reviewer scores
- `/settle` git-native mode reads verdict ref to gate merge
- `.evidence/<branch>/verdict.json` is a copy for browsability (ref is authoritative)
- Pre-merge hook validates verdict ref exists and SHA matches HEAD
- `git push origin refs/verdicts/*` syncs verdicts across machines

## Oracle

- [x] `verdict_write` creates a valid ref under `refs/verdicts/<branch>`
- [x] `verdict_read` returns valid JSON with all required fields
- [x] `verdict_validate` returns 0 when SHA matches HEAD, non-zero otherwise
- [x] `verdict_validate` returns non-zero when no verdict exists
- [ ] Verdict refs survive `git push`/`git fetch` across remotes (needs remote test)
- [x] `/code-review` calls `verdict_write` after synthesizing scores (skill instruction added)
- [ ] Pre-merge hook calls `verdict_validate` and blocks without valid verdict (tracked by 022)

## What Was Built

- `scripts/lib/verdicts.sh` — thin shell library (5 functions, ~60 LOC) matching
  `claims.sh` pattern. Stores verdicts as JSON blobs under `refs/verdicts/<branch>`.
- `scripts/lib/test_verdicts.sh` — 11 tests covering write, read, validate, delete,
  list, JSON validation, and required field enforcement.
- `/code-review` SKILL.md updated with "Verdict Ref" section — records verdict
  after every review. Gracefully skips if verdicts.sh absent in target project.

Remaining oracle items are tracked by downstream backlog items (022, 026).

## Non-Goals

- Human dispute resolution (separate item)
- Multi-repo federation
- Web UI for verdict browsing
- Replacing `.groom/review-scores.ndjson` (that's aggregate; verdicts are per-branch)
