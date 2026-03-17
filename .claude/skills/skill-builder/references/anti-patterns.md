# Skill Anti-Patterns

Common mistakes when building agent skills.

## Structure Anti-Patterns

### Monolithic SKILL.md
**Problem**: All content in one file (300+ lines)
**Fix**: Extract detailed sections to `references/`

### No Progressive Disclosure
**Problem**: Claude loads entire skill even when only part is needed
**Fix**: Keep SKILL.md lean, load references on-demand

### Missing Frontmatter
**Problem**: Skill won't be discovered
**Fix**: Always include `name` and `description` in YAML frontmatter

## Description Anti-Patterns

### Vague Description
```yaml
# BAD
description: Helps with coding.

# GOOD
description: |
  Apply Python best practices for type hints, testing, and project structure.
  Use when writing Python code, reviewing Python PRs, or setting up Python projects.
```

### Missing Trigger Terms
```yaml
# BAD - no actionable triggers
description: Database knowledge base.

# GOOD - explicit triggers
description: |
  Design PostgreSQL schemas. Use when creating tables, adding indexes,
  writing migrations, or optimizing queries. Keywords: CREATE TABLE,
  foreign key, index, normalization, JSONB, array types.
```

### Too Long
**Problem**: Over 1024 characters gets truncated
**Fix**: Be concise, move detail to SKILL.md body

## Content Anti-Patterns

### Duplicating Standard Knowledge
**Problem**: Repeating what Claude already knows
**Fix**: Focus on YOUR conventions, not general best practices

### Outdated Information
**Problem**: Recommendations become stale
**Fix**: Reference external docs, include version numbers

### No Examples
**Problem**: Abstract guidance without concrete patterns
**Fix**: Include before/after code examples

### Contradicting Other Skills
**Problem**: Skills give conflicting advice
**Fix**: Coordinate skill set, use shared conventions

### Flag Explosion
**Problem**: Core workflow requires remembering multiple UNIX-style flags
**Fix**: Keep happy path intent-first; reserve flags for deterministic mechanics only

## Script Anti-Patterns

### Non-Executable Scripts
**Problem**: Missing `chmod +x`
**Fix**: Always set execute permission

### Heavy Dependencies
**Problem**: Requires complex environment setup
**Fix**: Use standard library when possible

### No Error Handling
**Problem**: Fails silently or cryptically
**Fix**: Return structured errors with clear messages

### Loading Code as Context
**Problem**: Script content loaded into Claude's context
**Fix**: Scripts should be EXECUTED, not READ

## allowed-tools Anti-Patterns

### Too Permissive
**Problem**: Skill grants unnecessary tool access
**Fix**: Restrict to minimum needed tools

### Too Restrictive
**Problem**: Skill can't accomplish its purpose
**Fix**: Include all tools required for the workflow

## Testing Anti-Patterns

### No Trigger Testing
**Problem**: Skill doesn't activate when expected
**Fix**: Test with various phrasings users might use

### No Edge Case Testing
**Problem**: Skill fails on unusual inputs
**Fix**: Test boundary conditions

## Red Flags Checklist

- [ ] SKILL.md > 150 lines without references/
- [ ] Description < 50 characters
- [ ] No trigger terms in description
- [ ] Scripts without execute permission
- [ ] references/ files never loaded
- [ ] Contradicts CLAUDE.md guidance
- [ ] Duplicates another skill's purpose
- [ ] Core happy path requires memorizing multiple flags
