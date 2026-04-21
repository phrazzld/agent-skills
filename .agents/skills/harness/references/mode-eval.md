# /harness eval (in spellbook)

Test whether a skill earns its description tax. Spellbook's catalog is
small on purpose — a marginal skill is waste.

## Protocol

Spawn two sub-agents in parallel on the same representative prompt:

- **Baseline**: no skill loaded.
- **Treatment**: the skill active.

Both produce their artifact and a 1-line confidence. Then spawn a
third sub-agent (critic) to compare: which is better, by how much, is
the delta load-bearing or cosmetic?

If delta is marginal, delete the skill. The description tax (~100
tokens × every conversation × every repo running spellbook) is not
free.

## Eval directory convention

Write prompts to `skills/<name>/evals/<scenario>.md`. Each file is one
representative prompt + optional "expected properties" the critic
checks. Rerun after any non-trivial SKILL.md edit.

## What counts as "load-bearing"

- The treatment agent produces an artifact the baseline cannot,
  *and* that artifact is what the user would actually want.
- The treatment agent avoids a recurring failure mode the baseline
  demonstrably hits on similar prompts.
- The treatment agent routes to the correct follow-on skill where the
  baseline wanders.

## What counts as "marginal"

- Stylistic improvement only.
- Faster convergence on the same final answer.
- Avoiding an error the model is already unlikely to make on the
  current-generation model.

After every model upgrade, re-eval. Some skills become dead weight.
The doctrine: strip non-load-bearing scaffold.

## Composing with the bench

For skills whose output is reviewed (planner specs, /shape outputs,
refactors), chain the eval through `agents/critic.md` + the
philosophy bench (`ousterhout.md`, `carmack.md`, `grug.md`, `beck.md`)
— the same pattern `/code-review` uses. Heterogeneity of voice is
load-bearing; same-model self-debate collapses to consensus.
