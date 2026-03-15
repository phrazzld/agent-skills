---
name: database
description: |
  Database design, operations, and platform-specific patterns. Schema design principles,
  migrations, query optimization, transactions, connection pooling, and Convex-specific
  best practices. Reference skill for all database work.
user-invocable: false
---

# Database

Best practices for schema design, database operations, and platform-specific patterns.

## Schema Design Principles

### Primary Keys
- Every table MUST have a primary key
- UUIDv7 for distributed systems, auto-increment BIGINT for monoliths

### Foreign Keys
- Use FK constraints unless specific reason not to
- ON DELETE: RESTRICT (safest), CASCADE (sparingly), SET NULL (breaks audit)

### Data Types
- Money: DECIMAL (never FLOAT/DOUBLE)
- Dates without time: DATE not DATETIME
- Small sets: ENUM not VARCHAR

### Constraints
- NOT NULL on required columns, UNIQUE on natural keys, CHECK for business rules

## Decision Trees

### "Should I denormalize?"
Evidence of query perf problem? -> Tried indexes/caching? -> Read-heavy >100:1? -> Denormalize specific fields.

### "UUID or auto-increment?"
Distributed (multiple write nodes)? -> UUIDv7. Exposed to users? -> Auto-increment. Otherwise -> auto-increment.

### "Soft or hard delete?"
GDPR applies? -> Hard delete. Need audit trail? -> Audit table. High deletion rate? -> Hard delete. Otherwise -> soft delete.

## Database Operations

### Migrations
Forward-only. No rollbacks. Maintain backward compatibility.
Break large changes into smaller steps. Use feature flags during transitions.

### Query Optimization
Always check `EXPLAIN ANALYZE` before optimizing. Index based on actual query patterns.
Monitor unused indexes. Remove if `idx_scan < 100`.

### N+1 Prevention
Always eager load in loops. Use `joinedload` or equivalent.

### Transactions
Scope to single business operation. Keep short. Never hold during external calls.

### Connection Pooling
Size based on measured peak concurrency. Alert at 80% utilization.

## Anti-Patterns
- EAV (entity-attribute-value) patterns
- God tables (>50 columns)
- Multi-valued fields (CSV in columns)
- Rollback migrations
- N+1 queries in loops
- Long transactions with external calls

## References

| Reference | Content |
|-----------|---------|
| `references/schema-design.md` | Detailed schema principles, anti-patterns, normalization |
| `references/operations.md` | Migrations, queries, transactions, connection pooling |
| `references/convex.md` | Convex-specific patterns (indexes, pagination, ctx.auth, model/) |
