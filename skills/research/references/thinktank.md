# Thinktank

Thin Pi bench launcher for repo-aware research.

## Role

Launches a repo-aware Pi bench against the current workspace and records raw
agent outputs plus an optional synthesis.

## Objective

Answer `$ARGUMENTS` with a repo-aware research bench, not a semantic workflow engine.

## Workflow

1. **Set the correct workspace root first** — Run Thinktank from the repo you want agents to inspect. If the target is another repo, `cd` there before launch. Workspace is context; `--paths` only orient the bench.
2. **Frame** — Write a clear prompt.
3. **Orient** — Add `--paths` for relevant files or directories when useful.
4. **Choose depth**
   - Quick fanout source: `thinktank run research/quick --input "$ARGUMENTS" --output /tmp/thinktank-out --json --no-synthesis`
   - Deep repo-aware bench: `thinktank research "$ARGUMENTS" --output /tmp/thinktank-out --json`
5. **Record the operator contract before waiting**
   - Mode: `quick` or `deep`
   - Output directory
   - Time budget
     - `quick`: target `60-180s`, hard cap `300s`
     - `deep`: target `3-8m`, hard cap `900s`
6. **Wait with an artifact-first posture** — Quick runs can still take a few minutes. Deep runs can take several minutes. Use `thinktank runs show /tmp/thinktank-out` and `thinktank runs wait /tmp/thinktank-out` first; fall back to raw artifacts only when you need more detail.
7. **Read stdout** — `--json` prints the final run envelope after completion. Quiet stdout during the run is expected.
8. **Poll artifacts while it runs**
   - `manifest.json`
   - `trace/events.jsonl`
   - `task.md`
   - `prompts/*.md`
   - `agents/*.md` as individual agents finish
9. **Harvest partial value if interrupted or capped**
   - Summarize what artifacts exist
   - Label the result `Thinktank (partial)`
   - State what is missing and whether a rerun should stay `quick` or go `deep`
10. **Read synthesis** — Synthesized summary is in `/tmp/thinktank-out/synthesis.md` when enabled. There is no `report.json` artifact.

Default `/research` fanout does not skip Thinktank. If the bench fails or
times out, keep the Thinktank section and report the failure mode plus the
output directory instead of silently omitting it.

## Depth Selection

| Situation | Mode |
|-----------|------|
| Repo-aware shallow question, quick triangulation, code-review assist | `quick` |
| Multi-path architecture question, deeper repo investigation, synthesis-heavy research | `deep` |

## WIP Artifact-First Workflow

Thinktank launches agents. It is not an instant lookup.

- A healthy `--json` run may look quiet until completion because stdout is reserved for the final envelope.
- If the pointed paths live outside the current workspace, stop and rerun from the correct repo root. `--paths` is orientation, not workspace replacement.
- Today, the most reliable in-flight artifacts are `manifest.json`, `trace/events.jsonl`, `task.md`, and rendered prompts.
- Agent report files appear as agents finish; if you stop early, some may be missing.
- Current limitation: Thinktank does not yet guarantee durable per-agent scratchpads during execution. If you stop early, preserve the output directory and synthesize only from what exists.
- Prefer `--no-synthesis` first for research and code-review usage when you only need the bench results; synthesize from completed `agents/` artifacts yourself instead of paying extra wait time for another model pass.

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
- **Partial result path** — when the run is stopped or times out, keep the output directory and report the run as partial rather than discarding it
