---
name: tailor
description: |
  Tailor this repository's harness. Explore the repo, read prior
  session history if any, browse the spellbook catalog, pick the
  primitives that fit, and install them locally in .claude/.
  Specialize where specialization is concrete; leave alone otherwise.
  Use when: "tailor this repo", "configure the agent for this codebase",
  "set up a harness", "what skills apply here". Trigger: /tailor.
---

# /tailor

Give this repo its own harness. You're a librarian: spellbook is the
collection; this repo is one reader. Pick relevant volumes, maybe
write a note in the margin, put them on the reader's shelf.

## Shape of the work

1. **Explore.** Read enough of this repo to know what it is —
   language, frameworks, test/CI/deploy commands, size, domain.
   `package.json` / `Cargo.toml` / `pyproject.toml`, README, top-level
   structure.

2. **Prior art.** If your harness keeps session history for this repo
   (Claude Code: `~/.claude/projects/<path-hash>/`, Codex: analogous
   state path), read the session JSONL and memory files. What
   commands does the user actually run here? Where have they
   corrected you? That's the highest-signal input available.

3. **Browse.** Read the spellbook catalog — resolve via `readlink -f`
   on this SKILL.md, walk up to find `$SPELLBOOK/skills/` and
   `$SPELLBOOK/agents/`. Each primitive's frontmatter describes when
   to use it. That's your map.

4. **Pick.** Dispatch planner + critic subagents. Planner proposes a
   set; critic applies `references/focus-postmortem.md`. One round.
   Stop on critic-clear.

5. **Install.** Copy each picked primitive's full directory into
   `.claude/skills/<name>/` or `.claude/agents/<name>.md`. Preserve
   self-containment — `references/` and `scripts/` travel with their
   skill.

6. **Specialize (where it helps).** If an edit adds concrete,
   repo-specific value to a copied primitive, add it. Otherwise
   leave the copy alone. See "When specializing" below.

7. **Write the glue.** `AGENTS.md` with this repo's build/test/deploy
   commands, hot paths, gotchas. `.claude/settings.local.json` with a
   permissions allowlist for the tools actually in use.

## Invariants

- Never write outside the current repo. No `$SPELLBOOK` mutation,
  no `~/.claude` / `~/.codex` / `~/.pi` mutation.
- Over-install is worse than under-install. That's how `/focus`
  rotted. Err toward fewer.
- Don't tailor speculatively. Specialization must be concrete and
  repo-specific (e.g. "flag Rust unsafe without SAFETY: comment"),
  not aesthetic ("make it more fitting").

## When specializing

The edit is skill authoring. Key principles from `/harness` — read
`$SPELLBOOK/skills/harness/SKILL.md` for the full set:

- **Judgment over procedure.** Gotchas ("in this repo, X fails when
  Y — check for Z") beat step-lists the agent already knows.
- **Preserve the contract.** Don't rewrite the primitive's
  description or invariants — add to them.
- **Concrete or skip.** Checkable edits only. No vague "improvements."
- **Self-contained.** Any file the edit references lives under the
  copied skill's directory, not in the repo root.

## References

- `references/focus-postmortem.md` — critic's rejection checklist.

See also: `/seed` for the dumb-copy variant when you want something
working fast and will curate by hand later.
