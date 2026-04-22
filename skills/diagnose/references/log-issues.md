# /log-issues

Audit a domain, create `backlog.d/` items for every finding.

## Usage

```
/log-issues stripe           # Audit Stripe, create issues
/log-issues production        # Audit production, create issues
/log-issues --all             # Audit everything, create issues for all findings
```

## Domains

**Dynamic.** Scan `references/*-checklist.md` for available domains.

## Process

### 1. Audit

Read `audit/references/{domain}-checklist.md`, or
`audit/generated-references/{domain}-checklist.md` for pack-provided domains,
and run all checks.
If `--all`, run all applicable domain checklists.

### 2. Deduplicate

```bash
ls backlog.d/  # check existing items by title/filename
```

Skip findings that match existing backlog items (by title similarity).

### 3. Create Issues

For each new finding, create a file `backlog.d/NNN-{slug}.md` with the standard format:

```markdown
# [P{0-3}] {finding description}

Priority: {p0|p1|p2|p3}
Status: ready
Estimate: S

## Goal
{What's wrong — one sentence}

## Oracle
- [ ] {mechanically verifiable fix criterion}

## Notes
Domain: {domain}. Created by `/log-issues`.
```

### 4. Issue Format

**Title:** `[P{0-3}] {Domain} - {description}`

**Priority:** `p0` | `p1` | `p2` | `p3`
**Labels (in Notes):** `domain/{domain}`, `type/bug` | `type/enhancement` | `type/chore`

**Body sections:** Goal, Oracle, Notes (with Problem, Impact, Location, Suggested Fix where useful)

### 5. Report

```
Created 7 backlog.d/ items for domain/stripe:
  - backlog.d/042-stripe-webhook-sig.md: [P0] Missing webhook signature verification
  - backlog.d/043-stripe-portal.md: [P1] No customer portal configured
  - backlog.d/044-stripe-subscription-check.md: [P1] Subscription status not checked
  Skipped 2 (duplicates of existing backlog items)
```

## Related

- `/audit <domain>` -- Audit without creating issues
- `/fix <domain>` -- Fix issues instead of logging them
- `/groom` -- Runs `/log-issues --all` as part of backlog hygiene
