---
name: sysadmin-ops
description: Investigate host stability incidents (memory/process pressure), triage likely culprits, and drive safe recovery + hardening for multi-workspace Pi operations.
---

# Sysadmin Ops Skill

Use when the user asks to investigate crashes, runaway memory, machine instability,
or to design autonomous reliability guardrails for Pi workflows.

## Primary goals

1. Stabilize the host quickly.
2. Preserve evidence for root-cause analysis.
3. Restore interrupted workflows with minimal context loss.
4. Prevent recurrence with layered guardrails.

## Incident triage workflow

1. **Confirm event window**
   - capture local timestamp range
   - list active/affected workspaces

2. **Collect host forensics (macOS)**
   - inspect `/Library/Logs/DiagnosticReports/JetsamEvent-*.ips`
   - summarize top process families by aggregate RSS and process count
   - extract evidence of process storms (count, age distribution, coalition hints)

3. **Collect Pi execution forensics**
   - parse `~/.pi/agent/sessions/**` for bash commands around event window
   - identify high-risk commands (tests/builds/nested CLI/orchestration)
   - detect unfinished commands and crash-correlated sessions

4. **Containment recommendations**
   - immediate limits (session count, concurrency, timeouts)
   - command-level guardrails for sharp edges
   - optional emergency stop procedure

5. **Recovery plan**
   - regenerate per-workspace handoff state
   - enumerate next-resume checklist per workspace

6. **Preventive hardening**
   - extension guardrails
   - slice policy changes
   - watchdog automation and alerts

## Key sharp edges to check

- nested non-interactive `pi` invocations inside agents
- unbounded test/build commands without explicit timeout
- test runners without worker caps
- team/pipeline recursion loops
- many simultaneous workspaces with heavy runners

## Output contract

```markdown
## Incident Summary

## Forensic Evidence
- host
- session timeline

## Likely Root Causes (ranked)

## Immediate Containment

## Recovery Plan

## Hardening Plan
- now
- next
- later
```
