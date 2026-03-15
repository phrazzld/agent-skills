# Mechanical Enforcement

Encode boundaries in tooling, not documentation. Trust tools over instructions.

## Guardrail Hierarchy

From most to least reliable:

```
1. Type system      -- compile-time, zero runtime cost, impossible to bypass
2. Linter rules     -- fast local feedback, auto-fixable, catch patterns
3. Tests            -- runtime verification, catch regressions, prove behavior
4. Git hooks        -- pre-commit/push gates, last local defense
5. CI checks        -- remote verification, catches what local missed
6. Instructions     -- CLAUDE.md rules, prompt constraints, documentation
7. Conventions      -- team norms, unwritten rules, tribal knowledge
```

**Rule:** Encode at the highest level possible. If a type can express
the constraint, don't rely on a test. If a test can catch it, don't
rely on a code review instruction.

## Type System as Enforcement

The type system is the most reliable enforcement mechanism because
violations are caught at compile time with zero ambiguity.

```typescript
// Bad: Instruction: "Always validate user input before database queries"
function getUser(id: string) { ... }  // Any string accepted

// Good: Mechanical: Type makes invalid states unrepresentable
type UserId = string & { readonly __brand: 'UserId' };
function validateUserId(input: string): UserId | Error { ... }
function getUser(id: UserId) { ... }  // Only validated IDs accepted
```

**Branded types, newtypes, and opaque types** make it structurally
impossible to pass unvalidated data where validated data is expected.

## Dependency Layer Enforcement

Define architectural layers and enforce import direction:

```
Types -> Config -> Repo -> Service -> Runtime -> UI
  ^ can import from left, cannot import from right
```

**Mechanical enforcement options:**
- ESLint `import/no-restricted-paths` -- lint-time, fast
- `dependency-cruiser` -- generates dependency graphs, CI check
- TypeScript project references -- compile-time layer boundaries
- Go internal packages -- language-level visibility

```javascript
// eslint config for layer enforcement
"import/no-restricted-paths": ["error", {
  zones: [{
    target: "./src/types",
    from: ["./src/config", "./src/repo", "./src/service", "./src/ui"],
    message: "Types layer cannot import from other layers"
  }]
}]
```

## Schema Validators as Pre-Commit

Catch configuration errors before they reach CI:

```bash
#!/bin/bash
# .githooks/pre-commit

# Validate OpenAPI spec
npx @redocly/cli lint openapi.yaml || exit 1

# Validate environment config schema
npx ajv validate -s config.schema.json -d config/*.json || exit 1

# Validate CLAUDE.md frontmatter
python scripts/validate_skill_frontmatter.py core/*/SKILL.md || exit 1
```

**Why pre-commit?** CI feedback takes minutes. Pre-commit takes seconds.
For agents, the difference between 5-second and 5-minute feedback
determines whether they self-correct or context-switch and forget.

## Structural Tests for Architecture

Tests that verify architectural invariants, not business logic:

```typescript
// No service imports types from UI layer
test('service layer has no UI dependencies', () => {
  const serviceFiles = glob.sync('src/service/**/*.ts');
  for (const file of serviceFiles) {
    const content = readFileSync(file, 'utf-8');
    expect(content).not.toMatch(/from ['"].*\/ui\//);
  }
});

// All API endpoints have error handling middleware
test('all routes use error handler', () => {
  const routeFiles = glob.sync('src/routes/**/*.ts');
  for (const file of routeFiles) {
    const content = readFileSync(file, 'utf-8');
    if (content.includes('router.')) {
      expect(content).toContain('errorHandler');
    }
  }
});
```

**These tests act as guardrails that agents hit and learn from.**
When an agent violates an architectural boundary, the test fails with
a clear message, and the agent self-corrects.

## When to Trust the Agent vs Encode in Tooling

| Encode in Tooling | Trust the Agent |
|-------------------|-----------------|
| Security boundaries | Code style preferences |
| Data integrity constraints | Naming conventions |
| Architectural layer violations | Comment quality |
| API contract compliance | Refactoring decisions |
| Dependency direction | Test strategy |
| Configuration validity | Error message wording |

**Heuristic:** If violation is invisible at runtime but catastrophic
in production -> encode in tooling. If violation is visible and
non-catastrophic -> trust the agent.

## Anti-Patterns

### Documentation-Only Enforcement
```
Bad:  CLAUDE.md: "Never import from the UI layer in services"
      -> Agent might miss it, no feedback when violated

Good: Lint rule + test that fails with clear error message
      -> Agent sees error, self-corrects, learns
```

### Permissive Type Systems
```
Bad:  function processPayment(amount: number, currency: string)
      -> Agent can pass any number and any string

Good: function processPayment(amount: PositiveInt, currency: CurrencyCode)
      -> Invalid inputs are impossible
```

### Late Feedback
```
Bad:  Architectural violation caught in code review (hours later)
      -> Agent has lost context, fix is expensive

Good: Architectural violation caught by pre-commit hook (seconds later)
      -> Agent has full context, fix is immediate
```
