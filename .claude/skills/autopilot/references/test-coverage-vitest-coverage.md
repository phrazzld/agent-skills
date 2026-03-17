# Coverage Strategy

## v8 vs Istanbul (Vitest 3.2+)

| Provider | Accuracy | Speed | Setup |
|----------|----------|-------|-------|
| `v8` | High (fixed in 3.2) | Fast | Built-in |
| `istanbul` | High | Slower | Requires babel plugin |

**Recommendation**: Use `v8` - it's now accurate and faster.

## Always Define coverage.include

```typescript
coverage: {
  provider: 'v8',
  include: ['src/**/*.{ts,tsx}'],  // REQUIRED - defaults miss files
  exclude: [
    '**/*.d.ts',
    '**/*.test.{ts,tsx}',
    '**/test/**',
    '**/__mocks__/**',
  ],
}
```

Without `include`, Vitest only covers files imported by tests. Untested files show 0% instead of being flagged.

## Patch Coverage > Overall Coverage

Focus on **changed lines**, not project-wide percentages.

```yaml
# GitHub Actions with coverage diff
- uses: coverallsapp/github-action@v2
  with:
    flag-name: Unit
    parallel: true
```

Configure PR checks to require 80%+ coverage on **changed lines**, not overall.

## Ignore Comments

```typescript
// v8 provider
/* v8 ignore next */
const debugOnly = process.env.DEBUG && expensiveOperation()

/* v8 ignore start */
if (process.env.NODE_ENV === 'development') {
  // Development-only code
}
/* v8 ignore stop */

// istanbul provider (also works with v8 in some versions)
/* istanbul ignore next */
/* istanbul ignore if */
```

## reportOnFailure

```typescript
coverage: {
  reportOnFailure: true,  // Generate coverage even when tests fail
}
```

Essential for CI - failing tests shouldn't block coverage visibility.

## Thresholds Philosophy

```typescript
coverage: {
  thresholds: {
    // Use as diagnostic, not gate
    lines: 60,
    branches: 60,
    functions: 60,
    statements: 60,
    // Per-file can catch regressions better
    perFile: true,
  },
}
```

**Anti-pattern**: High global thresholds (90%+) that encourage testing implementation details.

**Better**: Lower global threshold + strict patch coverage on PRs.
