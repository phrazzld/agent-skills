# Offline evidence and artifact storage in Git

Priority: medium
Status: pending
Estimate: M

## Goal

Replace GitHub releases/draft releases as the evidence storage mechanism with
a git-native `.evidence/` directory. QA screenshots, demo GIFs, review
artifacts, and agent trace logs all live in Git, keyed by branch name instead
of PR number.

## Why

Currently `/demo` uploads to GitHub draft releases keyed by `qa-evidence-pr-{N}`.
`/qa` stages to `/tmp/qa-{slug}/` then relies on `/demo upload` to push to GitHub.
Without a PR number, evidence is orphaned in `/tmp`. This breaks offline-first,
creates hard GitHub coupling, and makes evidence invisible to agents that can't
call `gh`.

PRs are human-visibility tools. Agent-first workflows need machine-queryable
auditability — structured files in Git, not comments on a web UI.

## Design

### Directory Structure

```
.evidence/
  <branch-slug>/
    <date>/
      qa-screenshot-01.png      # QA captures (LFS-tracked)
      qa-walkthrough.gif         # Demo GIF (LFS-tracked)
      qa-report.md               # QA findings + classifications
      review-synthesis.md        # Code review output from agent swarm
      verdict.json               # Review verdict (also stored as ref)
      trace.ndjson               # Agent activity log (tool calls, decisions)
```

### Key by Branch, Not PR

Branch name is the primary key. Evidence accumulates per-run (dated
subdirectories). On merge, the merge commit gets trailers:

```
QA-Evidence: .evidence/feat-foo/2026-04-06/
Reviewed-By: critic, ousterhout, carmack, grug, beck
Tested-By: qa-agent
```

### Binary Handling

- `.gitattributes` tracks `*.png`, `*.gif`, `*.webm` under `.evidence/` via LFS
- Text files (reports, verdicts, traces) are regular Git objects
- LFS requires a server for full binary retrieval, but pointer files survive
  clone and document what evidence exists

### Skill Integration

| Skill | Current | After |
|-------|---------|-------|
| `/qa` | Writes to `/tmp/qa-{slug}/` | Writes to `.evidence/<branch>/<date>/` |
| `/demo` | `gh release create` + `gh pr comment` | Writes to `.evidence/<branch>/<date>/`, no GitHub calls |
| `/demo upload` | Uploads to draft GitHub release | Commits `.evidence/` to branch, optional `git push` |
| `/settle` (git-native) | `gh pr view` for evidence | Reads `.evidence/<branch>/` for review artifacts |
| `/code-review` | Output in conversation only | Also writes `review-synthesis.md` + `verdict.json` |
| `/autopilot` | Invokes `/demo upload` to GitHub | Invokes `/demo` which writes locally |

### Cleanup

On merge via `/settle --land`:
- `.evidence/<branch>/` stays in history (auditable)
- Optionally: move to `.evidence/_archived/<branch>/` on master
- Or: `.evidence/` is gitignored on master, evidence only lives on feature branches
  and in merge commit history

### Trace Logging

`trace.ndjson` captures agent activity per-run:
```json
{"ts": "...", "agent": "critic", "action": "review", "finding": "shallow module in auth.py", "severity": "blocking"}
{"ts": "...", "agent": "qa", "action": "screenshot", "file": "qa-screenshot-01.png", "route": "/dashboard"}
```

This replaces PR comment threads as the audit trail. It's machine-queryable,
grep-friendly, and works offline.

## Oracle

- [ ] `/qa` writes captures to `.evidence/<branch>/<date>/` (not `/tmp`)
- [ ] `/demo` writes artifacts to `.evidence/` without GitHub API calls
- [ ] `.gitattributes` tracks binary evidence via LFS
- [ ] `/code-review` writes `review-synthesis.md` + `verdict.json` to `.evidence/`
- [ ] Merge commit includes `QA-Evidence:` trailer linking to evidence directory
- [ ] Evidence is retrievable from a fresh clone (pointer files at minimum)
- [ ] Works fully offline (no network calls during evidence capture/storage)
- [ ] `/settle` git-native mode reads evidence from `.evidence/`

## Implementation Sequence

1. Add `.gitattributes` LFS rules for `.evidence/**/*.{png,gif,webm}`
2. Update `/qa` to write to `.evidence/<branch>/<date>/` instead of `/tmp`
3. Update `/demo` to write locally, remove `gh release create` path
4. Update `/code-review` to write synthesis + verdict to `.evidence/`
5. Update `/settle` git-native mode to read from `.evidence/`
6. Add trailer injection to `/settle --land` merge commit
7. Update `/autopilot` to skip `gh pr comment` evidence embedding

## Non-Goals

- Building a web UI or TUI for browsing evidence (just files in git)
- Replacing `.groom/review-scores.ndjson` (that's a cross-branch aggregate)
- Automatic LFS server setup (user's responsibility)
- Removing GitHub release upload entirely (keep as optional for repos that use PRs)
