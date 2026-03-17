# Session Patterns

Structure agent work sessions for reliability and continuity.

## Single-Feature-Per-Session

Unbounded sessions produce drift, context overload, and half-finished work.
Scope each session to one deliverable.

**Before starting:**
- Define "done" in concrete terms (test passes, PR created, file updated)
- Estimate scope: if >30 tool calls likely needed, decompose further
- Identify dependencies that might block

**During session:**
- Stay in scope. New discoveries -> note for future session, don't pivot
- Checkpoint progress to files (not just conversation memory)
- If blocked for >3 attempts on same issue, escalate or pivot

## Session Initialization Protocol

Standard startup sequence for coding agents:

```
1. pwd                              # Where am I?
2. git status / git log --oneline -5  # What's the repo state?
3. Read CLAUDE.md / AGENTS.md       # What are the rules?
4. Read progress file (if exists)   # Am I continuing prior work?
5. Verify feature registry          # What's assigned to me?
```

**Why formalize this?** Agents that skip initialization make wrong
assumptions. A 10-second startup ritual prevents 10-minute debugging.

## Handoff Artifacts

When a session ends (by completion, context limit, or interruption),
write handoff notes for the next session:

```markdown
## Session Handoff -- [feature/branch name]

### Completed
- [x] Created schema migration (db/migrations/003_add_roles.sql)
- [x] Updated user model (src/models/user.ts)

### In Progress
- [ ] Role permission middleware -- partially implemented, see src/middleware/roles.ts

### Blocked
- API spec for admin endpoints not finalized (asked in #backend-design)

### Next Steps
1. Complete permission middleware (src/middleware/roles.ts:45 has TODO)
2. Write tests for role-based access
3. Create PR
```

**Where to write:** `/tmp/session-handoff-<branch>.md` or a progress
file at a repo-ignored path. Never write session artifacts to tracked
files (merge conflict bait).

## Worktree-Per-Task Pattern (TinyAGI)

For parallel agent work, each agent gets its own git worktree:

```bash
# Create isolated worktree for agent
git worktree add /tmp/worktree-feature-auth feature/auth

# Agent works in /tmp/worktree-feature-auth
# Full repo copy, independent changes

# When done, merge back
git worktree remove /tmp/worktree-feature-auth
```

**Benefits:**
- No merge conflicts between parallel agents
- Each agent has a clean working directory
- Failed agent work can be discarded without affecting main
- Git handles the merge when work is complete

**Merge strategy:** Dedicated merger agent reviews and resolves conflicts.
Don't auto-merge -- the merger needs to understand intent.

## Checkpoint-Based Delegation (Devin Pattern)

Structure complex tasks as a series of checkpoints:

```
Plan -> Implement chunk -> Test -> Fix -> Review -> Next chunk
  ^         ^              ^      ^       ^         ^
  CP1       CP2            CP3    CP4     CP5       CP6
```

**At each checkpoint:**
1. Assess progress against plan
2. Decide: continue, adjust plan, or cut losses
3. Write checkpoint artifact (state, findings, decisions)
4. If stuck for >2 attempts: escalate or skip to next chunk

**Cut losses early:** If a subtask is failing after 2-3 attempts with
different strategies, skip it, note it as blocked, and move to the next
chunk. Don't let one stuck subtask block the entire session.

## Initializer Agents

A lightweight agent that runs before the main work agent to set up context:

```
Initializer -> reads repo -> writes context summary -> Main agent starts with summary
```

**What the initializer produces:**
- Repo structure overview (key directories, tech stack)
- Relevant recent changes (git log filtered to relevant paths)
- Known blockers or WIP from previous sessions
- Applicable conventions from CLAUDE.md

**Why separate?** The initializer's context is discarded after producing
the summary, keeping the main agent's context clean and focused.
