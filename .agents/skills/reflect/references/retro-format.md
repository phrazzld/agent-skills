# Retro Format

## Storage

```
{repo}/.groom/retro/<issue>.md
```

Created automatically if missing. One file per issue to avoid branch-hot append conflicts.

## Entry Format

```markdown
## Entry: #{issue} -- {title} ({date})

**Effort:** predicted {predicted} -> actual {actual}
**Scope changes:** {what changed}
**Blockers:** {what blocked}
**Pattern:** {reusable insight}

---
```

## Manual Invoke

```
/reflect append --issue 42 --predicted m --actual l --scope "Added retry logic" --blocker "Undocumented API"
```

## How /groom Uses Retro

During planning, `/groom` reads `.groom/retro/*.md` and extracts:
- Effort calibration ("Payment issues take 1.5x estimates")
- Scope patterns ("Webhook issues always need retry logic")
- Blocker patterns ("External API docs frequently wrong")
- Domain insights ("Bitcoin wallet needs regtest testing")
- Bloat patterns ("Agent kept layering fallback paths instead of deleting old code")
