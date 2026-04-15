# Project: Spellbook

## Vision
Portable primitive library that makes AI coding agents reliably excellent across any harness.

**North Star:** Every recurring workflow pattern a senior engineer uses is captured as a tested,
composable primitive — so any agent (Claude, Codex, Gemini, Pi) can execute it first-try.
**Target User:** Senior+ engineers running multi-agent workflows across multiple repos.
**Current Focus:** Spellbook architecture — flat skills, manifest-driven activation via `/focus`, agent definitions.
**Key Differentiators:** Agent-agnostic (works across harnesses), manifest-driven (`.spellbook.yaml`),
research-backed (web + multi-model validation before codifying).

## Domain Glossary

| Term | Definition |
|------|-----------|
| Skill | A markdown-first module (SKILL.md + optional references/) that gives agents domain expertise |
| Agent | A markdown persona definition that gives subagents specialized review/analysis capabilities |
| Collection | Named group of skills in collections.yaml (payments, web, agent, infra, etc.) |
| Harness | An AI agent runtime (Claude Code, Codex, Gemini CLI, Factory, Pi) |
| Manifest | `.spellbook.yaml` — declares which primitives a project needs |
| Focus | Meta-skill that reads manifests and pulls primitives from GitHub |
| DMI | Disable-model-invocation — user-only skills that cost zero budget |
| Delivery pipeline | groom → deliver (shape → implement → review + ci + refactor + qa) → merge |

## Active Focus

- **Milestone:** Spellbook Architecture — flat skills, manifest-driven activation, agent definitions
- **Key work:** Rename from agent-skills, flatten core/packs → skills/, add /focus, bootstrap, collections
- **Theme:** Make the library distributable via manifest + GitHub pull, not symlinks
- **Recent:** Core/packs flattened to skills/, focus meta-skill, collections.yaml, index.yaml, bootstrap.sh

## Quality Bar

- [ ] Every skill has clear trigger conditions (when to invoke, when NOT to)
- [ ] All descriptions ≤1024 chars with trigger phrases
- [ ] Skills compose — orchestrators call primitives, never reimplement
- [ ] Agent-agnostic — no Claude-specific assumptions leak into skill bodies
- [ ] Retro patterns flow back into skill definitions

## Patterns to Follow

### Progressive Disclosure
```
description (budget cost) → SKILL.md body → references/ (on-demand)
```

### Skill Structure
```
skills/{name}/
├── SKILL.md          # Required. Frontmatter + instructions.
└── references/
    ├── sub-cap-1.md  # Loaded on demand
    └── sub-cap-2.md  # Zero additional budget cost
```

### AC Tags for Machine Verification
```markdown
- [ ] [test] Given X, when Y, then Z
- [ ] [command] Given X, when `cmd`, then output matches
- [ ] [behavioral] Given X, when user does Y, then Z
```

## Lessons Learned

| Decision | Outcome | Lesson |
|----------|---------|--------|
| Umbrella pattern (research/) | 4→1 budget savings | Progressive disclosure works; add sub-caps at zero cost |
| Core pruning 50+ → 11 | Budget 10.2K → 1.4K | Aggressive pruning + pack architecture works |
| Standalone pipeline skills | Fragmented, hard to compose | Absorb related skills into umbrellas |
| Symlink distribution | Fragile, machine-specific | Manifest-driven pull from GitHub (focus) is more portable |
| Flat skills/ directory | Simpler than core/packs | One level of indirection is enough; collections handle grouping |

---
*Last updated: 2026-03-16*
*Updated during: Spellbook architecture refactor*
