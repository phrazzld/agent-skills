---
name: code-review
description: "Parallel multi-agent code review. Launches 3-5 reviewer subagents (Ousterhout, Grug, Carmack, or repo-specific), synthesizes findings into a single verdict, auto-fixes blocking issues via builder agents, and loops until clean or escalates. Use when: 'review this', 'code review', 'is this ready to ship', 'check this code', 'review my changes', 'is this mergeable'. Trigger: /code-review, /review, /critique."
argument-hint: "[branch|diff|files]"
---

# /code-review

Parallel reviewer bench → synthesized verdict → auto-fix loop → ship or escalate.

## Step-by-Step Workflow

### 1. Scope the diff

```bash
git diff main...HEAD --stat
git diff main...HEAD
```

### 2. Launch reviewer bench (parallel)

Launch 3-5 subagents in a **single message** — all as **Explore type** (read-only):

| Reviewer | Lens | Example prompt snippet |
|----------|------|----------------------|
| Ousterhout | Depth, abstractions | "Review for unnecessary complexity, leaky abstractions, deep vs shallow modules" |
| Grug | Simplicity | "Review for over-engineering, premature abstraction, unnecessary indirection" |
| Carmack | Correctness, performance | "Review for bugs, edge cases, performance pitfalls, unsafe patterns" |
| (Ad-hoc) | Repo-specific | Tailor to the domain — e.g., security reviewer for auth changes |

Each reviewer returns:

```markdown
## [Name] Verdict: Ship | Conditional | Don't Ship
### Blocking Issues (if any)
- [file:line] — [issue] — [fix instruction]
### Non-Blocking Notes
- [observation]
```

### 3. Synthesize

Collect all verdicts. Deduplicate overlapping concerns. Rank by severity:
- **Blocking** (correctness, security, data loss) → gates shipping
- **Non-blocking** (style, naming, minor improvements) → logged, not gated

### 4. Fix blocking issues

For each blocking issue, spawn a **builder** sub-agent (general-purpose type) with the specific `file:line` and fix instruction. Builder fixes, runs tests.

### 5. Re-review (loop)

Return to step 2. **Max 3 iterations.** If blocking issues remain after 3 rounds, escalate to human with:
- List of unresolved blocking issues
- What was attempted
- Why the fix didn't hold

### 6. Live verification (conditional)

**Trigger:** diff touches user-facing files (`.tsx`, `.jsx`, `pages/`, `app/`, `routes/`, `api/`, `endpoints/`, component directories).

When triggered, at least one reviewer must exercise the affected routes/components. "Ship" verdict is **blocked** until live verification passes.

**Skip:** pure refactors, config-only, test-only, backend-only with no user-facing surface.

### 7. Simplification pass

If diff > 200 LOC net after review passes:
- Delete dead code, collapse unnecessary abstractions, simplify conditionals, remove compatibility shims with no users.

### 8. Score and record

Append one JSON line to `.groom/review-scores.ndjson` (create `.groom/` if needed):

```json
{"date":"2026-03-30","pr":42,"correctness":8,"depth":7,"simplicity":9,"craft":8,"verdict":"ship"}
```

- Scores (1-10) reflect bench consensus. `pr`: PR number or `null`. `verdict`: `"ship"`, `"conditional"`, `"dont-ship"`.
- Committed to git (not gitignored). `/groom` reads it for quality trends.

## Gotchas

- **Self-review leniency:** Reviewers must be separate sub-agents, not the builder evaluating itself.
- **Scope is the diff:** `git diff main...HEAD`, not the whole repo.
- **Skipping the bench:** Running only the critic misses structural issues. The philosophy agents add perspectives the critic doesn't cover.
- **Blocking vs style:** Correctness and security gate shipping. Style preferences don't.
- **Plausible-but-wrong patterns:** Watch for wrong algorithm complexity, stub implementations that pass tests but don't work, "specification-shaped" code with right names but wrong behavior, and missing invariant checks.
