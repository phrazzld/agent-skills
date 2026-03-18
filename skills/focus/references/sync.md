# Focus Sync

Nuke all Spellbook-managed primitives and rebuild from the manifest.
Installs to **all** harness targets on every run.

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

**Filter globals:** Skip any skill whose resolved name matches a global skill
(listed in `registry.yaml` under `global.skills`). These are already installed
globally by bootstrap and must not be duplicated into project-local directories.

### 3. Nuke Managed Primitives

For **each harness target**, remove managed primitives:

```bash
for target in HARNESS_TARGETS; do
  # Skills
  find "${target.skills}" -maxdepth 2 -name ".spellbook" -type f | while read marker; do
    managed_dir="$(dirname "$marker")"
    rm -rf "$managed_dir"
  done

  # Agents
  find "${target.agents}" -maxdepth 1 -name "*.spellbook" | while read marker; do
    rm -f "${marker}" "${marker%.spellbook}.md" "${marker%.spellbook}.toml"
  done
done
```

**Only directories/files with `.spellbook` markers are touched.**

### 4. Download Skills (Once Per Primitive)

Fetch each skill once into a staging area. Do NOT download per-harness —
skill content is format-identical across all targets.

```bash
source="phrazzld/spellbook"  # or "anthropics/skills", etc.
skill="debug"
staging="/tmp/spellbook-sync-$$/${skill}"
raw="https://raw.githubusercontent.com/${source}/main"

# Determine the skill path within the source repo
skill_path="skills/${skill}"

mkdir -p "$staging"
curl -sfL "$raw/$skill_path/SKILL.md" -o "$staging/SKILL.md"
```

**Download subdirectories** (references/, scripts/, assets/):
```bash
api="https://api.github.com/repos/${source}/contents/${skill_path}"

for subdir in references scripts assets; do
  files=$(curl -sf "$api/$subdir" 2>/dev/null | \
    python3 -c "import sys,json; [print(f['path']) for f in json.load(sys.stdin)]" 2>/dev/null) || continue
  mkdir -p "$staging/$subdir"
  echo "$files" | while read path; do
    fname=$(basename "$path")
    curl -sfL "$raw/$path" -o "$staging/$subdir/$fname"
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
  mkdir -p "$staging/references/$nested_dir"
  echo "$nested_files" | while read path; do
    fname=$(basename "$path")
    curl -sfL "$raw/$path" -o "$staging/references/$nested_dir/$fname"
  done
done
```

### 5. Distribute Skills to All Targets

Copy staged content to each harness target's skills directory:

```bash
for target in HARNESS_TARGETS; do
  dest="${target.skills}/${skill}"
  mkdir -p "$dest"
  cp -R "$staging/"* "$dest/"

  # Write marker
  cat > "$dest/.spellbook" << EOF
source: ${source}
name: ${skill}
installed: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
done
```

Create target directories if they don't exist. This is intentional —
the primitives are ready the moment the user starts any harness.

### 6. Install Agents

Download each agent source once, then distribute per-target with
format translation:

```bash
agent="ousterhout"
raw="https://raw.githubusercontent.com/${source}/main"
staging_agent="/tmp/spellbook-sync-$$/agents/${agent}.md"
curl -sfL "${raw}/agents/${agent}.md" -o "$staging_agent"

for target in HARNESS_TARGETS; do
  if [ "${target.agent_format}" = "markdown" ]; then
    cp "$staging_agent" "${target.agents}/${agent}.md"
    # Write companion marker
    echo "source: ${source}" > "${target.agents}/${agent}.spellbook"
  elif [ "${target.agent_format}" = "toml" ]; then
    # Translate markdown+YAML to TOML (see references/harnesses/codex.md)
    mkdir -p "${target.agents}"
    # Extract frontmatter fields → TOML keys
    # name → name, description → description, body → developer_instructions
    translate_agent_to_toml "$staging_agent" "${target.agents}/${agent}.toml"
    echo "source: ${source}" > "${target.agents}/${agent}.spellbook"
  fi
done
```

### 7. Rate Limiting

GitHub API: 60 req/hour unauthenticated, 5000 with token.
Use `gh api` if available (auto-authenticated) or `GITHUB_TOKEN`.

If rate-limited, fall back to shallow clone:
```bash
tmp=$(mktemp -d)
git clone --depth 1 "https://github.com/${source}.git" "$tmp"
# Copy to staging, then distribute to all targets as above
cp -R "$tmp/skills/$skill/" "$staging/"
rm -rf "$tmp"
```

### 8. Post-Install

Run harness-specific setup for each target (see `references/harnesses/`).
Report installed/skipped/errored primitives with per-harness status.
