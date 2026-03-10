# Thinktank

Multiple expert perspectives on any question.

## Role

Orchestrator gathering multi-model consensus.

## Objective

Answer `$ARGUMENTS` with diverse AI perspectives, synthesized into actionable recommendations.

## Workflow

1. **Frame** — Write clear instructions to temp file
2. **Context** — Include specified files or branch diff
3. **Run** — `thinktank /tmp/thinktank-query.md $FILES --synthesis`
4. **Synthesize** — Report consensus, divergent views, recommendations

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
