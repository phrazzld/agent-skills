# /log-issues

Audit a domain, create issues for every finding.
Uses git-bug if installed (issues travel with repo, offline-first).
Falls back to `backlog.d/` items if git-bug is absent.

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

**git-bug (preferred):**
```bash
git-bug bug --label "domain/{domain}" --status open --format json
```

**backlog.d/ (fallback):**
```bash
ls backlog.d/  # check existing items by title/filename
```

Skip findings that match existing open issues or backlog items (by title similarity).

### 3. Create Issues

For each new finding:

**git-bug (preferred):**
```bash
git-bug bug new \
  --title "[P{0-3}] {Domain} - {description}" \
  --message "$(cat <<'EOF'
## Problem
{What's wrong}

## Impact
{Business/security/user impact}

## Location
{File:line if applicable}

## Suggested Fix
{Code snippet or skill to run}

---
Created by `/log-issues`
EOF
)" \
  --non-interactive
# Then add labels:
git-bug bug label new <bug-id> "priority/p{0-3}" "domain/{domain}" "type/{bug|enhancement|chore}"
```

**backlog.d/ (fallback):**
Create a file `backlog.d/NNN-{slug}.md` with the standard format:
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

**Labels:**
- `priority/p0` | `priority/p1` | `priority/p2` | `priority/p3`
- `domain/{domain}`
- `type/bug` | `type/enhancement` | `type/chore`

**Body sections:** Problem, Impact, Location, Suggested Fix

### 5. Sync (git-bug only)

After creating all issues, push to sync with GitHub bridge:
```bash
git-bug push origin
```

### 6. Report

```
Created 7 issues for domain/stripe:
  - [P0] abc1234: Missing webhook signature verification
  - [P1] def5678: No customer portal configured
  - [P1] ghi9012: Subscription status not checked
  Skipped 2 (duplicates of existing open issues)
  Synced to GitHub via bridge.
```

## Related

- `/audit <domain>` -- Audit without creating issues
- `/fix <domain>` -- Fix issues instead of logging them
- `/groom` -- Runs `/log-issues --all` as part of backlog hygiene
