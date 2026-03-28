# git-bug: distributed git-native issue tracking + agent coordination

Priority: high
Status: in-progress
Estimate: M

## Goal
Issues live in git as objects, not in GitHub's database. Agents read/write issues via CLI.
GitHub Issues becomes a read-only bridge for human visibility. Agents coordinate via
atomic claims so two agents never work the same issue.

## Non-Goals
- Don't migrate all historical GitHub Issues
- Don't build a custom issue tracker
- Don't break existing backlog.d/ pattern (git-bug complements it)

## Oracle
- [ ] `git bug` CLI installed and configured
- [ ] Bridge to GitHub configured (git-bug push/pull syncs with GitHub Issues)
- [ ] Agents can create, query, and close issues via `git bug` commands
- [ ] Claim protocol works: `git update-ref refs/claims/<id>` atomic CAS
- [ ] `/autopilot` claims item before spawning builder; `/groom` skips claimed items
- [ ] New `/debug` findings auto-create git-bug issues
- [ ] Issues travel with repo clone (no API calls needed to read)

## Notes
- git-bug stores issues as git objects (not files), with Lamport timestamps for CRDT merging
- git-bug has NO assignee concept — use labels (`wip:agent-id`) + `refs/claims/` for coordination
- Bridges to GitHub/GitLab for human visibility
- Offline-first — works in CI, sandboxes, locally without network
- backlog.d/ = shaped work ready to build. git-bug = raw issues, bugs, requests
- Coordination: `git update-ref refs/claims/<id> $HASH ""` is atomic CAS within shared .git.
  All worktrees see claims instantly. For multi-machine: push-gate the ref.
- Cursor's lesson: peer coordination fails at scale. Hierarchical (planner assigns) wins.
- Research: https://github.com/git-bug/git-bug
