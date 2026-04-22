# Branch & Workspace Ownership

`/deliver` operates on its own feature branch. Delivery is local work;
the branch is the unit of handoff to a human.

## HEAD Detection & Branch Creation

| HEAD state | `/deliver` action |
|---|---|
| Already on non-default branch | Use current branch |
| On `main` / `master` / `trunk` | Create `<type>/<slug>` from HEAD |
| Detached HEAD | Exit 40 — ambiguous starting state |

## Branch Naming

`<type>/<slug>` where:

- `<type>` is derived from the backlog item kind: `feat`, `fix`, `chore`,
  `refactor`, `docs`, `test`, `perf`
- `<slug>` is the item id (e.g. `feat/<item-id>`)

Item kind comes from the backlog file: its filename prefix or explicit
inference from the title.

## No-Commit-to-Default Invariant

`/deliver` **never** commits to `main`/`master`. Phase skills that would
commit run only after branch creation. If a phase skill's receipt
indicates it committed while HEAD was on default, that is a bug in the
phase skill — `/deliver` surfaces it as exit 10.

## No-Push Invariant

`/deliver` **never** runs `git push`. Delivery ≠ shipping.

- Human flow: `/deliver` → inspect receipt → human pushes & opens PR
- Outer-loop flow: `/deliver` → `/flywheel` outer reads receipt → the
  outer loop (not `/deliver`) decides when/whether to push

A phase skill that runs `git push` is a bug in that phase skill.

## No-Claim Invariant

Claim-based coordination is dropped entirely. The old `scripts/lib/`
acquire/release helper and its `refs/claims/*` storage are gone. Single
local workspace assumption.

Concurrent `/deliver` invocations on different items in **different
worktrees** are supported — see `worktree.md`. Concurrent `/deliver`
invocations on the **same item** produce the double-invoke behavior
(exit 41).

## Cleanup

`/deliver` does not clean up after itself. The feature branch persists.
State-dir persists until `--abandon`.

When invoked by `/flywheel` outer, the outer loop returns to a clean
base (`git switch main && git pull`) before the next cycle. That cleanup
is the outer loop's contract, not `/deliver`'s.
