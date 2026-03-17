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
SPELLBOOK_RAW:     https://raw.githubusercontent.com/phrazzld/spellbook/main
EMBEDDINGS_URL:    ${SPELLBOOK_RAW}/embeddings.json
INDEX_URL:         ${SPELLBOOK_RAW}/index.yaml
MANIFEST_FILE:     .spellbook.yaml
MARKER_FILE:       .spellbook
```

## Routing

| Command | Action |
|---------|--------|
| `/focus` | Sync from manifest. If no manifest, run init. |
| `/focus init` | Analyze project, generate `.spellbook.yaml` |
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
harness directories (~/.claude/, ~/.codex/, etc.). The only global primitive
is focus itself (installed by bootstrap.sh).

If the user wants primitives available everywhere, they navigate to their
global config directory and run focus there. Focus does not decide scope —
the working directory decides scope.

## Core Flow

### 1. Detect Harness

Determine which agent harness is running:

```bash
# Check environment and filesystem signals
if [ -n "${CLAUDE_CODE:-}" ] || [ -d ".claude" ]; then HARNESS="claude-code"
elif [ -n "${CODEX:-}" ] || [ -d ".codex" ]; then HARNESS="codex"
elif [ -d ".agents" ]; then HARNESS="agents"
fi
```

Load harness-specific reference from `references/harnesses/${HARNESS}.md`.

**Harness directory mapping (all paths relative to project root):**

| Harness | Skills Dir | Agents Dir |
|---------|-----------|------------|
| Claude Code | `.claude/skills/` | `.claude/agents/` |
| Codex | `.agents/skills/` | `.codex/agents/` |
| Generic | `.agents/skills/` | `.agents/agents/` |

### 2. Read or Create Manifest

If `.spellbook.yaml` exists at project root, read it.

If not, run the init flow (see `references/init.md`):
1. **Deeply analyze the project**: read CLAUDE.md, package.json, go.mod, mix.exs,
   directory structure, README, recent git history. Understand what this project
   IS, what tech it uses, what domains it touches.
2. **Semantic search** against the embeddings index (144+ skills/agents across
   multiple sources). Use `scripts/search-embeddings.py --project-dir .`
3. For each candidate, ask: "Would this primitive provide value in THIS repo?"
   Reject any without a concrete use case.
4. Generate `.spellbook.yaml` with recommended primitives (skills AND agents)
5. Present to user with reasoning for each inclusion. Get confirmation before writing.

**Discernment over coverage.** 8 precisely-relevant primitives beats 25 with noise.

### 3. Resolve Skill References

Each skill is either unqualified or fully qualified:

```
debug                                    → source: phrazzld/spellbook
anthropics/skills@frontend-design        → source: anthropics/skills
vercel-labs/agent-skills@vercel-react-best-practices → source: vercel-labs/agent-skills
Leonxlnx/taste-skill@design-taste-frontend → source: Leonxlnx/taste-skill
```

Unqualified names resolve to `phrazzld/spellbook`. External skills use
`owner/repo@skill-name` format to avoid name collisions.

### 4. Nuke Managed Primitives

Scan the local harness skills and agents directories. Find ALL directories
containing a `.spellbook` marker file. Delete them entirely.

```bash
# Find and remove all Spellbook-managed directories
find "${SKILLS_DIR}" -name ".spellbook" -maxdepth 2 | while read marker; do
  rm -rf "$(dirname "$marker")"
done
find "${AGENTS_DIR}" -name ".spellbook" -maxdepth 2 2>/dev/null | while read marker; do
  rm -rf "$(dirname "$marker")"
done
```

**Critical**: Only directories with a `.spellbook` marker are touched.
Everything else is invisible to focus and will not be modified or deleted.

### 5. Install Primitives

For each resolved skill:

```bash
SKILL_NAME="debug"  # example
TARGET="${SKILLS_DIR}/${SKILL_NAME}"
mkdir -p "$TARGET"

# Download SKILL.md
curl -sfL "${SPELLBOOK_RAW}/skills/${SKILL_NAME}/SKILL.md" -o "$TARGET/SKILL.md"

# Download references/ if they exist
# Use GitHub API to list directory contents, then download each file
REFS=$(curl -sf "https://api.github.com/repos/${SPELLBOOK_REPO}/contents/skills/${SKILL_NAME}/references" | \
  python3 -c "import sys,json; [print(f['path']) for f in json.load(sys.stdin) if f['type']=='file']" 2>/dev/null) || true
if [ -n "$REFS" ]; then
  mkdir -p "$TARGET/references"
  echo "$REFS" | while read path; do
    name=$(basename "$path")
    curl -sfL "${SPELLBOOK_RAW}/${path}" -o "$TARGET/references/$name"
  done
fi

# Download scripts/ and assets/ similarly if they exist

# Write .spellbook marker
cat > "$TARGET/.spellbook" << EOF
source: ${SPELLBOOK_REPO}
name: ${SKILL_NAME}
installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
```

### 5b. Install Agents

Agents are markdown files (not directories). Install to the agents dir:

```bash
AGENT_NAME="ousterhout"  # example
curl -sfL "${SPELLBOOK_RAW}/agents/${AGENT_NAME}.md" -o "${AGENTS_DIR}/${AGENT_NAME}.md"
```

For Claude Code, agent files are used as-is (markdown + YAML frontmatter).
For Codex, translate to TOML format during install (see harness references).

### 6. Harness-Specific Setup

After installing primitives, run harness-specific configuration.
See `references/harnesses/claude-code.md` and `references/harnesses/codex.md`.

### 7. Report

```markdown
## Focus Complete

**Harness**: Claude Code
**Manifest**: .spellbook.yaml (12 skills, 1 collection, 0 agents)

### Installed
| Type | Name | Status |
|------|------|--------|
| skill | debug | installed |
| skill | autopilot | installed |
| collection/payments | stripe, bitcoin, lightning | installed |

### Unchanged (not managed by Spellbook)
- my-custom-deploy-skill/
- project-specific-lint/

### Errors
(none)
```

## Managed vs Unmanaged

**Spellbook-managed**: Any directory containing a `.spellbook` marker file.
Focus will delete and recreate these on every sync.

**Unmanaged**: Any directory WITHOUT a `.spellbook` marker file.
Focus will never read, modify, or delete these. They are the project's own
primitives, managed outside Spellbook.

The `.spellbook` marker contains:

```yaml
source: phrazzld/spellbook
name: debug
installed: 2026-03-16T15:30:00Z
```

## .spellbook.yaml Manifest Format

```yaml
# .spellbook.yaml — checked into git, harness-agnostic
skills:
  - debug
  - autopilot
  - groom
  - anthropics/skills@frontend-design
  - vercel-labs/agent-skills@vercel-react-best-practices
agents:
  - ousterhout
  - test-strategy-architect
```

Unqualified names = `phrazzld/spellbook`. Qualified names use FQN format.
No harness config — focus handles translation per-harness.

## Smart Selection

When invoked with a task description:

1. Embed the task description with Gemini Embedding 2
2. Cosine similarity against the full embeddings index (all sources)
3. Check which primitives are already in the manifest
4. Suggest additions (with reasoning and similarity scores)
5. Ask user to confirm before modifying manifest
6. Sync

## Anti-Patterns

- **Never install to global directories.** ~/.claude/, ~/.codex/ are off-limits.
  The working directory IS the scope. No exceptions. No "reasonable choice."
- Never touch directories without `.spellbook` markers
- Never install primitives not declared in the manifest
- Never skip the nuke step — stale state causes subtle bugs
- Never hardcode paths — always derive from harness detection
- **Never bulk-add a collection without filtering.** Every expanded skill must
  pass the "useful in THIS repo" test. If `agent-browser` is in the `agent`
  collection but the project has no web component, don't install it.
- **Never skip agent syncing.** Agents are first-class primitives. If the
  manifest declares agents, install them. If init is running, recommend
  relevant agents alongside skills.
