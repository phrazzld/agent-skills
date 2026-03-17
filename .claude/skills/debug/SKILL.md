---
name: debug
description: |
  Investigate, audit, triage, and fix. Systematic debugging, incident lifecycle,
  domain auditing, and issue logging. Four-phase protocol: root cause → pattern
  analysis → hypothesis test → fix.
  Use for: any bug, test failure, production incident, error spikes, audit,
  triage, postmortem, "investigate", "why is this broken", "debug this",
  "production down", "is production ok", "audit stripe", "log issues".
argument-hint: <symptoms or domain> e.g. "error in auth" or "audit stripe"
---

# /debug

Find root cause. Fix it. Prove it works.

## Routing

| Intent | Sub-capability |
|--------|---------------|
| Debug a bug, test failure, unexpected behavior | This file (below) |
| Incident lifecycle: triage, investigate, postmortem | `references/triage.md` |
| Domain audit: "audit stripe", "audit quality" | `references/audit.md` |
| Audit then fix highest priority issue | `references/fix.md` |
| Create GitHub issues from audit findings | `references/log-issues.md` |

If first argument matches a domain name (stripe, quality, etc.), route to `references/audit.md`.
If "triage", "incident", "postmortem", "production down" → `references/triage.md`.
If "fix" → `references/fix.md`. If "log issues" → `references/log-issues.md`.
Otherwise, this is a debugging session — continue below.

**The user's symptoms:** $ARGUMENTS

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## Rule #1: Config Before Code

External service issues are usually config, not code. Check in order:

1. **Env vars present?** `npx convex env list --prod | grep <SERVICE>` or `vercel env ls`
2. **Env vars valid?** No trailing whitespace, correct format
3. **Endpoints reachable?** `curl -I -X POST <webhook_url>`
4. **Then** examine code

## The Codex First-Draft Pattern

Codex investigates. You review and verify.

```bash
codex exec "DEBUG: $SYMPTOMS. Reproduce, isolate root cause, propose fix." \
  --output-last-message /tmp/codex-debug.md 2>/dev/null
```

## Multi-Hypothesis Mode (Agent Teams)

When >2 plausible root causes and single investigation would anchor on one:

1. Create agent team with 3-5 investigators
2. Each teammate gets one hypothesis to prove/disprove
3. Teammates challenge each other's findings
4. Lead synthesizes consensus root cause

Use when: ambiguous stack trace, multiple services, flaky failures.
Don't use when: obvious single cause, config issue, simple regression.

## Instrumented Reproduction Loop

When you can't reproduce the bug yourself (auth-gated, mobile, timing-dependent,
hardware-specific, user-flow-dependent):

```
INSTRUMENT → USER REPRODUCES → READ LOGS → REFINE → REPEAT
```

1. **Hypothesize** -- form 2-3 candidate root causes from symptoms
2. **Instrument** -- add targeted logging that discriminates between hypotheses.
   Write to a log file the user can share back:
   ```bash
   LOG_FILE="${HOME}/Desktop/debug-$(date +%s).log"
   ```
   Log at decision points: function entry/exit, branch taken, values at boundaries.
   Tag each log line with the hypothesis it tests: `[H1] auth token expired: ${token.exp}`
3. **Hand off** -- tell user: "Reproduce the bug, then say done." Give exact steps if known.
4. **Read & analyze** -- when user signals done, read the log file. For each hypothesis:
   - Supported? Design next experiment to narrow further.
   - Disproved? Eliminate, remove its instrumentation, add new hypothesis.
   - Insufficient data? Add more targeted logging at the next layer.
5. **Iterate** -- repeat until one hypothesis survives all evidence. Max 3 rounds —
   if still ambiguous after 3, escalate to Multi-Hypothesis Mode (agent teams).
6. **Clean up** -- remove all instrumentation before fixing. Instrumentation is diagnostic,
   not the fix.

Use when: flaky tests, user-reported bugs you can't trigger, environment-specific issues.
Don't use when: bug reproduces in your environment (just use Phase 1-4 directly).

## The Four Phases

### Phase 1: Root Cause Investigation

BEFORE attempting ANY fix:

1. **Read error messages carefully** -- full stack traces, line numbers, error codes
2. **Reproduce consistently** -- exact steps. If not reproducible, gather more data
3. **Check recent changes** -- `git diff`, `git log --oneline -10`, new deps, config
4. **Gather evidence in multi-component systems** -- log at each component boundary, run once, identify failing layer
5. **Trace data flow** -- where does the bad value originate? Trace backward to source

### Phase 2: Pattern Analysis

1. **Find working examples** -- similar working code in same codebase
2. **Compare completely** -- read reference implementations fully, don't skim
3. **Identify all differences** -- however small
4. **Understand dependencies** -- settings, config, environment, assumptions

### Phase 3: Hypothesis and Testing

Scientific method. One experiment at a time. No stacking.

1. **Form single hypothesis** -- "I think X causes Y because Z" (write it down explicitly)
2. **Design experiment** -- What will prove or disprove this? Justify: why this experiment,
   what will it tell us? Smallest possible change, one variable only.
3. **Run experiment** -- observe result
4. **Evaluate**:
   - **Disproved** → eliminate this cause, form NEW hypothesis. This step matters —
     ruling things out is progress, not failure.
   - **Supported** → design next experiment to increase confidence. Not proven until
     you can explain the full causal chain.
   - **Ambiguous** → experiment was too broad. Narrow scope and rerun.
5. **Repeat** until root cause is proven or confidence is high enough to act

Never skip justification. "Just try X" is a red flag — if you can't explain what
you'll learn from an experiment, you don't understand the problem yet.

### Phase 4: Implementation

1. **Write failing test first** -- reproduce the bug in a test before any fix
2. **Verify test fails for the right reason** -- not syntax/import errors
3. **Implement single fix** -- address root cause. ONE change at a time.
4. **Verify** -- test passes, no other tests broken, issue resolved.
5. **If 3+ fixes failed** -- STOP. Question the architecture. See `references/systematic-debugging.md`.

## Root Cause Discipline

For each hypothesis, categorize:
- **ROOT**: Fixing this removes the fundamental cause
- **SYMPTOM**: Fixing this masks an underlying issue

Post-fix question: "If we revert in 6 months, does the problem return?"

## Demand Observable Proof

Before declaring "fixed", show:
- Log entry proving the fix worked
- Metric that changed
- Database state confirming resolution

Mark as **UNVERIFIED** until observables confirm.

## Classification

| Type | Signals | Approach |
|------|---------|----------|
| Test failure | Assertion error | Read test, trace expectation |
| Runtime error | Exception, crash | Stack trace -> source -> state |
| Type error | TS complaint | Read error, check types |
| Build failure | Bundler error | Check deps, config |
| Behavior mismatch | "Does Y, should do X" | Trace code path |
| Performance | Slow, timeout | Add timing instrumentation |
| Production incident | Sentry, alerts | Create INCIDENT.md, timeline |

## Investigation Work Log (Production Issues)

For non-trivial production issues, create `INCIDENT-{timestamp}.md`:
- **Timeline**: What happened when (UTC)
- **Evidence**: Logs, metrics, configs checked
- **Hypotheses**: Ranked by likelihood
- **Actions**: What tried, what learned
- **Root cause**: When found
- **Fix**: What resolved it

## Bounded Shell Output (MANDATORY)

- Size first: `wc -l <file>` or `du -h`
- Read windows: `sed -n '1,120p'`; jump with `rg -n`
- Cap logs: `head -n 200`, `tail -n 200`
- Abort after 20s without signal; narrow scope, rerun

## Red Flags -- STOP and Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see"
- Multiple simultaneous changes
- Proposing solutions before tracing data flow
- "One more fix attempt" (when 2+ already tried)
- Each fix reveals new problem in different place

## Toolkit

- **Sentry MCP**: `get_issue_details` for full context, `analyze_issue_with_seer` for AI root cause,
  `get_trace_details` for distributed traces, `search_events` for raw event search,
  `get_profile` for performance profiling
- **Git**: bisect, blame, recent deploys
- **Observability**: vercel/convex logs, sentry-cli
- **Codex**: Delegate investigation
- **Gemini**: Web-grounded research, similar issues
- **Thinktank**: Multi-model hypothesis validation

## Output

- **Root cause**: What's actually wrong
- **Fix**: How it was resolved
- **Verification**: Observable proof it works

## References

- `references/systematic-debugging.md` — Full four-phase protocol with examples
- `references/investigation-protocol.md` — Production incident investigation
- `references/triage.md` — Incident lifecycle (triage through postmortem)
- `references/audit.md` — Domain auditing with dynamic checklist routing
- `references/fix.md` — Audit then fix highest priority issue
- `references/log-issues.md` — Create GitHub issues from findings
