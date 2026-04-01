# /audit

> **Dynamic domain routing.** Domains are discovered by scanning checklist files
> in `references/*-checklist.md`. The `--list` flag scans this directory.

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

To list available domains:
```bash
find references -maxdepth 1 -name '*-checklist.md' 2>/dev/null | sed 's|.*/||;s|-checklist.md||' | sort -u
```

## Process

### 1. Load Domain Checklist

Read `references/{domain}-checklist.md`.

If `--list`, scan the checklist directory and list unique domain names.

If `--all`, load all checklist files. Auto-detect
applicable domains from project (check package.json deps, config files,
directory structure) and skip N/A domains.

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
