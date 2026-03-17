# Scope Rules for Review Findings

## Decision Tree

```
Is the file in the current diff?
├── No → OUT-OF-SCOPE (pre-existing issue)
└── Yes → Continue...
    │
    Is severity Critical or Important?
    ├── No (Suggestion) → OUT-OF-SCOPE (nice-to-have)
    └── Yes → Continue...
        │
        Is the fix localized (1-3 files)?
        ├── No → OUT-OF-SCOPE (architectural change)
        └── Yes → IN-SCOPE (fix with TDD)
```

## In-Scope Indicators

Fix now if:
- **File is in diff** — You touched it, you own it
- **Critical severity** — Security, data loss, broken functionality
- **Important severity** — Convention violation, missing error handling
- **Localized fix** — Changes 1-3 files, doesn't alter APIs
- **Clear remediation** — Reviewer provided specific fix

## Out-of-Scope Indicators

Create issue if:
- **Pre-existing** — Issue existed before this branch
- **Suggestion** — Nice-to-have, not blocking
- **Systemic** — Pattern repeated across codebase (needs coordinated fix)
- **Architectural** — Requires design discussion, broad refactor
- **API change** — Would break existing callers
- **Performance** — Needs profiling before fixing (don't optimize blind)

## Gray Areas (Confirm with User)

**Pre-existing but easy fix:**
- Issue existed before, but trivial to fix while here
- Ask: "This is pre-existing but easy. Fix now or defer?"

**Suggestion that's quick:**
- Low priority but 5 minutes to implement
- Ask: "Suggestion item, but quick. Include or defer?"

**Cascading fix:**
- Fixing one thing reveals another
- Ask: "Found additional issue while fixing. Scope in or create issue?"

**Hindsight items:**
- Strategic observations, not bugs
- Usually out-of-scope unless actionable immediately

## Examples

### In-Scope

```
Finding: auth/login.ts:42 — Missing input validation
Severity: Important
File in diff? Yes
Localized? Yes (single function)
→ IN-SCOPE: Fix with TDD
```

```
Finding: api/orders.ts:17 — SQL injection vulnerability
Severity: Critical
File in diff? Yes
Localized? Yes
→ IN-SCOPE: Fix immediately with TDD
```

### Out-of-Scope

```
Finding: Similar pattern in utils/helpers.ts (not in diff)
Severity: Important
File in diff? No
→ OUT-OF-SCOPE: Pre-existing, create issue
```

```
Finding: Consider using dependency injection throughout
Severity: Suggestion
Architectural? Yes
→ OUT-OF-SCOPE: Requires design discussion, create issue
```

```
Finding: N+1 query pattern should be optimized
Severity: Important
Needs profiling? Yes
→ OUT-OF-SCOPE: Profile first, then fix. Create issue.
```

## Priority for Issues

When creating issues for out-of-scope items:

- **Critical deferred** → Label: `priority: high`, `type: bug`
- **Important deferred** → Label: `priority: medium`, `type: improvement`
- **Suggestion deferred** → Label: `priority: low`, `type: enhancement`
- **Hindsight items** → Label: `type: tech-debt` or `type: discussion`
