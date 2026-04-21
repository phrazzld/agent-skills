# /harness convert (in spellbook)

Convert between agents (`agents/<name>.md`) and skills
(`skills/<name>/SKILL.md`), and translate frontmatter across
harnesses when moving personas between Claude, Codex, and Pi.

## Agent → Skill

When the persona is actually a workflow you want model-triggered by
description rather than dispatched by orchestration.

1. Read `agents/<name>.md` — frontmatter + system prompt.
2. Drop persona-only fields (`color`, `tools`, `model` when the skill
   shouldn't pin a model).
3. Rewrite `description:` from "who this agent is" to "when to invoke
   this skill" — assertive, with trigger phrases.
4. Create `skills/<name>/SKILL.md`. Move the system-prompt body into
   it, stripping second-person persona framing ("You are…") in favor
   of invariants the model applies.
5. If the body is >500 lines (which is rare for an agent), split into
   `references/mode-*.md` with a router table in SKILL.md.
6. Add the new skill's entry to `registry.yaml`? Only if it's a
   sync-managed external. First-party skills are filesystem-
   discovered; no registry edit needed.
7. Decide: does `agents/<name>.md` stay? Often yes — the persona and
   the workflow are distinct artifacts. A skill routes *to* a
   persona agent for a subtask (the `/code-review` pattern uses
   `critic` + the philosophy bench).

## Skill → Agent

When the skill is really a persona that should be dispatched with full
context, not triggered from description-scan.

1. Read `skills/<name>/SKILL.md`.
2. Create `agents/<name>.md`. Frontmatter: `name`, `description` (as a
   one-line persona summary), `tools` (or leave for Claude default),
   `disallowedTools` if the persona must not edit/write, optional
   `model:` and `color:`.
3. Rewrite body as a system prompt. Second-person, persona-first
   ("You are the Critic…"). See `agents/critic.md`, `agents/builder.md`,
   `agents/planner.md` as canonical form.
4. Keep instructions focused — agents receive full context at
   startup, so progressive disclosure via `references/` is usually
   unnecessary.
5. Delete `skills/<name>/` unless it remains useful as a trigger
   surface. Run `./scripts/generate-index.sh` so `index.yaml` drops
   the skill entry.

## Cross-harness translation (frontmatter)

Claude and Codex-classic agents share the same YAML-frontmatter shape
in `agents/*.md`. Fields that map:

| Field | Claude | Codex | Pi |
|-------|--------|-------|-----|
| `name` | required | required | required |
| `description` | required, trigger-phrased | required | required |
| `tools` | allowlist of tool names | same | advisory |
| `disallowedTools` | denylist, evaluated after `tools` | may drop silently | may drop silently |
| `model` | per-agent pin | per-agent pin | usually ignored |
| `color` | UI hint | ignored | ignored |

Gotchas:

- **Codex `config.toml` profiles are execution config, not personas.**
  `harnesses/codex/config.toml` defines `[profiles.ultrathink]` etc.
  for model/reasoning/sandbox, not agent personas. Don't translate
  agent frontmatter into TOML profiles — they're different axes.
- **Pi does not honor `tools` precisely.** Pi scans skills via
  `harnesses/pi/settings.json:skills[]` globs. Tool restrictions
  enforce at the harness level, not per-skill. If the skill's safety
  property depends on `disallowedTools`, redesign.
- **`disallowedTools` is Claude-specific in practice.** Use `tools` as
  an allowlist (positive semantics) when portability matters. Prior
  art: `agents/critic.md` uses both; the allowlist is the load-bearing
  one.

## After conversion

Run the full gate preflight:

```
dagger call check --source=.
```

`check-frontmatter` catches missing fields on both sides. If you
moved a skill into `agents/`, `check-index-drift` expects `index.yaml`
to drop the skill — `./scripts/generate-index.sh` (or the pre-commit
hook) handles it.
