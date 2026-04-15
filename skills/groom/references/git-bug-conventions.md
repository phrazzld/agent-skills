# git-bug Conventions

## Routing Heuristic

**git-bug** is preferred when installed. Falls back to `gh issue` when absent.
Argument routing: hex prefix (e.g. `abc1234`) → git-bug; `#N` → GitHub Issues.

## Label Taxonomy

| Category | Labels | Purpose |
|----------|--------|---------|
| Priority | `priority/p0` `priority/p1` `priority/p2` `priority/p3` | Urgency |
| Domain | `domain/<name>` (e.g. `domain/auth`, `domain/ci`) | Area of codebase |
| Type | `type/bug` `type/enhancement` `type/chore` | Nature of work |
| Status | `status/shaped` | Ready for `/deliver` (has oracle) |

## Lifecycle

1. **Create:** `git-bug bug new -t "title" -m "body" --non-interactive`
2. **Label:** `git-bug bug label new <id> "priority/p1" "domain/auth"`
3. **Query:** `git-bug bug status:open --label "priority/p0" --format json`
4. **Close:** `git-bug bug status close <id>`
5. **Sync:** `git-bug push origin`

## GitHub Bridge

GitHub Issues is an **optional sync target** (currently empty across all repos).
`git-bug push origin` creates issues there for human visibility when desired.
