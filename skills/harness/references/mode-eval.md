# /harness eval

Test whether a skill improves output quality via baseline comparison.

## Protocol

Spawn two sub-agents in parallel with the same representative prompt. One runs
without the skill loaded (baseline). The other runs with the skill active.
Both produce their output and rate their confidence.

Then spawn a critic sub-agent to compare the two outputs: which is better?
By how much? Is the skill load-bearing or marginal?

If improvement is marginal, the skill isn't load-bearing. Delete it.

## Eval directory convention

Write eval prompts to `evals/` in the skill directory. Rerun after changes.
