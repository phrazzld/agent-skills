# Phase 2: Polish — elevate quality (spellbook)

Elevate a working branch from "gate green" to "exemplary." Phase 2 of
`/settle`.

## Hindsight architecture review

Read the full diff with one question: **"Would we build it the same way
starting over?"**

Don't defend sunk cost. The code exists; evaluate it as a proposal.

### General smell catalog

**Shallow modules** — interface as complex as implementation; the module
hides nothing. Merge with caller, or deepen by absorbing related logic.

**Pass-through layers** — methods that forward with no judgment. Each
adds cognitive cost, no value. Eliminate the middleman.

**Hidden coupling** — two modules that must change together but don't
declare a dependency. Make it explicit (shared type, interface) or
eliminate it.

**Temporal decomposition** — organization by *when* things happen rather
than *what information* they manage. Reorganize around information
hiding.

**Missing abstractions** — same multi-step pattern in 3+ places.
Extract, but only after the pattern is stable (rule of three).

**Premature abstractions** — generic framework for one use case. Inline
it. Concreteness is a virtue until you have evidence for abstraction.

**Tests testing implementation** — mocking internals, asserting on call
counts, breaking when refactoring. Rewrite to assert on observable
behavior through public interfaces.

### Spellbook-specific smells

- **SKILL.md > 500 lines.** Extract to `references/<topic>.md`. Hard
  limit enforced by `check-frontmatter`.
- **Skill escapes its tree.** `../..`, `$REPO_ROOT/…`, hardcoded paths
  to the install dir. Breaks on symlink install. Libs must resolve via
  `readlink -f` + `$SCRIPT_DIR/lib/…`; state roots anchor to
  `git rev-parse --show-toplevel` of the *invoking* project.
- **`references/<repo-name>.md` sidecar.** Repo-specific content belongs
  in SKILL.md body. Stack-specific (`references/convex-patterns.md`) is
  fine. Repo-shaped (`references/spellbook.md`) is not.
- **Claim-coordination primitives under `skills/`.** `claims.sh`,
  `claim_acquire`, `claim_release` are dropped per `backlog.d/032/`.
  Guarded by `check-no-claims`.
- **Raw `dagger call check`, `bunx playwright`, or bench-agent dispatch
  inside `skills/deliver/SKILL.md`.** Composition violation. `/deliver`
  must compose atomic phase skills via trigger syntax only. Guarded by
  `check-deliver-composition`.
- **Hardcoded `/Users/<name>/` or `C:\Users\`** outside
  `harnesses/claude/` + `.claude/hooks`. Guarded by
  `check-portable-paths`.
- **Seed/tailor copy logic that only targets Claude.** Guarded by
  `check-harness-install-paths`. Cross-harness Red Line.
- **Manual `index.yaml` edits.** The pre-commit hook regenerates it.
  Hand edits are churn or drift — revert and let the hook run.
- **`harnesses/claude/settings.json` changes that expect a symlink.**
  Bootstrap *copies* that file (Claude mutates it at runtime). Changes
  require a re-bootstrap to land.

### Applying the review

For each smell:
1. Name it and the affected files.
2. Severity: blocking (fix now) vs advisory (note, track).
3. Blocking smells fixed in Phase 2. Advisory smells get a `backlog.d/`
   entry or git-bug issue.

## Test audit

### Coverage gaps

Which paths have no test? Prioritize:
- Error paths and failure modes.
- Edge cases and boundary values.
- Newly added branches.

Happy-path-only coverage is a false signal. Bugs live in the paths
nobody tested.

### Brittle tests

Break when implementation changes but behavior doesn't. Usual causes:
- Over-mocking (internals instead of boundaries).
- Asserting on call counts or internal state.
- Coupling to serialization format or log output.

Rewrite to assert on observable behavior through public interfaces.

### Edge cases

Each is a production failure mode:
- Boundary values (0, 1, max, off-by-one).
- Empty/null/missing inputs.
- Concurrent access where applicable.
- Error recovery and retry.
- Resource exhaustion.

### Assertion quality

Weak: `assert result is not None`. Proves the code ran, not that it's
correct.

Strong: `assert result.status == 401 and "expired" in result.body`.
Proves specific behavior under specific conditions.

One vague assertion per test is a smell.

### Test naming

Name the behavior, not the method.

- Bad: `test_login`, `test_process`.
- Good: `test_login_with_expired_token_returns_401`.
- Good: `test_empty_cart_checkout_raises_validation_error`.

If you can't name the behavior, you don't understand what you're testing.

## Cross-harness parity check (Red Line)

Every new mechanism must work on Claude Code, Codex, AND Pi.

- **Filesystem + SKILL.md primary layer.** Runtime-only toggles
  (Claude's `enabledPlugins`, Codex's `/plugins`, Pi's
  `skills[]` glob) are optimizations *on top of* the filesystem layer,
  not a substitute for it.
- **Per-harness artifacts from one source.** If the mechanism needs
  runtime toggling, emit plugin.json for Claude + plugin.json for Codex
  + glob entry for Pi deterministically. Never manual per-harness
  drift.
- **Single-harness designs fail the doctrine.** If you can't answer
  "what does this do on Codex?" the design is incomplete.

Prior art: `harnesses/pi/settings.json:skills[]` — filesystem-level
allow/deny globs, works everywhere by construction.

## Confidence assessment

Confidence is an explicit deliverable. State it with evidence, not
feelings.

### Levels

**High** — all behaviors tested, edge cases covered, matches existing
patterns, small blast radius. Merge without hesitation.

**Medium** — core path tested but edge cases have gaps. Or touches
unfamiliar code. Or large blast radius with rollback story.

**Low** — untested paths, novel patterns, large blast radius, no
rollback. Requires verification before merge.

### Evidence that increases confidence

- Passing `dagger call check` (necessary, not sufficient).
- Live verification of the changed skill via symlink install + invoke
  from a foreign project (the canonical self-containment test).
- Before/after on observable behavior.
- Explicit enumeration of failure modes and why they don't apply.
- `/code-review` verdict of `ship` (not just `conditional`).

### Evidence that decreases confidence

- "It compiles" as the only signal.
- Tests covering only the happy path.
- Large diff with no test changes.
- Changes to shared utilities with no downstream check.
- Conditional verdict with open caveats unaddressed.

### Reporting

State confidence per concern when the branch spans multiple:

```
Confidence:
- settle SKILL.md rewrite: HIGH — unchanged script plumbing, references follow existing pattern
- scripts/land.sh doc references: HIGH — script is unchanged
- Cross-harness check: HIGH — SKILL.md surface is filesystem + frontmatter, works uniformly
```

## Agent-first assessment

Run structured assessment tools when available.

| Tool | Purpose | When |
|---|---|---|
| `assess-review` | Code quality scoring (triad, strong tier) | Always |
| `assess-tests` | Test quality scoring | Always |
| `assess-docs` | Documentation quality | When docs touched |
| `assess-simplify` | Validate Phase 3 refactor moved complexity out, not sideways | After Phase 3 |

### Hard gate

All `fail` findings from assess-* must be addressed before exiting
Phase 2. `warn` findings are advisory.

## Docs audit

Update anything stale after the change:
- `harnesses/shared/AGENTS.md` if the change touches principles.
- `CLAUDE.md` if the change alters workflow map entries.
- `SKILL.md` bodies of composed skills if their contracts shifted.
- `backlog.d/NNN-*.md` if the shape's Acceptance Criteria evolved
  during implementation.

## Exit criteria

- [ ] Hindsight review performed, blocking smells fixed.
- [ ] Spellbook-specific smells checked; none blocking.
- [ ] Test audit performed, coverage gaps filled.
- [ ] Cross-harness parity confirmed.
- [ ] Confidence assessment stated with evidence.
- [ ] All `assess-*` `fail` findings resolved.
- [ ] Docs current with changes.

If this phase produced commits, return to Phase 1 — the gate must stay
green.
