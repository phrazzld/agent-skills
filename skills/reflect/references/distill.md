# DISTILL

Distill this repo's knowledge into a single, sharp `AGENTS.md`.

## Purpose

- Rewrite the current repository's `AGENTS.md` into the best possible onboarding + operating guide for this project.
- Output must let a new contributor start useful work in minutes, without asking questions.
- Scope is this repo only; global philosophy lives in global agent instructions.

## The Kill Test

Every line in AGENTS.md must survive three questions:

1. **Discoverable?** Would the agent figure this out from `ls`, `cat package.json`, or reading code? → DELETE
2. **Surprising?** Does this describe something counter-intuitive or unexpected? If not → DELETE
3. **Earned by pain?** Did this instruction come from something going wrong? → KEEP

**Start with nothing. Wait for the agent to do something wrong. Write THAT down.**

### What to kill

- File trees (agent can `ls`)
- "This project uses React with TypeScript" (agent can see tsconfig.json)
- Architecture descriptions that restate what code shows
- Technology stack versions (in package.json)
- Module lists (in imports)
- Development philosophy restating linter/type config
- Sprint plans, roadmaps, marketing copy, performance metrics
- Build system descriptions (in build config)
- Testing framework choice (in test config)

### What survives

- "Run `yarn test:unit` not `npm test`" — weird, not discoverable
- "Don't touch src/legacy/ — three enterprise clients depend on it" — earned by pain
- "The auth middleware is load-bearing, all of it, don't be a hero" — counter-intuitive
- "DATABASE_URL not POSTGRES_URL — Prisma's Rust engine reads it before Node" — painful gotcha
- "e2e tests can't run headless due to extension limitations" — surprising constraint
- "Delete compatibility shims in greenfield paths — they compound fast and mislead agents" — earned by pain

## Inputs

- Always read, if present:
  - Repo `AGENTS.md`.
  - Existing harness-specific instruction files (e.g. `CLAUDE.md`).
  - Root `README` and any high-signal docs in `docs/`.
  - Key config / entry files (e.g. `package.json`, `pyproject.toml`, `docker-compose.yml`, main entrypoints).

## Target Shape for `AGENTS.md`

```markdown
# AGENTS

## Purpose
- What this repo is and why it exists.

## Architecture Map
- Main domains / services and how they fit.
- Where to start reading code (file:line).

## Run & Test
- Commands to run app, tests, lint, typecheck.
- Required env, secrets, or services.

## Quality & Pitfalls
- Definition of done, PR expectations, review norms.
- Non-obvious invariants, footguns, "never do X".

## References
- Key docs / ADRs / diagrams (paths).
- External systems / dashboards / runbooks.
```

## The Delegation Pattern

**Use a second agent to draft AGENTS.md. You review and refine.**

Review the draft. Refine for accuracy and compression.

## Algorithm

1. **Gather**
   - Read inputs; understand what the repo does, how it runs, and how it fits into the wider system.
2. **Kill Test every line**
   - For each line, ask three questions:
     - **Discoverable?** Would the agent figure this out from `ls`, `cat package.json`, or reading code? → DELETE
     - **Surprising?** Does this describe something counter-intuitive? If behavior is what you'd expect → DELETE
     - **Earned by pain?** Did this come from something going wrong? → KEEP
   - Also classify:
     - General / global → belongs in global agent instructions, do not restate here.
     - Marketing copy / roadmaps / sprint plans → DROP (not instructions)
3. **Draft new `AGENTS.md`**
   - Fill the target shape above with tight, repo-specific bullets.
   - Prefer bullets over paragraphs; every line must earn its place.
   - Link to existing docs instead of duplicating them.
4. **Compress**
   - Apply the 3-2-1 test:
     - 3 key decisions or invariants newcomers must know.
     - 2 critical insights about architecture or workflow.
     - 1 clear starting point in the codebase.
   - Rewrite soft prose into sharp, actionable lines.
5. **Validate**
   - Run the checklist below.
   - Only propose the new `AGENTS.md` once all checks pass.

## Checklist (must pass)

- [ ] Readable in ≤3 minutes; roughly ≤80 lines.
- [ ] Every line fails the Kill Test (not discoverable from code/config/ls).
- [ ] Run commands included (only if non-obvious — skip if standard `pnpm dev/test/build`).
- [ ] Captures footguns, gotchas, and "don't touch X" warnings.
- [ ] No file trees (agent can `ls`).
- [ ] No technology stack listings (agent can read package.json).
- [ ] No architecture descriptions that restate what code shows.
- [ ] No marketing copy, roadmaps, or sprint plans.
- [ ] Links to deeper docs / ADRs instead of copying them.
- [ ] Does not restate global behavior or philosophy from global agent instructions.

## Compression Examples

**Kill** (discoverable): "The project uses Turborepo with pnpm workspaces, Next.js 15, React 19, Tailwind CSS, and TypeScript strict mode."
→ Agent can read `package.json` and `tsconfig.json`.

**Kill** (not surprising): "Content scripts inject into web pages. Background scripts handle lifecycle. Core modules have specific responsibilities."
→ This is what every browser extension does.

**Kill** (file tree):
```
├── apps/web/       # Next.js app
├── packages/common/ # Shared types
└── turbo.json      # Turborepo config
```
→ Agent can `ls`.

**Keep** (earned by pain): "DATABASE_URL not POSTGRES_URL — Prisma's Rust engine reads it before Node.js starts. Runtime env modifications are too late in serverless."

**Keep** (surprising): "e2e tests can't run headless due to browser extension limitations."

**Keep** (load-bearing): "Don't touch src/legacy/ — three enterprise clients depend on it, and there are no tests."

## Philosophy

- Maximum signal per word.
- Document what is not obvious from code or README.
- If you can't find 3 decisions, 2 insights, and 1 starting point, read more code before writing.

## Graduation Rules

AGENTS.md is a staging area for learnings. When sections grow, graduate them:

- **Patterns section > 10 lines** → extract to a skill
- **Rules section > 5 items** → extract to an agent
- **Workflow section > 3 steps** → extract to a command

Keep AGENTS.md lean. Knowledge graduates to executable artifacts.

## Codify Learnings

**Default codify, justify exceptions.** Every correction, feedback, or debugging insight represents a system gap. No cross-session memory exists — if you learned it, codify it now.

### Identify Learnings

Scan the session for:
- Errors encountered and how they were fixed
- PR feedback received
- Debugging insights ("the real problem was...")
- Workflow improvements discovered
- Patterns that should be enforced
- Repeated explanations that should become cold-memory docs
- Retrieval misses that exposed undocumented subsystems

### Codification Targets

Apply codification hierarchy (see `/reflect calibrate`) — highest reliability level wins:

```
Type system > Lint rule > Hook > Test > CI > Skill/reference > AGENTS.md > Memory
```

Lint rules are ideal for: import boundaries, naming conventions, deprecated API usage,
auth enforcement, architectural layering violations.

### Anti-Patterns

- "No patterns detected" — One occurrence is enough
- "First time seeing this" — No cross-session memory exists
- "Seems too minor" — Minor issues compound into major friction
- "Not sure where to put it" — Brainstorm, ask, don't skip
- "Already obvious" — If it wasn't codified, the system didn't know it

### Report Format

```
CODIFIED:
- [learning] → [file]: [summary of change]

NOT CODIFIED:
- [learning]: [justification - must be specific]
```
