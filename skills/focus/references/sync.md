# Focus Sync

Nuke all Spellbook-managed primitives and rebuild from the manifest.

## Process

### 1. Read Manifest

Parse `.spellbook.yaml` from project root. If missing, error and suggest
running `/focus init`.

### 2. Resolve Skill References

Each skill in the manifest is either:
- **Unqualified** (`debug`) — resolves to `phrazzld/spellbook`
- **Fully qualified** (`anthropics/skills@frontend-design`) — uses the named source

Parse FQNs:
```
owner/repo@skill-name  →  source="owner/repo", name="skill-name"
skill-name             →  source="phrazzld/spellbook", name="skill-name"
```

### 3. Nuke Managed Primitives

**Only remove directories/files with `.spellbook` marker files.**

```bash
# Skills
find "${SKILLS_DIR}" -maxdepth 2 -name ".spellbook" -type f | while read marker; do
  managed_dir="$(dirname "$marker")"
  rm -rf "$managed_dir"
done

# Agents
find "${AGENTS_DIR}" -maxdepth 1 -name "*.md" | while read agent_file; do
  # Check if the agent has a companion .spellbook marker
  marker="${agent_file%.md}.spellbook"
  [ -f "$marker" ] && rm -f "$agent_file" "$marker"
done
```

### 4. Install Skills

For each skill, download from its source:

```bash
source="phrazzld/spellbook"  # or "anthropics/skills", etc.
skill="debug"
target="${SKILLS_DIR}/${skill}"
raw="https://raw.githubusercontent.com/${source}/main"

# Determine the skill path within the source repo
# Default: skills/${skill}/SKILL.md
# Some repos use different layouts — check embeddings.json for hints
skill_path="skills/${skill}"

mkdir -p "$target"
curl -sfL "$raw/$skill_path/SKILL.md" -o "$target/SKILL.md"
```

**Download subdirectories** (references/, scripts/, assets/):
```bash
api="https://api.github.com/repos/${source}/contents/${skill_path}"

for subdir in references scripts assets; do
  files=$(curl -sf "$api/$subdir" 2>/dev/null | \
    python3 -c "import sys,json; [print(f['path']) for f in json.load(sys.stdin)]" 2>/dev/null) || continue
  mkdir -p "$target/$subdir"
  echo "$files" | while read path; do
    fname=$(basename "$path")
    curl -sfL "$raw/$path" -o "$target/$subdir/$fname"
  done
done
```

**Handle nested reference directories:**
```bash
dirs=$(curl -sf "$api/references" 2>/dev/null | \
  python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='dir']" 2>/dev/null) || true
for nested_dir in $dirs; do
  nested_files=$(curl -sf "$api/references/$nested_dir" 2>/dev/null | \
    python3 -c "import sys,json; [print(f['path']) for f in json.load(sys.stdin)]" 2>/dev/null) || continue
  mkdir -p "$target/references/$nested_dir"
  echo "$nested_files" | while read path; do
    fname=$(basename "$path")
    curl -sfL "$raw/$path" -o "$target/references/$nested_dir/$fname"
  done
done
```

### 5. Write Marker

For each installed primitive, write the source in the marker:
```bash
cat > "$target/.spellbook" << EOF
source: ${source}
name: ${skill}
installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
```

### 6. Install Agents

Agents from `phrazzld/spellbook` are single `.md` files:
```bash
agent="ousterhout"
curl -sfL "${raw}/agents/${agent}.md" -o "${AGENTS_DIR}/${agent}.md"
```

### 7. Rate Limiting

GitHub API: 60 req/hour unauthenticated, 5000 with token.
Use `gh api` if available (auto-authenticated) or `GITHUB_TOKEN`.

If rate-limited, fall back to shallow clone:
```bash
tmp=$(mktemp -d)
git clone --depth 1 "https://github.com/${source}.git" "$tmp"
cp -R "$tmp/skills/$skill/" "$target/"
rm -rf "$tmp"
```

### 8. Post-Install

Run harness-specific setup (see `references/harnesses/`).
Report installed/skipped/errored primitives.
