# Routing Table

Starter trigger table for tuned repos.

Use `/tune-repo` to replace placeholders with real routes tied to source areas.

| Trigger | Signal | Route |
|---------|--------|-------|
| Pre-change | skill creation or modification | `/craft-primitive` |
| Pre-change | rerunning `/focus init` or auditing primitive selection | read `.spellbook/init-report.json` before new catalog search |
| Pre-change | auditing selection drift, missing matches, or sync outcomes | read `.spellbook/observations.ndjson` before revising `focus` behavior |
| Pre-change | repo tuning / agent foundation work | `codified-context-architecture` + `/tune-repo` |
| Post-change | PR blocked on CI, reviews, or conflicts | `/pr-fix` |
