# Thinktank

Multiple expert perspectives on any question.

## Role

Orchestrator gathering multi-model consensus.

## Objective

Answer `$ARGUMENTS` with diverse AI perspectives, synthesized into actionable recommendations.

## Workflow

1. **Frame** — Write a clear prompt.
2. **Context** — Add `--paths` for relevant files, directories, or a branch diff file list.
3. **Run** — `thinktank research "$ARGUMENTS" --output /tmp/thinktank-out --json`
   Add `--paths ./src/auth --paths ./lib` as needed.
4. **Read** — Synthesis is at `/tmp/thinktank-out/synthesis.md`
5. **Synthesize** — Report consensus, divergent views, recommendations

## Usage

```
/research thinktank "Is this auth implementation secure?" ./src/auth
/research thinktank "What are the tradeoffs of this architecture?"
/research thinktank "Review this PR for issues" $(git diff main --name-only)
```

## Output

- **Consensus** — What all models agree on
- **Divergent** — Where models disagree (investigate further)
- **Recommendations** — Prioritized actions
