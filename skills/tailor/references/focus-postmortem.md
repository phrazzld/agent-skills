# Critic Checklist — /focus postmortem

The critic runs once in `/tailor`'s pick step. One round. No loop.
Any blocking objection aborts the pick.

This is the structural differentiator from `/focus`, which shipped
71 commits over two months (87 skills, 41 auditors) before being
killed in March 2026 for ceremony-to-value inversion. The criteria
below encode the failure modes that killed it, *scoped to the
categories where they apply*.

## Scope: which criteria apply to which category

`/tailor`'s picking defaults (see `SKILL.md`) distinguish three
categories: universal, workflow, domain. The critic applies
different criteria to each.

| Category | Default | Critic criteria |
|---|---|---|
| Universal (research, groom, reflect, …) | **include** | 1 only |
| Workflow (deliver, ci, qa, flywheel, …) | **include unless infrastructure missing** | 1, 2 |
| Domain (invented: `/convex-migrate` etc.) | **exclude unless concrete** | 1, 2, 3, 4 |

A workflow skill with present infrastructure (real CI, real tests,
real deploy) passes the critic automatically. Criterion 4 exists to
reject speculative domain inventions, not workflow inclusion.

## 1. Does this duplicate a truly global skill?

**Reject if yes.** Only two skills are globally installed:
`/tailor` and `/seed`. A project-local copy of either is dead weight.

(Other primitives are *meant* to be installed per-repo under the
minimal-globals model. This criterion only flags the two globals.)

## 2. Would a scaffold-on-demand skill cover it?

**Reject if yes.** `/qa scaffold`, `/demo scaffold`, etc. generate
repo-specific scaffolding on invocation. Don't pre-bake their output
into a separate skill.

- Reject: a tailored `/qa` that hardcodes this repo's test golden
  paths (that's what `/qa scaffold` produces on demand)
- Allow: a `settings.local.json` permissions entry that lets `/qa
  scaffold` run without prompts

## 3. Is the domain set focused, or 41-auditor ceremony?

**Reject if invented domain skills sprawl** into near-duplicate
reviewers or kitchen-sink single skills. This criterion *does not
apply to the workflow category* — 12 workflow skills is not
ceremony, it's the inner and outer loops. It applies to domain
inventions only.

- Reject: four near-duplicate Rust reviewers (`unsafe-`, `lifetime-`,
  `trait-bound-`, `generic-reviewer`) when one would do
- Allow: one focused `rust-unsafe-reviewer` if the repo has unusual
  `unsafe` patterns that justify it

## 4. For domain inventions: can you name the concrete characteristic?

**Reject if no.** A proposed domain skill must correspond to a
concrete repo characteristic the planner can state in one sentence.
"This repo uses Convex with live-traffic schema migrations and
`v.optional` upgrade paths" → `/convex-migrate` makes sense.
"This might be useful someday" → reject.

This criterion does not apply to workflow skills — their
justification is already encoded in the default: present
infrastructure means the skill earns its place.

## Stopping condition

Critic emits a list of blocking objections (possibly empty). The
pick proceeds iff empty. No round 2. No appeals. User can re-run
`/tailor` with different inputs or adjust the planner's
instructions.
