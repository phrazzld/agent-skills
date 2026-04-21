# Philosophy Bench

Philosophy agents under `/Users/phaedrus/Development/spellbook/agents/`.
Running on the same model as the marshal with different lenses — useful for
depth, not foundation diversity. For foundation diversity, rely on
thinktank + cross-harness.

All reviewers run as **Explore type** (read-only). The marshal selects 3-5
via `bench-map.yaml` and crafts tailored prompts.

## Agent Catalog

| Agent | Lens | Best on Spellbook diffs |
|---|---|---|
| **critic** | correctness, depth, simplicity, craft (grading rubric) | every review — the baseline evaluator and scorer |
| **ousterhout** | deep modules, information hiding, complexity management | SKILL.md restructuring, new skill/agent interfaces, Dagger gate composition. Hunts *shallow modules*, *pass-through layers*, *hidden coupling*. |
| **grug** | complexity demon, anti-scaffolding | Catches *semantic workflow DSLs around general agents*, *speculative abstractions*, scaffold that compensates for a strong model. Reference form: `skills/flywheel/SKILL.md` (43 lines). |
| **carmack** | shippability, pragmatism, direct implementation | `bootstrap.sh`, shell scripts, Dagger gates, harness configs. "Is this the simplest working thing?" |
| **beck** | TDD discipline, YAGNI, simple design | Test coverage for `ci/src/spellbook_ci/`, scripts, python modules. Eval fixtures. |

No a11y triad in this repo — no UI surface.

`planner` and `builder` are on the roster but used in fix loops, not as
reviewers.

## Selection Heuristics

- **Always include critic.** Baseline scoring.
- **Skill / agent markdown changes** → ousterhout (module depth, interface
  simplicity) + grug (anti-scaffolding).
- **Dagger gate changes** → carmack (shippability, parallel composition) +
  beck (test coverage on `heal_support`).
- **`bootstrap.sh` changes** → carmack + grug (directness, no unnecessary
  scaffolding).
- **`harnesses/shared/AGENTS.md` changes** → ousterhout. Changes here ripple
  through every harness; treat as interface design.
- **Large diffs with new abstractions** → grug + ousterhout.

The marshal may define **ad-hoc agents** when the diff raises concerns the
named bench doesn't cover. Document the ad-hoc in the synthesis so it stays
auditable.

## Prompting

Every reviewer prompt states:

1. **Diff scope** — `git diff $BASE...HEAD` (or specific files).
2. **Lens applied to this specific diff** — not the generic persona.
   Example: instead of "review as Ousterhout," say "apply deep-module /
   pass-through-layer analysis to the new `/rebase` skill's interaction
   with `/deliver`."
3. **Verdict options** — `Ship`, `Conditional`, `Don't Ship`.
4. **Cite file:line for every finding.** Opinions without coordinates are
   noise.
5. **Respect Dagger.** Dagger already ran gates 0. Don't restate frontmatter
   errors or shellcheck warnings — focus on judgment Dagger can't form.
6. **Red-flag vocabulary.** Use `harnesses/shared/AGENTS.md` terms verbatim
   when they apply: *shallow modules, pass-through layers, hidden coupling,
   large diffs, speculative abstractions, stale context, regexes over agent
   prose, semantic workflow DSLs around general agents*.

The marshal crafts these prompts per-diff. This reference describes the
lenses, not the exact words.

## What Each Lens Catches on This Repo

**ousterhout — shallow modules.** A SKILL.md that wraps a one-liner and
adds no judgment. An agent persona that's a thin persona-shaped jacket over
prose a general-purpose subagent would emit anyway. A Dagger gate that
pass-through-calls one shellcheck invocation.

**grug — scaffolding.** A SKILL.md over 150 lines that could be 40 (see
`/flywheel`). Procedure disguised as judgment. A semantic workflow DSL
that's reinventing bash. State machines around general agents. YAML schema
branches where a single flat manifest would do.

**carmack — shippability.** A `bootstrap.sh` change that breaks the
symlink-mode + download-mode parity. A Dagger gate that serializes what
could parallelize. Harness configs that drift between Claude/Codex/Pi
without a reason.

**beck — test coverage.** A new Python helper in `ci/` with no tests. A
script that would break silently in a downstream repo but has no
symlink-install smoke test. YAGNI calls on "future-proof" config keys that
currently have one consumer.

**critic — rubric.** Correctness (does it work?), depth (does it earn its
complexity?), simplicity (can it be smaller?), craft (is it honest about
what it does?). Assigns the cross-provider scores written to
`.groom/review-scores.ndjson`.
