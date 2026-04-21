# Branch & Workspace Ownership (spellbook)

`/deliver` operates on its own `<type>/<slug>` feature branch. Delivery
is local work; the branch is the unit of handoff to a human (or to
`scripts/land.sh` when the human chooses to land).

## HEAD Detection & Branch Creation

| HEAD state | `/deliver` action |
|---|---|
| Already on non-`master` branch | Use current branch |
| On `master` | Create `<type>/<slug>` from HEAD |
| Detached HEAD | Exit 40 — ambiguous starting state |

Spellbook's base branch is **`master`**, not `main`. Phase skills that
hardcode `main` produce wrong diffs; treat that as dirty output.
`/code-review` computes `git diff master...HEAD`; `/refactor`'s
feature-branch mode uses the same base.

## Branch Naming

`<type>/<slug>` where `<type>` is one of:

- `feat/*` — new skill, new gate, new hook, new agent
- `fix/*` — bug fix in a skill, script, gate, or hook
- `chore/*` — bootstrap/index/registry housekeeping
- `refactor/*` — simplification of an existing skill or the Dagger
  module (`ci/src/spellbook_ci/main.py`)
- `docs/*` — `CLAUDE.md`, `harnesses/shared/AGENTS.md`,
  `backlog.d/*.md`

`<slug>` is the backlog id (e.g. `feat/023-review-score-feedback-loop`)
or a short kebab-case title for `git-bug` issues lacking a backlog
entry. Current in-flight example: `feat/tailor-harden`.

Type is inferred from the backlog filename prefix, a `type/*` label on
a `git-bug bug`, or the title if both are absent.

## No-Commit-to-`master` Invariant

`/deliver` **never** commits to `master`. Phase skills that commit run
only after branch creation. If a phase skill's receipt indicates it
committed while HEAD was on `master`, that is a bug in the phase skill
— `/deliver` surfaces it as exit 10.

## No-Push Invariant

`/deliver` **never** runs `git push`. Delivery ≠ shipping.

- Human flow: `/deliver` → inspect `receipt.json` → human runs
  `scripts/land.sh` or pushes + opens PR.
- Outer-loop flow: `/deliver` → `/flywheel` reads the receipt →
  `/flywheel` decides when/whether to push.

A phase skill that runs `git push` is a bug in that phase skill.
Note: `scripts/land.sh` is explicitly human-invoked; it is not a phase
and must not be called from any `/deliver` phase.

## No-Claim Invariant

Claim-based coordination was dropped per `backlog.d/_done/032` and
enforced by the `check-no-claims` gate (`claims.sh`, `claim_acquire`,
`claim_release` forbidden anywhere under `skills/`). Single local
workspace assumption.

Concurrent `/deliver` invocations across git worktrees are supported —
see `worktree.md`. Concurrent invocations on the **same item** yield
double-invoke behavior (exit 41).

## Pre-merge Gate

When the human runs `scripts/land.sh` (or `git merge --no-ff`), the
`.githooks/pre-merge-commit` hook runs the verdict gate against
`refs/verdicts/<branch>`. The escape hatch is `SPELLBOOK_NO_REVIEW=1`
— but `/deliver` never sets it. If review is missing at merge time,
that's the human's choice, not a delivery failure.

## Cleanup

`/deliver` does not clean up after itself. The `<type>/<slug>` branch
persists. State-dir persists until `--abandon <ulid>`.

When invoked by `/flywheel` outer, the outer loop returns to a clean
base (`git switch master && git pull`) before the next cycle. That
cleanup is the outer loop's contract, not `/deliver`'s.
