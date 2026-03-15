# Database Operations

## Migrations
Forward-only. No rollbacks. Maintain backward compatibility:
```sql
-- Add nullable column (backward compatible)
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
-- Later: make required after backfill
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
```

## Query Optimization
```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123;

-- Composite for common query
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at DESC);
-- Partial for filtered queries
CREATE INDEX idx_orders_pending ON orders (status) WHERE status = 'pending';
```

## N+1 Prevention
```python
# Good
users = User.query.options(joinedload(User.posts)).all()
# Bad (N+1)
users = User.query.all()
for user in users:
    print(user.posts)  # N queries!
```

## Transactions
```python
async with db.transaction():
    order = await create_order(data)
    await update_inventory(order.items)
# OUTSIDE transaction: send emails, call external APIs
```

## Connection Pooling
```python
create_engine(url, pool_size=15, max_overflow=5, pool_timeout=30, pool_recycle=3600, pool_pre_ping=True)
```

## Data Validation
Validate at boundaries: input before INSERT, output after retrieval.
