# Skill Menu

Show the user what's available.

## Process

### 1. Core Skills (always loaded)

List the 7 core skills with one-line descriptions:

| Skill | Mode | What it does |
|-------|------|-------------|
| `/debug` | auto | Investigate, audit, triage, fix |
| `/research` | auto | Web search, delegation, validation |
| `/forage` | auto | Find and load pack skills |
| `/autopilot` | user | Full delivery pipeline (plan → build → ship) |
| `/groom` | user | Backlog grooming and planning |
| `/moonshot` | user | Strategic divergent thinking |
| `/reflect` | user | Session retrospective and codification |

Auto = model can invoke proactively. User = invoked by user only.

### 2. Autopilot Sub-commands

Show the routing table from autopilot's SKILL.md:
`/build`, `/shape`, `/pr`, `/pr-fix`, `/pr-polish`, `/simplify`, `/commit`, `/issue`,
`/check-quality`, `/test-coverage`, `/verify-ac`, `/pr-walkthrough`

### 3. Pack Skills

Read `pack-index.md` and show the summary table + per-pack skill counts.
Offer: "Use `/forage <query>` to search for specific domain guidance."

### 4. Project-Local Skills

Scan `.claude/skills/*/SKILL.md` in the current project for any locally loaded skills.
