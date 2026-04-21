# Durability & Resume (spellbook)

State is filesystem-backed, worktree-local, and resumable. SIGKILL,
power loss, and mid-phase crashes are recoverable via
`/deliver --resume <ulid>`. The escape-hatch wording here matches the
`.githooks/pre-commit` error message — keep them in sync.

## State Layout

```
<state-dir>/
├── state.json      # current_phase, completed_phases, item_id, branch, ulid
├── receipt.json    # written at exit — see receipt.md
├── review/         # /code-review transcripts (bench + thinktank + cross-harness)
└── ci/             # /ci logs (dagger call check per-gate tails; heal traces)
```

Default `<state-dir>` = `<worktree-root>/.spellbook/deliver/<ulid>/`.
The whole `.spellbook/` tree is gitignored; `state.json` and
`receipt.json` are additionally guarded by `.githooks/pre-commit`,
which refuses force-adds and prints:

```
These files are rewritten by /deliver and must never be human-edited.
If /deliver is stuck, use:
  /deliver --resume <ulid>    # continue the in-flight run
  /deliver --abandon <ulid>   # clear state, keep branch
```

## Checkpoint Protocol (atomic)

After every phase completes, `/deliver` rewrites `state.json`
atomically:

1. Serialize new state → `state.json.tmp`
2. `fsync` the file
3. `rename state.json.tmp state.json`
4. `fsync` the parent directory

POSIX atomic-rename guarantee: on any crash, `state.json` is either
the previous consistent state or the new one — never a torn write.

## Phase Idempotency

Every phase skill must be idempotent on partial runs:

- `/implement` re-runs tests on already-green code cheaply.
- `/code-review` re-reviews the current diff; writes a fresh
  `refs/verdicts/<branch>` entry tied to `git rev-parse HEAD`.
- `/ci` re-runs `dagger call check --source=.`; the Dagger engine
  caches container layers, so repeat runs are fast. Self-heal
  attempts are bounded per `/ci`'s policy, not re-tried on resume.
- `/refactor` re-computes the `master...HEAD` diff; no-op returns
  clean.

This is a contract on phase skills, not a guarantee `/deliver`
provides. See each phase skill's SKILL.md for explicit idempotency
clauses.

## `--resume <ulid>`

1. Load `<state-dir>/state.json`.
2. Skip phases in `completed_phases`.
3. Re-enter at `current_phase`.
4. Continue normally.

Typical trigger: the `.githooks/pre-commit` or `.githooks/pre-push`
hook noticed stale state, printed the escape hatches, and blocked the
user's commit. User reads the ULID from the hook output, runs
`/deliver --resume <ulid>`.

## `--abandon <ulid>`

1. Remove `<state-dir>` entirely.
2. Leave the `<type>/<slug>` branch as-is (unpushed, uncommitted
   changes if any).
3. Exit 0.

The human can delete the branch themselves (`git branch -D
<type>/<slug>`) or re-use it for a fresh `/deliver` invocation.

## Double-Invocation (exit 41)

`/deliver <item-id>` when a state-dir exists for that item with
`status: merge_ready`:

- **Exit 41** with the same escape-hatch message as the pre-commit
  hook: "already delivered; use `/deliver --resume <ulid>` or
  `/deliver --abandon <ulid>` or switch to a fresh branch".
- No silent re-run. No no-op.

This catches the common footgun of re-invoking after a successful
delivery and getting a confusing "why is this doing nothing"
experience.

## Interruption Guarantees

| Event | Guarantee |
|---|---|
| SIGINT | Trap writes `status: aborted`, exits 30 |
| SIGKILL | `state.json` remains last consistent checkpoint |
| Power loss | Same as SIGKILL — no torn writes |
| Mid-phase crash | `current_phase` records in-flight phase; resume re-runs it |

Resume-after-SIGKILL is part of the oracle: a test kills `/deliver`
mid-`/code-review`, then `/deliver --resume <ulid>` completes
delivery.
