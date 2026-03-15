# ast-grep Rule Anatomy

## Overview

ast-grep (`sg`) matches code patterns using structural search. Rules are YAML files
that describe a pattern to match and a message/fix to apply. Works with any language
ast-grep supports: Python, Go, Rust, TypeScript, JavaScript, C, Java, etc.

## Rule Structure

```yaml
# guardrails/rules/no-direct-db-import.yml
id: no-direct-db-import
language: python
severity: error
message: "Import db through repository layer. Direct import from '$MATCH' bypasses validation."
note: "Use: from app.repository import db"

rule:
  pattern: from $MATCH import db
  not:
    inside:
      kind: module
      has:
        pattern: "# repository-layer"   # Exception marker

fix: "from app.repository import db"
```

## Pattern Syntax

| Syntax | Meaning | Example |
|--------|---------|---------|
| `$VAR` | Single node metavariable | `from $MOD import $NAME` |
| `$$$ARGS` | Multiple nodes (variadic) | `function($$$ARGS)` |
| `$$_` | Anonymous multi-match | `{ $$$_ }` |
| Literal code | Exact match | `console.log` |

## Rule Combinators

```yaml
rule:
  # Match ALL of these
  all:
    - pattern: fetch($URL)
    - not:
        inside:
          pattern: apiClient.$METHOD($$$ARGS)

  # Match ANY of these
  any:
    - pattern: fetch($URL)
    - pattern: axios.get($URL)

  # Negate
  not:
    pattern: apiClient.$METHOD($$$ARGS)

  # Structural context
  inside:
    kind: function_declaration    # Tree-sitter node kind
    has:
      pattern: requireAuth()
```

## Config File

```yaml
# guardrails/sgconfig.yml
ruleDirs:
  - rules
```

## Running

```bash
# Scan project
sg scan --config guardrails/sgconfig.yml

# Scan single file
sg scan --config guardrails/sgconfig.yml src/api/handler.py

# Test rules (snapshot-based)
sg scan --config guardrails/sgconfig.yml --test

# Apply fixes
sg scan --config guardrails/sgconfig.yml --update-all
```

## Testing

Create test cases as YAML snapshot files alongside rules:

```yaml
# guardrails/rules/__tests__/no-direct-db-import-test.yml
id: no-direct-db-import
valid:
  - "from app.repository import db"
  - "from app.repository import get_user"
invalid:
  - "from app.db import db"
  - "from database import connection"
```

Or verify against the real codebase — 0 violations means the rule is correctly scoped.

## Tips

- **Use `kind`** from tree-sitter grammar for precise structural matching.
- **`fix` is optional** — omit if the replacement isn't mechanical.
- **`note` field** appears in output — put the fix suggestion here for Claude.
- **File filtering:** Use `files` field or pass specific paths to `sg scan`.
- **Severity:** `error`, `warning`, `info`, `hint`.
