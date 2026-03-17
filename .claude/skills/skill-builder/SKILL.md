---
name: skill-builder
description: |
  Create new agent skills from procedural knowledge. Invoke PROACTIVELY when:
  - Discovering a reusable workflow pattern worth preserving
  - User asks to "capture this as a skill" or "make this reusable"
  - Recognizing institutional knowledge that should persist
  - After solving a problem in a novel way worth repeating
  - Noticing repeated patterns across sessions
  AUTONOMOUS: Create skills proactively, then inform user what was created.
user-invocable: false
---

# Skill Builder

Build new agent skills that capture procedural knowledge.

## Autonomy Model

**Create then inform**: When recognizing skill-worthy knowledge, create the skill proactively, then inform the user what was created and why. Don't ask permission first.

## When to Invoke (Proactively)

1. **Successful novel solution** - Just solved something in a way worth repeating
2. **Repeated pattern** - Noticed doing the same thing multiple times
3. **Institutional knowledge** - Learning domain-specific rules that should persist
4. **User workflow** - User demonstrates a process they want automated
5. **Research findings** - Discovered best practices worth preserving

## Quality Gates (Pre-Extraction)

Before creating a skill, verify ALL gates pass:

| Gate | Question | Fail Criteria |
|------|----------|---------------|
| **REUSABLE** | Applies beyond this instance? | One-off solution |
| **NON-TRIVIAL** | Required discovery, not docs lookup? | Just followed documentation |
| **SPECIFIC** | Clear trigger conditions defined? | Vague "sometimes useful" |
| **VERIFIED** | Solution confirmed working? | Theoretical, untested |
| **SIMPLE INTERFACE** | Happy path works without flag memorization? | Requires multiple flags for core flow |

If ANY gate fails → Stop. Not skill-worthy.

## Skill Lifecycle: Absorption

Standalone skills can be **absorbed** into umbrella skills to reduce budget consumption.
An umbrella skill consolidates related skills into one budget entry with reference-based routing.

### When to Absorb

- 3+ skills share a natural domain boundary (research, standards, delivery)
- Budget pressure requires consolidation
- Skills are frequently co-triggered

### How to Absorb

1. Create umbrella `SKILL.md` with routing table mapping intent → reference file
2. Copy each absorbed skill's body (minus frontmatter) → `references/{name}.md`
3. Move `scripts/`, `assets/`, existing `references/` into umbrella (merge, prefix if collisions)
4. Delete old `core/{name}/` directory
5. `./scripts/sync.sh all`

### Canonical Examples

- `core/design/` — 11 skills absorbed, mode-based routing
- `core/audit/` — dynamic domain routing via `references/{domain}-checklist.md`
- `core/research/` — 4 skills absorbed (web-search, delegate, thinktank, introspect)

### Budget Impact

Budget scales O(umbrellas), not O(skills). Adding sub-capabilities costs zero budget.

## Skill Creation Workflow

### 0. Research Best Practices

**Before extracting, search for current patterns:**

```bash
# Use Gemini CLI for web-grounded research
gemini "[technology] [feature] best practices 2026"
gemini "[technology] [problem type] official recommendations"
```

Why: Don't just codify what you did. Incorporate current best practices.
Skip if: Pattern is project-specific internal convention.

### 0.5. Classify Skill Type

Before creating, determine if foundational or workflow:

| Type | Characteristics | Frontmatter | Action |
|------|-----------------|-------------|--------|
| **Foundational** | Universal patterns, applies broadly, no explicit trigger needed | `user-invocable: false` | Add compressed summary to CLAUDE.md |
| **Workflow** | Explicit trigger, action-oriented, user/model invokes | (default) | Skill only |

**If Foundational:**
1. Write skill as normal with `user-invocable: false`
2. Create 20-30 line compressed summary extracting core principles
3. Add summary to CLAUDE.md "Passive Knowledge Index" section
4. Add skill to Skills Index (pipe-delimited format)
5. Inform user: "Added to passive context — no invocation needed"

**If Workflow:**
1. Write skill as normal (default is invocable)
2. No CLAUDE.md changes needed
3. Inform user of trigger terms

**Foundational indicators:**
- Would benefit all code, not specific triggers
- Patterns that should "always be on"
- Language-agnostic principles
- Universal conventions (naming, testing, docs)

**Workflow indicators:**
- Explicit action verb (audit, configure, check, fix)
- Specific domain (stripe, posthog, lightning)
- User would say "/skill-name" to invoke

### 1. Identify the Knowledge
- What problem does this solve?
- What trigger terms would activate it?
- Is it cross-project or project-specific?
- Which tier should hold it: hot memory, specialist, cold memory, or hook?

### 2. Draft Structure
Reference `references/structure-guide.md` for ideal anatomy.

### 3. Write Description
Reference `references/description-patterns.md` for trigger-rich descriptions (~100 words, explicit trigger terms).

### 4. Validate
Run `scripts/validate_skill.py <skill-path>` to check structure and frontmatter.

Also verify:
- Metadata is concise and trigger-rich
- Body stays lean; push detail into `references/`
- No absolute paths unless the runtime truly requires them
- Tool scope is explicit when a skill depends on special tools

### 5. Inform User
After creating, tell user:
- What skill was created and why
- What triggers will activate it
- How to test it works

## Progressive Disclosure

Keep SKILL.md lean (<100 lines). Put detailed specs in `references/`:
- Detailed examples → `references/examples.md`
- Edge cases → `references/edge-cases.md`
- Anti-patterns → `references/anti-patterns.md`

Beware brevity bias: compress aggressively for general doctrine, but do not
over-compress high-failure domains that need real mental models.

## Code Opportunities

If skill involves deterministic operations (validation, parsing, extraction), create `scripts/` with executable code rather than prose instructions. Scripts:
- Run without loading into context
- Must be executable (`chmod +x`)
- Should handle errors gracefully

## Skill Locations

- Personal: `~/.claude/skills/` - Available across all projects
- Project: `.claude/skills/` - Shared with team via git

## Template

Use `templates/SKILL-TEMPLATE.md` as starting point for new skills.
