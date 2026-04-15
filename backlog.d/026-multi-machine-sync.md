# Multi-machine sync for claims and verdicts

Priority: low
Status: pending
Estimate: M

## Goal

Enable `refs/verdicts/*` to sync across machines via `git push`/`git fetch`.
Verdicts (from 020) are local refs.

**Note (032):** Claim-based coordination was dropped when `/autopilot` was
renamed to `/deliver`. This ticket was originally scoped to sync claims +
verdicts; it now covers verdicts only. Kept alive as a design note for the
verdict-sync half. Retained claim-sync sections below are historical.

## Design

- Push verdicts: `git push origin 'refs/verdicts/*'`
- Fetch verdicts: `git fetch origin 'refs/verdicts/*:refs/verdicts/*'`
- Push claims: Extend `source scripts/lib/claims.sh` to use git refs instead
  of local file locks
- Conflict resolution: last-writer-wins for claims (agent coordination is
  best-effort), verdict refs are immutable once written

## Oracle

- [ ] Verdict created on machine A is visible on machine B after fetch
- [ ] Claim acquired on machine A blocks same claim on machine B
- [ ] Works with any git remote (not GitHub-specific)

## Non-Goals

- Real-time sync (polling/push is sufficient)
- Distributed consensus protocol
