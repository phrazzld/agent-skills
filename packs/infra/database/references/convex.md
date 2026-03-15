# Convex Development

Best practices for robust, secure, performant Convex backends.

## Core Principle
**Deep modules via `convex/model/` pattern.** Most logic in plain TypeScript; query/mutation wrappers are thin.

## Critical Rules
1. **ALWAYS commit `convex/_generated/`**
2. **Index what you query** -- `.withIndex()` not `.filter()`
3. **Compound indexes** for multi-field filters
4. **Paginate everything** -- never unbounded `.collect()` on user-facing queries
5. **Trust `ctx.auth` only** -- never user-provided auth data

## Quick Reference
| Need | Use |
|------|-----|
| Read data reactively | `query` |
| Write to database | `mutation` |
| External APIs, vector search | `action` |
| Scheduled tasks | `internalMutation` / `internalAction` |

## Philosophy
- **Cost First**: Bandwidth is largest cost. Index aggressively, paginate everything.
- **Security First**: Never trust client input. Always use `ctx.auth`.
- **Reactivity is Power**: Use `useQuery` for real-time, don't forfeit with one-off fetches.
- **Type Safety**: Leverage full type chain from database to UI.

## Anti-Patterns Scanner
```bash
scripts/anti_patterns_scanner.py ./convex
```

## Detailed References
- `cost-mitigation.md` - Bandwidth optimization, indexing, pagination
- `embeddings-vectors.md` - Vector search patterns
- `query-performance.md` - Compound indexes, caching
- `security-access.md` - Auth patterns, RLS, RBAC
- `schema-migrations.md` - Expand/Contract pattern
- `architectural-patterns.md` - File organization, state machines
