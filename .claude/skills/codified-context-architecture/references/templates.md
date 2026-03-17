# Context Architecture Templates

## `docs/context/INDEX.md`

```markdown
# Context Index

| Subsystem | Docs | Source Files | Notes |
|-----------|------|--------------|-------|
| auth | `docs/context/auth.md` | `src/auth/**` | session + token flows |
```

## `docs/context/ROUTING.md`

```markdown
# Routing Table

| Trigger | Signal | Route |
|---------|--------|-------|
| Pre-change | `src/payments/**` | `stripe` specialist |
| Post-change | auth/session files | security review |
```

## `docs/context/DRIFT-WATCHLIST.md`

```markdown
# Drift Watchlist

| Files Changed | Review These Docs |
|---------------|-------------------|
| `src/auth/**` | `docs/context/auth.md` |
| `src/payments/**` | `docs/context/payments.md` |
```
