# Deferred Issue Template

Use this template when creating GitHub issues for out-of-scope review findings.

## Template

```markdown
## Origin

Surfaced during code review of PR #[PR_NUMBER] / branch `[BRANCH_NAME]`

**Reviewer:** [REVIEWER_NAME] (e.g., security-sentinel, Grug, Fowler)

## Finding

> [QUOTE THE EXACT FINDING FROM THE REVIEW]

**File(s):** `[FILE:LINE]` (if applicable)

## Context

[Brief description of why this was flagged and why it's being deferred]

## Recommended Action

[What should be done to address this finding]

## Priority

**Severity:** [Critical / Important / Suggestion]
**Why deferred:** [Pre-existing / Architectural / Out of scope / Needs profiling / etc.]

## Acceptance Criteria

- [ ] [Specific measurable outcome 1]
- [ ] [Specific measurable outcome 2]
- [ ] Tests added proving the fix

---
*Created by `/address-review` from [REVIEWER] finding*
*Original PR: #[PR_NUMBER]*
```

## Example Issues

### Security Finding (Pre-existing)

```markdown
## Origin

Surfaced during code review of PR #42 / branch `feature/user-auth`

**Reviewer:** security-sentinel

## Finding

> `utils/crypto.ts:23` — Using MD5 for password hashing. MD5 is cryptographically broken.

**File(s):** `utils/crypto.ts:23`

## Context

This issue predates PR #42. The auth feature touched adjacent code, which triggered the review finding. Fixing requires migration strategy for existing hashed passwords.

## Recommended Action

1. Switch to bcrypt or argon2 for new passwords
2. Create migration plan for existing users (rehash on next login)
3. Add password hashing tests

## Priority

**Severity:** Critical
**Why deferred:** Pre-existing issue requiring migration strategy

## Acceptance Criteria

- [ ] New passwords use bcrypt with cost factor 12+
- [ ] Existing passwords rehashed on successful login
- [ ] Legacy MD5 code removed after migration period
- [ ] Tests verify secure hashing

---
*Created by `/address-review` from security-sentinel finding*
*Original PR: #42*
```

### Architectural Suggestion

```markdown
## Origin

Surfaced during code review of PR #87 / branch `feature/order-processing`

**Reviewer:** Grug

## Finding

> Order processing has 8 layers of indirection. Grug head hurt. Could be 3 layers: Controller → Service → Repository.

**File(s):** `src/orders/` (multiple files)

## Context

Current architecture evolved organically. Simplifying requires coordinated refactor across multiple features. Not safe to do mid-feature.

## Recommended Action

1. Map current call graph
2. Identify which layers add value vs pass-through
3. Design simplified architecture
4. Refactor in dedicated PR with full test coverage

## Priority

**Severity:** Suggestion
**Why deferred:** Architectural change requiring design discussion

## Acceptance Criteria

- [ ] Architecture diagram showing before/after
- [ ] Call depth reduced from 8 to ≤4 layers
- [ ] No behavior changes (all existing tests pass)
- [ ] Performance maintained or improved

---
*Created by `/address-review` from Grug finding*
*Original PR: #87*
```

### Performance Finding (Needs Profiling)

```markdown
## Origin

Surfaced during code review of PR #103 / branch `feature/report-export`

**Reviewer:** performance-pathfinder

## Finding

> `reports/export.ts:45` — Potential N+1 query pattern when fetching report items. Each item triggers separate DB call.

**File(s):** `reports/export.ts:45`

## Context

This may or may not be a real performance issue. Need to profile with production-like data volumes before optimizing.

## Recommended Action

1. Add performance test with realistic data (1000+ items)
2. Profile query execution
3. If confirmed: batch queries or use JOIN
4. If not confirmed: document why current approach is acceptable

## Priority

**Severity:** Important
**Why deferred:** Needs profiling before optimization

## Acceptance Criteria

- [ ] Performance test added
- [ ] Profile data captured
- [ ] Decision documented (optimize or accept)
- [ ] If optimized: query count reduced to O(1) or O(log n)

---
*Created by `/address-review` from performance-pathfinder finding*
*Original PR: #103*
```

## Labels to Apply

Based on finding type:

| Finding Type | Labels |
|--------------|--------|
| Security | `security`, `priority:high` |
| Performance | `performance`, `needs-profiling` |
| Architecture | `architecture`, `tech-debt` |
| Code smell | `refactor`, `code-quality` |
| Pre-existing | `pre-existing`, `improvement` |
| Suggestion | `enhancement`, `priority:low` |

## CLI Command

```bash
gh issue create \
  --title "[Type] Brief description" \
  --label "from-review,tech-debt" \
  --body "$(cat <<'EOF'
[paste template content]
EOF
)"
```
