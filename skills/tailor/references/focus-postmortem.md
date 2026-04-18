# Critic Checklist — /focus postmortem

The critic runs once in `/tailor`'s pick step against every primitive
the planner proposes. One round. No loop. Any blocking objection
aborts the pick.

This is the structural differentiator from `/focus`, which shipped
71 commits over two months (87 skills, 41 auditors) before being
killed in March 2026 for ceremony-to-value inversion. The four
criteria below encode the failure modes.

Apply in order. First rejection wins; stop evaluating.

## 1. Does this already exist globally?

**Reject if yes.** Global spellbook primitives — `tailor`, `seed` —
are canonical and always available. A project-local copy of either
is dead weight.

(The broader global-shadow rule from the old MVP is dropped here:
the architectural pivot to "minimal globals" means most primitives
*are* intended to be installed per-repo. This criterion now only
flags duplication of the two truly global skills.)

## 2. Would a scaffold-on-demand skill cover it?

**Reject if yes.** `/qa scaffold`, `/demo scaffold`, etc. generate
repo-specific content on invocation. Don't pre-bake their output.

- Reject: a tailored `/qa` that hardcodes this repo's test golden paths
- Allow: a `settings.local.json` permissions entry that lets `/qa
  scaffold` run without prompts

## 3. Is the set focused, or 41-auditor ceremony?

**Reject if the proposal sprawls** — near-duplicate primitives that
all overlap the same domain, or a kitchen-sink single skill.

- Reject: four near-duplicate Rust reviewers
  (`unsafe-`, `lifetime-`, `trait-bound-`, `generic-reviewer`)
- Allow: one focused `rust-unsafe-reviewer` if the repo has unusual
  `unsafe` patterns that justify it

## 4. Can you name the concrete repo characteristic it addresses?

**Reject if no.** For every picked primitive, the planner must be
able to say in one sentence what about THIS repo makes the primitive
earn its place. "This is a Next.js app" → `/qa` makes sense.
"This might be useful someday" → reject.

This replaces the old MVP's "can Phase 4 prove the artifact's
value?" criterion. No A/B here — just the planner's articulable
reasoning. If the planner can't name the characteristic, the
primitive is speculative inclusion.

## Stopping condition

Critic emits a list of blocking objections (possibly empty).
The pick proceeds iff empty. No round 2. No appeals. User can
re-run `/tailor` with different inputs or adjust the planner's
instructions.
