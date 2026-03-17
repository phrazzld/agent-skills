# GitHub Issues

## Use the platform primitives for what they are good at

- Issues: canonical units of work and decision
- Sub-issues: parent-child decomposition for epics and large initiatives
- Dependencies: sequencing when one issue blocks another
- Labels: taxonomy for slicing and filtering
- Milestones: timebox or release grouping
- Projects: workflow, roadmap, and portfolio views
- Issue forms / templates: structured intake and consistent issue bodies

## Recommended structure

### Intake

Use issue forms or templates so new bugs and requests arrive with the minimum facts needed for
triage. Keep forms short enough that people complete them, but structured enough that duplicate and
incomplete reports are obvious.

### Classification

Use a small stable label taxonomy:
- priority
- type
- horizon or status
- domain
- effort

Avoid label sprawl. If a label does not improve routing, filtering, or reporting, remove it.

### Hierarchy

Use sub-issues for real decomposition, not for ornamental checklists. A parent issue should capture
the outcome and child issues should each produce a coherent slice of value or enabling work.

### Planning

Use milestones for release or sprint buckets. Use Projects for views across those buckets:
- triage inbox
- active work
- next up
- later / parking lot
- roadmap

Keep the issue body as the source of truth. Comments are for iteration, not for replacing the plan.

## GitHub-specific best practices

- Prefer editing the original issue body over scattering new requirements in comments.
- Use custom project fields when labels become overloaded for reporting.
- Keep issue forms aligned with the fields you actually triage on.
- Use dependencies when order matters; do not rely on implied sequencing.
- Close duplicates in favor of the canonical issue and link both directions.

## Suggested project fields

If you use GitHub Projects, prefer fields like:
- status
- priority
- horizon
- effort
- domain
- target milestone or release
- owner
- risk

## AI-agent adaptation

See `agent-issue-writing.md` for agent-specific issue shaping.

## Sources

- https://docs.github.com/issues/tracking-your-work-with-issues/about-issues
- https://docs.github.com/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects
- https://docs.github.com/issues/tracking-your-work-with-issues/using-issues/creating-a-sub-issue
- https://docs.github.com/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies
- https://docs.github.com/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates
- https://docs.github.com/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
- https://docs.github.com/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects
- https://docs.github.com/en/copilot/how-tos/agents/copilot-coding-agent/troubleshoot-copilot-coding-agent
