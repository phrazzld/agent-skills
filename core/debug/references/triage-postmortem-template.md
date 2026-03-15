# Postmortem Template

Absorbed from the `postmortem` skill.

## Philosophy

- **Blameless**: Focus on systems, processes, and tools -- not people
- **Honest**: Don't minimize or exaggerate
- **Actionable**: Every lesson should have a concrete follow-up

## Template

```markdown
# Postmortem: [Incident Title]

**Date:** YYYY-MM-DD
**Duration:** X hours
**Severity:** P0/P1/P2
**Author:** [name]

## Summary

One paragraph: what happened, impact, resolution.

## Timeline (UTC)

| Time | Event |
|------|-------|
| HH:MM | First alert / user report |
| HH:MM | Investigation started |
| HH:MM | Root cause identified |
| HH:MM | Fix deployed |
| HH:MM | Verified resolved |

## Root Cause

[The actual underlying cause, not symptoms]

## 5 Whys

1. Why did [symptom]? Because [cause 1].
2. Why did [cause 1]? Because [cause 2].
3. Why did [cause 2]? Because [cause 3].
4. Why did [cause 3]? Because [cause 4].
5. Why did [cause 4]? Because [systemic root cause].

## What Went Well

- [Recognition of good practices during response]

## What Went Wrong

- [Honest assessment without blame]

## Follow-up Actions

| Action | Owner | Due |
|--------|-------|-----|
| [concrete item] | [person/team] | [date] |

## Lessons Learned

[What should change to prevent recurrence]
```

## Storage

Write to `docs/postmortems/YYYY-MM-DD-ISSUE-ID.md`.

If `INCIDENT-{timestamp}.md` exists, update its postmortem section instead.
