# Worktree Behavior (spellbook)

`/deliver` supports concurrent invocations across git worktrees with
zero interference and no global locks. This is the whole reason
claims were dropped (see `backlog.d/_done/032`, enforced by the
`check-no-claims` gate).

## State Root Resolution

State root is computed per-invocation as:

```
$(git rev-parse --show-toplevel)/.spellbook/deliver/
```

In a linked worktree, `git rev-parse --show-toplevel` returns the
**worktree's** root, not the primary clone's. Every worktree has its
own `.spellbook/deliver/` tree.

This matches spellbook's self-containment invariant: state roots
anchor to the invoking project's toplevel, never to the skill's
install dir or a hardcoded `$HOME` path. The `check-portable-paths`
gate catches the common regression (hardcoded `/Users/<name>/` or
`C:\Users\`).

## Concurrent Worktrees

Two worktrees of the spellbook clone can each run `/deliver` on
different `<type>/<slug>` branches concurrently:

- Separate `<ulid>`s (ULIDs are process-local and monotonic;
  collisions are not possible).
- Separate `<worktree>/.spellbook/deliver/<ulid>/` state directories.
- Separate receipts.
- No cross-worktree file contention.

Coordination is via git branches, not file locks. The primary clone
and a `git worktree add ../spellbook-wt feat/something` share git
objects but nothing in `.spellbook/`.

## What's Not Supported

- **Same-worktree concurrent `/deliver`:** running `/deliver` twice
  in the same worktree on the same item exits 41 (double-invoke).
  Running on different items simultaneously works but the branch
  logic gets confusing — prefer serial execution.
- **Network filesystems with weak rename semantics:** the atomic
  checkpoint protocol assumes POSIX rename. NFS without
  close-to-open consistency may lose writes. Not a supported config.
- **Disposable worktree as global bootstrap source:** if a contributor
  bootstraps `~/.claude` from a temporary `git worktree add` path
  and later removes the worktree, every harness symlink dangles.
  `CLAUDE.md` warns against this; pin `SPELLBOOK_DIR` to a stable
  checkout. Not `/deliver`'s concern directly but worth flagging
  when resuming into a vanishing path.

## Verification

The `/deliver` oracle verifies:

> worktree-A and worktree-B each run `/deliver` on different
> `<type>/<slug>` branches concurrently; both produce independent
> merge-ready receipts under their respective
> `<worktree>/.spellbook/deliver/<ulid>/` trees.

If that check fails, the state-root resolution is broken — likely
someone hardcoded `$HOME/.spellbook/` or the primary clone's `.git/`
path. The `check-portable-paths` gate should have caught it.
