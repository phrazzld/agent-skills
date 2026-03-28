# Thinktank

Thin Pi bench launcher for repo-aware research.

## Role

Launches a fixed bench of Pi agents against the current workspace and records
their raw outputs plus an optional synthesis.

## Objective

Answer `$ARGUMENTS` with a repo-aware research bench, not a semantic workflow engine.

## Workflow

1. **Frame** — Write a clear prompt.
2. **Orient** — Add `--paths` for relevant files or directories when useful.
3. **Run** — `thinktank research "$ARGUMENTS" --output /tmp/thinktank-out --json`
4. **Read** — Raw agent outputs are in `/tmp/thinktank-out/agents/`
5. **Read** — Synthesized summary is in `/tmp/thinktank-out/synthesis.md` when enabled

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
