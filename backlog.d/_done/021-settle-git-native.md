# Evolve /settle for git-native workflow

Priority: high
Status: done
Estimate: M

## Goal

Make `/settle` (and its `/land` alias) work without GitHub PRs. Currently
every phase assumes a GitHub PR exists — `gh pr view`, review threads, draft
release evidence uploads. The git-native path should use verdict refs (from 020),
local Dagger CI, and git-native evidence storage instead.

## What Changes

1. **Phase 1 (Fix)**: Replace `gh pr view --json reviews,statusCheckRollup`
   with verdict ref check + `dagger call check`. Review comments come from
   local agent swarm output, not GitHub threads.
2. **Phase 2 (Polish)**: No change needed (already branch-focused).
3. **Phase 3 (Refactor)**: No change needed.
4. **Evidence upload**: Replace GitHub draft release uploads with git-native
   storage (see 024).
5. **Merge step**: When invoked as `/land`, validate verdict ref exists and
   SHA matches HEAD, run Dagger, then `git merge --no-ff`.
6. **Anti-patterns**: Update "Never call `gh pr merge`" to "Never merge without
   a valid verdict ref."

## Key Constraint

`/settle` must work in BOTH modes:
- **GitHub mode**: When a PR exists, use existing GitHub workflow (backwards compat)
- **Git-native mode**: When no PR exists, use verdict refs + Dagger + local review

Detection: if `$ARGUMENTS` is a PR number or `gh pr view` succeeds, use GitHub
mode. Otherwise, git-native mode.

## Oracle

- [ ] `/settle` on a branch with no GitHub PR uses git-native path
- [ ] `/settle` on a branch with a GitHub PR uses existing GitHub path
- [ ] `/land feat-foo` validates verdict ref, runs Dagger, merges
- [ ] `/land` refuses without verdict ref (clear error message)
- [ ] `/land` refuses if HEAD moved since verdict was recorded
- [ ] Evidence stored without GitHub API calls in git-native mode

## Oracle

- [x] `/settle` on a branch with no GitHub PR uses git-native path
- [x] `/settle` on a branch with a GitHub PR uses existing GitHub path
- [x] `/land feat-foo` validates verdict ref, runs Dagger, merges
- [x] `/land` refuses without verdict ref (clear error message)
- [x] `/land` refuses if HEAD moved since verdict was recorded
- [x] Evidence stored without GitHub API calls in git-native mode

## What Was Built

Pure skill instruction changes across 3 files:
- **SKILL.md**: Mode Detection section (GitHub vs git-native), dual-mode Phase 1,
  dual-mode Reviewer Artifact Policy, updated description/triggers, `/land` alias
  always uses git-native mode
- **pr-fix.md**: Dual-mode CI diagnosis sequence, dual-mode async settlement,
  dual-mode merge-readiness gate with verdict_validate
- **pr-polish.md**: Dual-mode evidence storage (GitHub releases vs .evidence/)

## Non-Goals

- Removing GitHub mode entirely (keep for repos that use PRs)
- Automatic push after merge (human decides)
