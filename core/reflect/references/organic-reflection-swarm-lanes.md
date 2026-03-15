# Reflection Swarm Lanes (Optional)

Use these lane prompts if a `subagent` tool is available.

## Lane A — Work Memory Miner

Goal: extract repeated friction and high-value wins from recent work.

Prompt:
- Inspect recent sessions/logs/commits/PRs.
- Return:
  1. repeated manual tasks
  2. recurring decision bottlenecks
  3. candidate codification targets

## Lane B — Legacy Config Synthesizer

Goal: identify reusable patterns from Claude/Codex without migrating bloat.

Prompt:
- Scan `~/.claude/skills`, `~/.codex/commands`, `~/.codex/agents` for only relevant patterns.
- Return keep/drop/later recommendations with reasons.

## Lane C — Pi Capability Mapper

Goal: map native Pi extension points for the reflected needs.

Prompt:
- Inspect Pi docs/examples for prompt templates, skills, extensions, sessions, compaction, SDK.
- Return implementation paths and constraints.

## Lane D — External Research Scout

Goal: gather current best practices and candidate tools.

Prompt:
- Research memory/orchestration best practices and candidate tools.
- Include citation URLs for factual claims.

## Synthesizer

Combine lanes A-D into one recommendation:
- 1-2 `now` experiments
- 2-3 `next` candidates
- clear `later` deferrals
- explicit bloat-risk notes
