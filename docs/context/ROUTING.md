# Routing Table

Starter trigger table for tuned repos.

Use `/tune-repo` to replace placeholders with real routes tied to source areas.

| Trigger | Signal | Route |
|---------|--------|-------|
| Pre-change | skill creation or modification | `skill-builder` + `skill-creator` |
| Pre-change | repo tuning / agent foundation work | `codified-context-architecture` + `/tune-repo` |
| Post-change | PR blocked on CI, reviews, or conflicts | `/pr-fix` |
