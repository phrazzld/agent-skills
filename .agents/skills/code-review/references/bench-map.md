# Bench Map — Static Reviewer Selection

The marshal picks the philosophy bench via a declarative path-glob map in
`bench-map.yaml`. Deterministic, greppable, eval-able. No LLM classifier.

## How It Works

```
changed files  ──►  match globs  ──►  union `add` agents with `default`
                                 ──►  de-dup
                                 ──►  cap at 5 (critic pinned)
                                 ──►  bench
```

1. **Get changed files:** `git diff --name-only <base>...HEAD`
2. **Start from `default`:** `critic`, `ousterhout`, `grug`. Always 3,
   always includes `critic`.
3. **Match rules:** for each rule, if ANY changed file matches ANY glob in
   `paths`, union the rule's `add` list into the bench.
4. **De-duplicate** — agents appear at most once.
5. **Cap at 5.** If over, drop agents contributed by the rule with the
   fewest file matches. `critic` is never dropped.
6. **Bench size stays in [3, 5]** for every diff.

## Fallback (No Rule Matches)

`default` is the fallback. If no rule matches — say, a diff touching only
unknown extensions — the bench is exactly `[critic, ousterhout, grug]`.
The review still runs; it never errors on an unclassified diff.

## Rules Mapped to Spellbook Reality

The map encodes what this repo actually reviews:

- **Skills** (`skills/**/SKILL.md`) → +`ousterhout`, `grug`. Shallow-module
  and scaffolding lenses.
- **`/deliver`** → +`carmack`, `critic`. Composition lint is load-bearing.
- **Agents** → +`ousterhout`, `grug`. Persona must have structural
  justification, not just prose.
- **Dagger / CI** → +`carmack`, `beck`. Gates are load-bearing walls;
  test coverage matters for `heal_support`.
- **`bootstrap.sh`** → +`carmack`, `grug`. Directness over scaffolding.
- **Shell / Python scripts** → lens by language.
- **`harnesses/shared/**`** → +`ousterhout`. THE principles file.
- **Per-harness configs** → +`carmack`. Parity and directness.
- **Tests** → +`beck`.
- **Docs / backlog** → +`grug`. Lightweight.

## How To Add a Rule

Edit `bench-map.yaml`. Each rule has `name`, a `paths` list of globs, and
an `add` list of agents.

```yaml
- name: registry
  paths: ["registry.yaml", "scripts/sync-external.sh"]
  add: [critic, carmack]
```

Constraints:

- Agents in `add` MUST exist under `/Users/phaedrus/Development/spellbook/agents/<name>.md`.
  Non-existent agents make the map unloadable.
- **No a11y-* agents** in any rule. This repo has no UI surface; if an
  a11y reviewer shows up in a bench here, the map is broken.
- Prefer 1-2 `add` agents per rule. `default` already carries 3.
- Keep globs specific. Overly broad globs inflate the bench and force the
  cap to drop useful reviewers.

## Available Agents

From `/Users/phaedrus/Development/spellbook/agents/`:

- `critic`, `ousterhout`, `carmack`, `grug`, `beck`
- `planner`, `builder` — used in fix loops, not as reviewers.

If you want a new specialty (e.g. a spellbook-security reviewer), add the
agent first, then reference it here.

## Override Mechanics

No per-repo override file. Manual overrides for a single review are fair
game: the marshal may swap or add a reviewer for concerns the map doesn't
capture (e.g. a Dagger gate that happens to touch async semantics).
Document the swap in the synthesis output.

## Determinism

Same diff + same `bench-map.yaml` → same bench. No randomness, no LLM call
in selection. This is load-bearing: it makes `/code-review` reproducible
and lets us write eval fixtures against known bench outputs.
