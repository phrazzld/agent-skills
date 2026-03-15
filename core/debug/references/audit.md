# /audit

> **Dynamic domain routing.** Domains are discovered by scanning checklist files
> in `references/*-checklist.md` and `generated-references/*-checklist.md`.
> Core checklists ship with the skill. Pack checklists appear after loading a
> pack via `sync.sh pack <name> <project>`, which symlinks pack audit-references
> into `generated-references/`. The `--list` flag scans both directories.
>
> After absorption into debug, the audit checklists live at
> `core/debug/references/audit-*-checklist.md` (core) and pack checklists
> should be symlinked into `core/debug/generated-references/` at pack load time.

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

**Dynamic.** Domains are discovered by scanning `references/*-checklist.md` and
`generated-references/*-checklist.md`.

Core domains ship with this skill. Pack domains (payments, growth, scaffold)
appear after loading a pack via `sync.sh pack <name> <project>`, which
symlinks pack checklists into `generated-references/`.

To list available domains:
```bash
find audit/references audit/generated-references -maxdepth 1 -name '*-checklist.md' 2>/dev/null | sed 's|.*audit/[^/]*/||;s|-checklist.md||' | sort -u
```

## Process

### 1. Load Domain Checklist

Read `references/{domain}-checklist.md`, or `generated-references/{domain}-checklist.md`
if the domain came from a loaded pack.

If `--list`, scan both checklist directories and list unique domain names.

If `--all`, load all checklist files from both directories. Auto-detect
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
