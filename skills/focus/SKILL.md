---
name: focus
description: |
  Configure the active set of Spellbook primitives for the current project.
  Reads .spellbook.yaml manifest, pulls skills and agents from GitHub,
  manages harness-specific setup (Claude Code, Codex, Pi).
  Use when: starting a session, setting up a project, "focus",
  "what skills do I need", "set up skills", "configure primitives",
  "init spellbook", "sync skills", "add skill", "remove skill".
argument-hint: "[init|sync|add|remove|search|list] [name]"
---

# /focus

Configure the active Spellbook primitives for this project. Nuke-and-rebuild
managed primitives on every run. Leave unmanaged primitives untouched.

## Constants

```
SPELLBOOK_REPO:    phrazzld/spellbook
SPELLBOOK_RAW:     https://raw.githubusercontent.com/phrazzld/spellbook/master
INDEX_URL:         ${SPELLBOOK_RAW}/index.yaml
REGISTRY_URL:      ${SPELLBOOK_RAW}/registry.yaml
MANIFEST_FILE:     .spellbook.yaml
MARKER_FILE:       .spellbook
```

## Global Skills (Already Available)

These skills are installed globally by `bootstrap.sh` and are always available.
**Never suggest, fetch, or install these — they're already present.**

The canonical list lives in `registry.yaml` under `global.skills` (13 skills)
and `global.agents` (4 agents). Do not hardcode this list — read the registry.

Focus manages **domain skills** — the project-specific knowledge primitives
that complement the always-available process layer.

## Routing

| Command | Action |
|---------|--------|
| `/focus` | Sync from manifest. If no manifest, run init. |
| `/focus init` | Analyze project from first principles, generate `.spellbook.yaml` |
| `/focus sync` | Force re-pull all managed primitives |
| `/focus add <name>` | Add skill, agent, or collection to manifest and sync |
| `/focus remove <name>` | Remove from manifest and delete locally |
| `/focus search <query>` | Search the Spellbook index |
| `/focus list` | Show manifest contents and install status |
| `/focus improve` | Synthesize observations into spellbook improvements |

If invoked with a task description (e.g., `/focus fix payment webhooks`),
run the smart selection flow: search index for task-relevant primitives,
suggest manifest changes, then sync.

## Invariant: Always Project-Local

Focus installs ONLY into the current project directory. Never into global
harness directories (~/.claude/, ~/.codex/, etc.). The only global primitives
are the bootstrap set (above).

If the user wants primitives available everywhere, they navigate to their
global config directory and run focus there. Focus does not decide scope —
the working directory decides scope.

## Core Flow

### 1. Resolve Harness Targets

All supported harnesses are always targeted. Focus installs to every
harness directory, creating them if they don't exist. No detection,
no if/elif — always both.

```
HARNESS_TARGETS:
  claude-code:
    skills: .claude/skills/
    agents: .claude/agents/
    agent_format: markdown
    reference: references/harnesses/claude-code.md
  codex:
    skills: .agents/skills/
    agents: .codex/agents/
    agent_format: toml
    reference: references/harnesses/codex.md
```

Load **all** harness references. Every sync produces primitives usable
by every supported harness.

### 2. Read or Create Manifest

If `.spellbook.yaml` exists at project root, read it. Proceed to step 3.

If not, **STOP. You MUST run the full init flow.** Load `references/init.md`
and follow it exactly. The init flow is 8 phases — do not shortcut it.

**Critical init invariants (inlined because skipping these is the #1 failure mode):**

1. **Analyze the project BEFORE searching the catalog.** Read code, deps,
   services, recent git activity. Understand what the project IS.
2. **Generate a wishlist from first principles.** What domain knowledge would
   make an agent most effective here? Think from the project's needs, not
   from what the catalog has.
3. **Search AFTER thinking.** Match wishlist items against the catalog.
4. **Identify gaps — the most valuable output.** Wishlist items with no
   catalog match are skill gaps. These represent knowledge NOT in the model's
   training data: process, domain-specific best practices, integration gotchas,
   failure modes. Actively push to create new skills for every gap. This is
   how spellbook grows — and these gap-born skills are the highest-leverage
   ones because they encode what the model can't already do.
5. **Present the full picture:** analysis, wishlist, matches, AND gaps.
   Lead with gaps as opportunities, not afterthoughts. Get explicit
   confirmation before writing the manifest.

### 3. Resolve Skill References

Each skill is either unqualified or fully qualified:

```
debug                                    → source: phrazzld/spellbook
anthropics/skills@frontend-design        → source: anthropics/skills
vercel-labs/agent-skills@vercel-react-best-practices → source: vercel-labs/agent-skills
```

Unqualified names resolve to `phrazzld/spellbook`. External skills use
`owner/repo@skill-name` format to avoid name collisions.

**Critical filter:** If a resolved skill name matches any global skill
(see table above), skip it silently. Global skills are never project-installed.

### 4. Nuke Managed Primitives

For **each harness target**, scan its skills and agents directories for
`.spellbook` markers and delete managed primitives:

```bash
for target in HARNESS_TARGETS; do
  find "${target.skills}" -maxdepth 2 -name ".spellbook" | while read marker; do
    rm -rf "$(dirname "$marker")"
  done
  find "${target.agents}" -maxdepth 1 -name "*.spellbook" 2>/dev/null | while read marker; do
    rm -f "${marker}" "${marker%.spellbook}.md" "${marker%.spellbook}.toml"
  done
done
```

**Critical**: Only directories/files with a `.spellbook` marker are touched.
Everything else is invisible to focus and will not be modified or deleted.

### 5. Install Primitives

Two-phase install — download once, distribute to all targets. See `references/sync.md`.

1. **Download phase**: Fetch each skill from GitHub once (into a temp staging area).
2. **Distribute phase**: Copy staged content to each harness target's skills dir.
   Skill content (SKILL.md, references/, scripts/, assets/) is format-identical
   across harnesses — no translation needed.

### 5b. Install Agents

Download each agent source file once, then install per-target:
- **markdown targets** (Claude Code): copy the `.md` as-is
- **toml targets** (Codex): translate markdown+YAML frontmatter to TOML format
  (see `references/harnesses/codex.md` for translation rules)

### 6. Harness-Specific Setup

After installing primitives, run harness-specific configuration for **each target**.
See `references/harnesses/claude-code.md` and `references/harnesses/codex.md`.

- **DMI handling**: For Claude Code, preserve `disable-model-invocation: true`
  in frontmatter. For Codex, emit `agents/openai.yaml` with
  `allow_implicit_invocation: false` in the skill directory.

### 7. Report

```markdown
## Focus Complete

**Manifest**: .spellbook.yaml (5 domain skills, 2 agents)
**Global layer**: 13 skills + 4 agents (via bootstrap, not shown)

### Installed (domain)
| Type | Name | Claude Code | Codex |
|------|------|-------------|-------|
| skill | stripe | .claude/skills/stripe/ | .agents/skills/stripe/ |
| skill | next-patterns | .claude/skills/next-patterns/ | .agents/skills/next-patterns/ |
| agent | stripe-auditor | .claude/agents/stripe-auditor.md | .codex/agents/stripe-auditor.toml |

### Unchanged (not managed by Spellbook)
- my-custom-deploy-skill/

### Errors
(none)
```

## Managed vs Unmanaged

**Spellbook-managed**: Any directory containing a `.spellbook` marker file.
Focus will delete and recreate these on every sync.

**Unmanaged**: Any directory WITHOUT a `.spellbook` marker file.
Focus will never read, modify, or delete these.

## .spellbook.yaml Manifest Format

```yaml
# .spellbook.yaml — checked into git, harness-agnostic
# Only domain/workflow skills go here. Process skills are global.
skills:
  - stripe
  - next-patterns
  - anthropics/skills@frontend-design
agents:
  - stripe-auditor
```

## Smart Selection

When invoked with a task description:

1. Run `python3 ${CLAUDE_SKILL_DIR}/scripts/search.py "<task description>" --top 15 --json`
2. **Filter out global skills** — never suggest what's already available
3. Check which remaining primitives are already in the manifest
4. Suggest additions (with reasoning and similarity scores)
5. Ask user to confirm before modifying manifest
6. Sync

## Anti-Patterns

- **Never install to global directories.** ~/.claude/, ~/.codex/ are off-limits.
- **Never suggest global skills.** They're already available. Don't waste the
  user's time recommending what they already have.
- Never touch directories without `.spellbook` markers
- Never install primitives not declared in the manifest
- Never skip the nuke step — stale state causes subtle bugs
- Never hardcode paths — always derive from the harness targets table
- **Never bulk-add a collection without filtering.** Every expanded skill must
  pass the "useful in THIS repo" test.
- **Never skip agent syncing.** Agents are first-class primitives.
- **Never skip init phases.** Jumping straight to catalog search without
  first-principles project analysis produces shallow, technology-matched
  results instead of need-matched results. The wishlist phase exists to
  surface gaps the catalog doesn't cover yet.
