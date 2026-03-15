# Vitest Configuration

> For advanced vitest configuration (pools, performance, mocking), see `/vitest`.

## Why Vitest
- Fast, modern test runner
- Jest-compatible API (easy migration)
- Great TypeScript support
- Built-in coverage with c8/v8
- Watch mode with intelligent re-runs

## Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './test/setup.ts',
    include: ['**/*.{test,spec}.{js,ts,jsx,tsx}'],
    exclude: ['**/node_modules/**', '**/dist/**', '**/.next/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        '**/node_modules/**',
        '**/dist/**',
        '**/.next/**',
        '**/test/**',
        '**/*.config.{js,ts}',
        '**/*.d.ts',
      ],
      // Use as diagnostic, not success metric
      thresholds: {
        lines: 60,
        functions: 60,
        branches: 60,
        statements: 60,
      },
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

## Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:ci": "vitest run --coverage",
    "test:watch": "vitest --watch",
    "typecheck": "tsc --noEmit",
    "lint": "eslint . --ext .ts,.tsx,.js,.jsx",
    "lint:fix": "eslint . --ext .ts,.tsx,.js,.jsx --fix",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,md,css}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,md,css}\""
  }
}
```

## Coverage Standards

**Patch coverage**: 80%+ for new/changed code (block if lower)
**Overall coverage**: Track but don't block
**Critical paths**: 90%+ (payment, auth, data integrity)

**Philosophy**: Coverage is a diagnostic tool, not a goal. 60% meaningful coverage beats 95% testing implementation details.
