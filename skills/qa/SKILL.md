---
name: qa
description: |
  Browser-based QA, exploratory testing, evidence capture, and bug reporting.
  Drive running applications and verify they work — not just that tests pass.
  Use when: "run QA", "test this", "verify the feature", "exploratory test",
  "check the app", "QA this PR", "capture evidence", "manual testing",
  "scaffold qa", "generate qa skill".
  Trigger: /qa.
argument-hint: "[url|route|feature|scaffold]"
---

# /qa

QA effectiveness depends on project-specific context. This skill either runs
QA (if a project-local skill exists) or scaffolds one.

## Routing

| Intent | Action |
|--------|--------|
| "scaffold qa", "generate qa skill" | Read `references/scaffold.md` and follow it |
| Run QA (project-local skill exists) | Defer to project-local `.claude/skills/qa/SKILL.md` |
| Quick one-off QA (no scaffold) | Use the quick protocol below |

If first argument is "scaffold" → read `references/scaffold.md`.

## Quick One-Off QA (no scaffold)

If you need to verify something right now without scaffolding:

1. Start the dev server
2. Navigate to affected routes
3. Verify: happy path, edge cases, console errors, network failures
4. Capture evidence to `/tmp/qa-{slug}/`
5. Classify findings: P0 (blocks ship), P1 (fix before merge), P2 (log)

For browser tool selection, read `references/browser-tools.md`.
For evidence capture patterns, read `references/evidence-capture.md`.

## Gotchas

- **"Tests pass" is not QA.** Tests verify code paths. QA verifies user experience.
- **This fallback is intentionally thin.** Generic QA instructions can't encode
  your app's routes, personas, or failure modes. Scaffold for real coverage.
- **Autopilot expects a scaffolded skill.** If `/autopilot` invokes `/qa` and
  hits this redirect, scaffold first: `/qa scaffold`.
