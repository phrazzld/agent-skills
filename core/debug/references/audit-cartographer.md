# Cartographer

Map and document codebases of any size using parallel AI subagents.

Creates `docs/CODEBASE_MAP.md` with architecture diagrams, file purposes, dependencies, and navigation guides. Updates `CLAUDE.md` with a summary.

## Critical Principle

**"Opus orchestrates, Sonnet reads."**

Never have Opus read codebase files directly. Always delegate file reading to Sonnet subagents. Opus plans the work, spawns subagents, and synthesizes their reports.

## Process

### 1. Check for Existing Map

Check if `docs/CODEBASE_MAP.md` exists. If it does, check `last_mapped` timestamp and `git log --oneline --since="<last_mapped>"` for changes. Proceed to update mode if significant changes detected.

### 2. Scan the Codebase

```bash
uv run ~/.claude/skills/cartographer/scripts/scan-codebase.py . --format json
```

Output provides: complete file tree with token counts, total token budget, skipped files.

### 3. Plan Subagent Assignments

**Token budget per subagent:** ~150,000 tokens (safe margin under Sonnet's 200k context limit)

Group files by directory/module, balance token counts, aim for more subagents with smaller chunks.

### 4. Spawn Sonnet Subagents in Parallel

Use Task tool with `subagent_type: "Explore"` and `model: "sonnet"`. Each subagent analyzes:
- Purpose of each file/module
- Key exports and public APIs
- Dependencies and dependents
- Patterns and conventions
- Gotchas or non-obvious behavior

### 5. Synthesize Reports

Merge all subagent reports, deduplicate, identify cross-cutting concerns, build architecture diagram, extract navigation paths.

### 6. Write CODEBASE_MAP.md

Structure: System Overview, Architecture (Mermaid), Directory Structure, Module Guide (per module: purpose, entry point, key files, exports, dependencies), Data Flow (sequence diagrams), Conventions, Gotchas, Navigation Guide.

### 7. Update CLAUDE.md

Add codebase summary with stack and structure info.

## Update Mode

1. Identify changed files from git or scanner diff
2. Spawn subagents only for changed modules
3. Merge new analysis with existing map
4. Update `last_mapped` timestamp
5. Preserve unchanged sections

## Token Budget Reference

| Model | Context Window | Safe Budget per Subagent |
|-------|----------------|-------------------------|
| Sonnet | 200,000 | 150,000 |
| Opus | 200,000 | 100,000 |
| Haiku | 200,000 | 100,000 |

Always use Sonnet subagents for file analysis.
