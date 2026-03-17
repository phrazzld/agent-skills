# Writing Effective Skill Descriptions

The `description` field determines when Claude invokes your skill. Write it carefully.

## Requirements

- ~100 words (max 1024 characters)
- Include explicit trigger terms
- Explain both WHAT and WHEN

## Structure

```
[What the skill does]. Use when:
- [Trigger scenario 1]
- [Trigger scenario 2]
- [Trigger scenario 3]
Keywords: [specific terms users might say]
```

## Good vs Bad Descriptions

### BAD: Vague, no triggers
```yaml
description: Helps with database stuff.
```

### GOOD: Specific, trigger-rich
```yaml
description: |
  Design database schemas with proper normalization, indexes, and constraints.
  Use when creating tables, designing data models, reviewing schema migrations,
  or discussing database architecture. Keywords: CREATE TABLE, foreign keys,
  indexes, normalization, ERD, data modeling, PostgreSQL, MySQL, schema design.
```

### BAD: Too short
```yaml
description: TypeScript patterns.
```

### GOOD: Comprehensive
```yaml
description: |
  Apply TypeScript best practices for type safety, generics, and advanced patterns.
  Use when writing TypeScript code, reviewing types, designing interfaces, or
  troubleshooting type errors. Covers: type narrowing, discriminated unions,
  mapped types, conditional types, utility types, strict mode, tsconfig.
```

## Trigger Term Categories

Include terms from multiple categories:

1. **Action verbs**: create, design, review, fix, optimize, refactor
2. **Domain nouns**: database, schema, API, component, service
3. **Tool names**: PostgreSQL, React, TypeScript, Convex
4. **Problem phrases**: "how to", "best practice", "error with"
5. **File patterns**: ".tsx files", "migration files", "config"

## Testing Your Description

Ask yourself:
1. If a user says "[trigger term]", would this skill help?
2. Are there synonyms I'm missing?
3. Would a non-expert use these words?

## Examples by Domain

### Frontend
```yaml
description: |
  Create distinctive frontend interfaces avoiding generic AI aesthetics.
  Use when building React components, designing layouts, choosing colors,
  selecting typography, or implementing animations. Covers: Tailwind,
  shadcn/ui, Motion, WebGL, GSAP, responsive design, accessibility.
```

### Testing
```yaml
description: |
  Apply testing best practices: TDD, behavior-focused tests, coverage strategy.
  Use when writing tests, reviewing test quality, setting up test infrastructure,
  or discussing test patterns. Keywords: Vitest, Jest, unit test, integration test,
  mock, stub, AAA pattern, test coverage, edge cases.
```

### DevOps
```yaml
description: |
  Configure CI/CD pipelines, Docker containers, and deployment workflows.
  Use when setting up GitHub Actions, writing Dockerfiles, configuring
  environments, or automating deployments. Covers: Vercel, AWS, containers,
  secrets management, environment variables, build optimization.
```
