# Thinktank

Thin Pi bench launcher for repo-aware research.

## Role

Launches a repo-aware Pi bench against the current workspace and records raw
agent outputs plus an optional synthesis.

## Objective

Answer `$ARGUMENTS` with a repo-aware research bench, not a semantic workflow engine.

## Workflow

1. **Decide if Thinktank belongs** — Use it when the local repo matters. Skip it for pure external research.
2. **Frame** — Write a clear prompt.
3. **Orient** — Add `--paths` for relevant files or directories when useful.
4. **Choose depth**
   - Quick fanout source: `thinktank run research/quick --input "$ARGUMENTS" --output /tmp/thinktank-out --json --no-synthesis`
   - Deep repo-aware bench: `thinktank research "$ARGUMENTS" --output /tmp/thinktank-out --json`
5. **Wait** — Quick runs can still take a minute or two. Deep runs can take several minutes.
6. **Read stdout** — `--json` prints the final run envelope after completion.
7. **Read artifacts** — Raw agent outputs are in `/tmp/thinktank-out/agents/`
8. **Read synthesis** — Synthesized summary is in `/tmp/thinktank-out/synthesis.md` when enabled. There is no `report.json` artifact.

## Usage

```
/research thinktank "Is this auth implementation secure?" ./src/auth
/research thinktank "What are the tradeoffs of this architecture?"
/research thinktank "What is this repo doing that feels over-engineered?"
```

## Output

- **Raw reports** — one file per Pi agent
- **Synthesis** — optional summary across the bench
- **Artifacts** — task, prompts, contract, manifest
- **Final envelope** — JSON on stdout when `--json` is used
