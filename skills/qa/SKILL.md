---
name: qa
description: "Browser-based QA, exploratory testing, evidence capture, and bug reporting for running applications. Starts dev servers, navigates affected routes, verifies happy paths and edge cases, captures screenshot/video evidence, and classifies findings by severity. Verifies user experience works — not just that tests pass. Use when: 'run QA', 'test this', 'verify the feature', 'exploratory test', 'check the app', 'QA this PR', 'capture evidence', 'manual testing'. Trigger: /qa."
argument-hint: "[url|route|feature]"
---

# /qa — Project-Local Skill Required

QA effectiveness depends on project-specific context: routes, personas, dev
commands, evidence strategy. This global fallback exists only to redirect you.

## If this project has no scaffolded QA skill

Run `/harness scaffold qa` to generate one. The scaffold investigates the
codebase (routes, framework, auth, browser tools), designs with you, and
writes a project-local `.claude/skills/qa/SKILL.md` tailored to this app.

Once scaffolded, `/qa` will resolve to the project-local skill automatically.

## Quick one-off QA (no scaffold)

If you need to verify something right now without scaffolding:

1. Start the dev server (e.g., `npm run dev`, `cargo run`, `python manage.py runserver`)
2. Confirm the server responds: `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000`
   - If no response: check logs, try alternate port, verify deps installed. Don't proceed until 200.
3. Navigate to affected routes via browser tools
4. Verify: happy path, edge cases, console errors, network failures
5. Capture evidence to `/tmp/qa-{slug}/`:
   - Screenshots: `mcp browser screenshot /tmp/qa-{slug}/step-N.png`
   - Console errors: copy from browser devtools
   - Network failures: note status codes and payloads
6. Classify findings: P0 (blocks ship), P1 (fix before merge), P2 (log)

For browser tool selection, read `skills/harness/references/browser-tools.md`.
For evidence capture patterns, read `skills/harness/references/evidence-capture.md`.

## Gotchas

- **"Tests pass" is not QA.** Tests verify code paths. QA verifies user experience.
- **This fallback is intentionally thin.** Generic QA instructions can't encode your app's routes, personas, or failure modes. Scaffold for real coverage.
- **Autopilot expects a scaffolded skill.** If `/autopilot` invokes `/qa` and hits this redirect, scaffold first: `/harness scaffold qa`.
