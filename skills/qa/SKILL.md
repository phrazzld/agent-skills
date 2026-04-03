---
name: qa
description: |
  Browser-based QA, exploratory testing, evidence capture, and bug reporting.
  Drive running applications and verify they work — not just that tests pass.
  Use when: "run QA", "test this", "verify the feature", "exploratory test",
  "check the app", "QA this PR", "capture evidence", "manual testing".
  Trigger: /qa.
argument-hint: "[url|route|feature]"
---

# /qa — Project-Local Skill Required

QA effectiveness depends on project-specific context: routes, personas, dev
commands, evidence strategy. This global fallback exists only to redirect you.

## Execution Stance

You are the executive orchestrator.
- Keep test scope, severity classification, and final pass/fail call on the lead model.
- Delegate route execution and evidence capture to focused subagents.
- Use independent verification when the same agent captured the evidence.

## If this project has no scaffolded QA skill

Run `/harness scaffold qa` to generate one. The scaffold investigates the
codebase (routes, framework, auth, browser tools), designs with you, and
writes a project-local `.claude/skills/qa/SKILL.md` tailored to this app.

Once scaffolded, `/qa` will resolve to the project-local skill automatically.

## Quick one-off QA (no scaffold)

If you need to verify something right now without scaffolding:

1. Start the dev server
2. Navigate to affected routes
3. Verify: happy path, edge cases, console errors, network failures
4. Capture evidence to `/tmp/qa-{slug}/`
5. Classify findings: P0 (blocks ship), P1 (fix before merge), P2 (log)

For browser tool selection, read `skills/harness/references/browser-tools.md`.
For evidence capture patterns, read `skills/harness/references/evidence-capture.md`.

## Gotchas

- **"Tests pass" is not QA.** Tests verify code paths. QA verifies user experience.
- **This fallback is intentionally thin.** Generic QA instructions can't encode
  your app's routes, personas, or failure modes. Scaffold for real coverage.
- **Autopilot expects a scaffolded skill.** If `/autopilot` invokes `/qa` and
  hits this redirect, scaffold first: `/harness scaffold qa`.
