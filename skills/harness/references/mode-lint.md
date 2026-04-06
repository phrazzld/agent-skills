# /harness lint

Validate a skill against quality gates.

## Quality gates

| Gate | Check | Fix |
|------|-------|-----|
| **Description triggers** | Does description include trigger phrases? | Add "Use when:" with concrete phrases |
| **Size** | SKILL.md < 500 lines? | Extract to references/ |
| **Gotchas** | Does it enumerate failure modes? | Add a gotchas section |
| **Judgment test** | Does it encode judgment the model lacks? | If not, delete the skill |
| **Oracle** | Can you verify the skill worked? | Add success criteria |
| **Freshness** | Do instructions match current model capabilities? | Strip non-load-bearing scaffold |
| **Mode bloat** | >4 modes with inline content, or any single mode >60 lines inline? | Extract mode content to references/mode-*.md; use router pattern (see /investigate, /settle) |

## Batch lint

Run on all skills: `for s in skills/*/SKILL.md; do /harness lint "$s"; done`
