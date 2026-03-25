# Global AGENTS.md — Pi runtime baseline

Loaded globally from `~/.pi/agent/AGENTS.md` for every Pi session.

## Scope

- Cross-repo defaults only.
- Keep this file short, stable, and high-signal.
- Push domain-specific workflow instructions into each repo’s local `AGENTS.md` (or `.pi/*`).

## Engineering doctrine (global)

- Root-cause remediation over symptom patching.
- Prefer the highest-leverage strategic simplification (Oosterhout/Torvalds/Carmack style): remove accidental complexity instead of layering guards.
- Default to clean design over backwards compatibility unless the user explicitly requests compatibility constraints.
- Favor convention over configuration and Unix-style composition: small focused primitives combined into explicit workflows.

## Quality bar

- For non-trivial changes, use test-first workflow where practical: repro/failing test → fix → regression test.
- Add or update automated tests for behavior changes and incident fixes.
- Optimize for meaningful test coverage, not superficial line-count gaming.

## Prompt + context contract

- Use role + objective + latitude framing; avoid brittle step-by-step micromanagement.
- Require clear output contracts: evidence, decisions, residual risks, and verification commands.
- Keep context high-signal and minimal; avoid noisy dumps.
- If an assistant message exceeds 1000 characters, append a final `TLDR:` section summarizing the result in 1–3 bullets.

## Reliability posture

- Treat agent health as progress over time, not just wall-clock duration.
- For delegated/orchestrated work, surface last meaningful action, last update timestamp, and progress delta.
- Escalate or recover stalled runs quickly; avoid silent hangs.
- Avoid destructive operations unless explicitly requested.

## Orchestration defaults (global)

- For non-trivial multi-step work, start with a small swarm (planner + worker + reviewer).
- Use serial execution only for tiny, low-risk edits; otherwise prefer parallel lane decomposition.
- If staying serial on non-trivial work, state the reason explicitly.

## Context precedence note

Pi concatenates context files with global first, then parent directories down to the current repo.
That means repo-local `AGENTS.md` should refine/override this baseline when needed.
