# Database Schema Design

## Quality Checklist
- [ ] Every table has primary key
- [ ] Foreign key constraints defined
- [ ] Appropriate data types (smallest sufficient)
- [ ] NOT NULL, UNIQUE, CHECK constraints
- [ ] No EAV patterns
- [ ] No god tables (>50 columns)
- [ ] No multi-valued fields (CSV in columns)
- [ ] Indexes match query patterns
- [ ] Foreign keys indexed
- [ ] Composite index column order optimized

## Naming Conventions
- Tables: plural, snake_case (`user_accounts`)
- Columns: singular, snake_case (`created_at`)
- Indexes: `idx_table_columns` (`idx_orders_user_date`)
- Constraints: `fk_table_ref`, `uk_table_column`, `ck_table_rule`

## Advanced Patterns
- **Soft delete**: Add `deleted_at` timestamp, filter in queries
- **Audit table**: Separate table with `action`, `old_values`, `new_values`
- **JSON columns**: OK for truly schemaless data, never for queryable fields
- **Temporal data**: Use `valid_from`/`valid_to` for time-varying records

**"The best schema is one you can understand in 6 months and modify with confidence."**
