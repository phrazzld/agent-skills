---
name: audit
description: |
  Audit any domain with a checklist in references/. Run /audit <domain> for
  structured P0-P3 findings report. /audit --all for everything.
  /audit --list to see available domains. Dynamic: pack checklists appear
  when loaded via sync.sh.
  Invoke for: domain audit, compliance check, launch readiness, gap analysis.
argument-hint: "<domain|--all|--list>"
disable-model-invocation: true
---

# /audit

Structured domain audit. One skill, all domains.

## Usage

```
/audit stripe               # Audit Stripe integration
/audit production            # Audit production readiness
/audit docs                  # Audit documentation
/audit --all                 # Run all applicable domains
/audit --list                # Show available domains
```

## Available Domains

**Dynamic.** Domains are discovered by scanning `references/*-checklist.md`.

Core domains ship with this skill. Pack domains (payments, growth, scaffold)
appear after loading a pack via `sync.sh pack <name> <project>`, which
symlinks pack checklists into `references/`.

To list available domains:
```bash
ls audit/references/*-checklist.md | sed 's|.*references/||;s|-checklist.md||'
```

## Process

### 1. Load Domain Checklist

Read `references/{domain}-checklist.md` for the requested domain.

If `--list`, scan `references/*-checklist.md` and list available domain names.

If `--all`, load all checklist files. Auto-detect applicable domains from project
(check package.json deps, config files, directory structure) and skip N/A domains.

### 2. Execute Checks

For each check in the domain checklist:

1. Run the shell commands listed
2. Classify result as PASS/FAIL/WARN
3. Map failures to priority using the checklist's priority table

### 3. Output Report

```markdown
## {Domain} Audit

### P0: Critical
- [finding]: [detail]

### P1: Essential
- [finding]: [detail]

### P2: Important
- [finding]: [detail]

### P3: Nice to Have
- [finding]: [detail]

## Summary
- P0: N | P1: N | P2: N | P3: N
- Recommendation: [top action]
```

### 4. Parallel Execution (`--all`)

When `--all`, run all applicable domain checklists in parallel.
Merge results into a single report organized by domain.

## Related

- `/fix <domain>` -- Fix issues found by audit
- `/log-issues <domain>` -- Create GitHub issues from audit findings
- `/groom` -- Runs `/audit --all` as part of backlog hygiene
