## Harness Accelerator (Claude Code)

When this skill runs in Claude Code:

1. In workflow step 8 (`Refine`), run `/simplify` after `/pr-fix --refactor`.
2. In `Parallel Refinement`, use `/batch` to dispatch teammate tasks in one call when possible.

If either command is unavailable, use the portable fallback path already defined in the base skill.
