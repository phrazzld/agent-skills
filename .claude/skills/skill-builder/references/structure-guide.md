# Skill Structure Guide

## Ideal Skill Anatomy

```
skill-name/
├── SKILL.md              # Required, lean (<100 lines)
├── references/           # On-demand detailed docs
│   ├── spec.md
│   └── examples.md
├── scripts/              # Executable code
│   └── validate.py
└── templates/            # Reusable starting points
    └── template.md
```

## SKILL.md Requirements

### Frontmatter (YAML)

```yaml
---
name: skill-name           # lowercase, hyphens, ≤64 chars
description: |             # ~100 words, ≤1024 chars
  What this skill does. When to use it.
  Include trigger terms users might say.
user-invocable: false                  # Optional: foundational/ambient skill
disable-model-invocation: true         # Optional: user-only slash command skill
argument-hint: "[optional examples]"   # Optional: menu guidance
allowed-tools: Read, Grep              # Optional: restrict/auto-approve tools
---
```

### Body Structure

1. **Purpose** (1-2 sentences)
2. **When to Use** (bullet list of triggers)
3. **Workflow** (numbered steps)
4. **References** (pointers to detailed docs)

### Command-Surface Rule

- Keep the happy path intent-first (natural language or one simple argument).
- Use flags only for deterministic mechanics (`--all`, `--list`, `--fix`), not semantic intent classification.
- Avoid flag matrices that require memorization to execute core workflows.

## When to Split into References

Move content to `references/` when:
- Section exceeds 50 lines
- Content is mutually exclusive with other sections
- Detail is only needed for specific subtasks
- Examples are extensive

## Reference File Patterns

```
references/
├── getting-started.md     # Quick setup
├── api-reference.md       # Detailed specs
├── examples.md            # Code samples
├── edge-cases.md          # Gotchas
├── anti-patterns.md       # What NOT to do
└── troubleshooting.md     # Common issues
```

## Script Patterns

Scripts should:
- Be executable (`chmod +x`)
- Accept clear arguments
- Return structured output (JSON preferred)
- Handle errors with clear messages
- Have zero dependencies when possible

Example validation script:
```python
#!/usr/bin/env python3
import sys
import yaml
import json

def validate(skill_path):
    # Return JSON with {valid: bool, errors: [], warnings: []}
    pass

if __name__ == "__main__":
    result = validate(sys.argv[1])
    print(json.dumps(result))
```

## allowed-tools Field

Use to restrict or auto-approve tools:

| Pattern | Use Case |
|---------|----------|
| `allowed-tools: Read, Grep, Glob` | Read-only analysis skill |
| `allowed-tools: Read, Edit, Write` | File modification skill |
| `allowed-tools: Bash` | Shell-focused skill |

When specified, Claude can use these tools without permission.

## Cross-Project vs Project-Specific

**Cross-project** (personal `~/.claude/skills/`):
- General best practices
- Language/framework patterns
- Personal workflows

**Project-specific** (`.claude/skills/`):
- Team conventions
- Domain-specific rules
- Project architecture decisions
