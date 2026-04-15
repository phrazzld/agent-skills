# End-to-end offline validation test

Priority: low
Status: blocked
Estimate: S

Blocked on 024 (`.evidence/` storage) — can't validate end-to-end offline
without the storage layer it exercises.

## Goal

Prove the git-native, offline-first workflow actually works end-to-end without
any network access. Run the full cycle in airplane mode:

1. Create a feature branch
2. Make changes
3. Run Dagger CI locally
4. Run agent swarm code review
5. Store review verdict in Git
6. Land the branch via `/land`
7. File/close issues via git-bug

## Why

Individual pieces may work offline, but the integrated workflow hasn't been
validated. Docker images need to be pre-pulled. thinktank needs network for
external providers. What's the actual offline boundary?

## Oracle

- [ ] Full workflow completes with network disabled (after initial setup)
- [ ] List of components that require network, with offline alternatives documented
- [ ] Dagger images pre-pullable for offline use
- [ ] Fallback: single-model review when multi-provider is unavailable

## Non-Goals

- Making everything work offline (some things need network — document them)
- Automated CI for this test
