# Static path-glob bench map for `/code-review`

Priority: medium
Status: pending
Estimate: S

## Goal

Replace the hardcoded four-bench selection in `/code-review` (critic,
ousterhout, carmack, grug, beck — always the same four) with a static
path-glob map that selects 3-5 reviewers based on diff content. Deeper,
greppable, eval-able. Independently valuable without `/iterate`.

## Why Now

Split out of 028 during 2026-04-14 grooming. The bench-map refactor is
useful on its own — every `/code-review` run improves once specialized
reviewers fire on relevant diffs. Doesn't need `/iterate` to deliver value.

## Why Not a Classifier

A 1-shot LLM classifier that picks reviewers per diff is a single point of
failure with no eval harness and no fallback — if it omits `a11y-auditor`
on a `.tsx` diff or `securitron` on an auth diff, the loop silently ships
issues. Static globs are deterministic, reviewable, and testable.

Revisit a classifier only if real diffs demonstrate glob rules can't cover
the cases and the classifier has an eval harness against ground-truth labels.

## Design

**File:** `skills/code-review/references/bench-map.yaml`

```yaml
default: [critic, ousterhout, grug]
rules:
  - paths: ["**/*.tsx", "**/*.jsx"]
    add: [a11y-auditor]
  - paths: ["**/auth/**", "**/*auth*.{ts,py,rs,go}"]
    add: [critic, beck]   # de-dup: still runs 3-5 total
  - paths: ["migrations/**", "**/*.sql"]
    add: [beck]
  - paths: ["Dockerfile", "**/*Dockerfile*", "ci/**", ".github/workflows/**"]
    add: [carmack]
```

**Selection algorithm:**
1. Start with `default` (always 3 agents)
2. For each rule whose glob matches any changed file, union `add` agents
3. Cap at 5 total; if over, drop least-matched rules
4. Always include `critic`

**Where it plugs in:** `skills/code-review/references/internal-bench.md`
replaces its static agent list with a pre-review step that reads
`bench-map.yaml` + `git diff --name-only <base>...HEAD` and emits the
selected bench.

## Oracle

- [ ] `bench-map.yaml` exists with ≥4 rules covering web-UI, auth, data, infra
- [ ] `/code-review` on a PR touching `**/*.tsx` invokes `a11y-auditor` in the bench
- [ ] `/code-review` on a PR touching only `README.md` uses the default bench
- [ ] Bench size stays in [3, 5] for any diff
- [ ] Selection is deterministic for a given diff — two invocations produce the same bench
- [ ] `grep -r "critic, ousterhout, carmack, grug, beck" skills/code-review/` returns zero hardcoded matches after refactor

## Non-Goals

- LLM-based dynamic classifier
- Adding new reviewer agents (securitron, perfhawk, etc.) — separate decision
- User-customizable per-repo overrides (can come via `/tailor` later)

## Related

- Split out of 028 (`/iterate`) during grooming
- Unblocks: richer `/code-review` without waiting for `/iterate` MVP
