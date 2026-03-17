# project.md Format Reference

`project.md` lives in the project root. It captures **product context** that
tune-repo artifacts don't cover: vision, principles, philosophy, domain language.

**Durability rule:** `project.md` should read correctly 6 months from now without
updates. No version numbers, no issue references, no sprint snapshots. Those
belong in GitHub milestones and `.groom/` artifacts.

## Relationship to Tune-Repo Artifacts

| Artifact | Owner | Covers |
|----------|-------|--------|
| `CLAUDE.md` | `/tune-repo` | Commands, stack, gotchas (code context) |
| `AGENTS.md` | `/tune-repo` | Commit, test, PR, style conventions |
| `docs/CODEBASE_MAP.md` | `/cartographer` | Architecture, modules, data flow |
| `docs/context/INDEX.md` | `/tune-repo` | Cold-memory subsystem index |
| `docs/context/ROUTING.md` | `/tune-repo` | Trigger table for specialist routing |
| `docs/context/*.md` | `/tune-repo` | Subsystem specifications |
| `docs/adr/*.md` | `/tune-repo` | Architectural decision records |
| **`project.md`** | **`/groom`** | **Vision, principles, philosophy, domain, quality bar** |

`project.md` fills the product gap. Together with tune-repo outputs, agents get
everything they need: what the product is, who it's for, what matters, and how
the code is structured.

## Template

```markdown
# Project: [Name]

## Vision
[One-liner: what this product is and who it's for]

**North Star:** [Dream state — what success looks like]
**Target User:** [Specific persona]
**Key Differentiators:** [What makes this different]

## Principles
- **[Name.]** [Durable design principle that guides decisions]
- **[Name.]** [Another principle]

## Philosophy
- [Product philosophy — what matters, what doesn't, how to make tradeoffs]
- [Engineering philosophy — what kind of code, what kind of UX]

## Domain Glossary

Terms agents must understand to work in this codebase.

| Term | Definition |
|------|-----------|
| | |

## Quality Bar

What "done" means beyond "tests pass." Project-specific standards.

- [ ] [Product-level acceptance criterion]
- [ ] [User experience expectation]
- [ ] [Performance budget]

## Patterns to Follow

Concrete code patterns agents should replicate. Project-specific examples
that complement AGENTS.md coding style.

### [Pattern Name]
```[lang]
// example code from this repo
```

## Lessons Learned

Things we've tried that didn't work. Distilled from `.groom/retro/*.md`.

| Decision | Outcome | Lesson |
|----------|---------|--------|
| | | |

---
*Last updated: YYYY-MM-DD*
*Updated during: /groom session*
```

## What Belongs Here vs. Elsewhere

| Content | Where it goes | Why |
|---------|---------------|-----|
| Vision, principles, philosophy | `project.md` | Durable — changes rarely |
| Domain glossary | `project.md` | Durable — terms outlive sprints |
| Quality bar | `project.md` | Durable — standards don't shift weekly |
| Code patterns | `project.md` | Durable — conventions are stable |
| Current sprint / milestone focus | GitHub milestones | Ephemeral — changes every sprint |
| Active issue references (#N) | `.groom/plan-*.md` | Ephemeral — issues close |
| Version numbers | `CHANGELOG.md` / tags | Ephemeral — versions ship |
| Retro findings | `.groom/retro/*.md` | Ephemeral until distilled into Lessons Learned |

## Anti-Patterns

- **Version pinning:** "Current Focus: post-v3.4.0" — breaks on next release.
- **Issue references in Vision:** "#187, #142" — meaningless once closed.
- **Sprint snapshots:** "Active Focus: stability and polish" — stale in 2 weeks.
- **Model counts:** "39+ models" — wrong after every registry update.

Replace with durable equivalents:
- "Current Focus: post-v3.4.0" → Principle: "Ship what matters."
- "#187, #142" → GitHub milestone queries
- "39+ models" → "many models"

## When to Create

- `/groom` Phase 1 creates or updates `project.md`
- Replaces the old `vision.md` format (which had only 5 fields)
- If `vision.md` exists, migrate its content into project.md and delete it

## When to Read

- `/groom` Phase 1 — load for session context
- `/autopilot` — load before starting any issue
- `/shape` — load for product context
- `/issue enrich` — embed vision one-liner in Context section

## Update Frequency

Updated only when vision, principles, or domain language genuinely change.
Sprint-level changes (milestones, active issues, themes) belong in GitHub
and `.groom/plan-*.md`, not here.
