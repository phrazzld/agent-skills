#!/usr/bin/env bash
set -euo pipefail

# Generate index.yaml from all skills and agents in the Spellbook repo.
# Run from repo root: ./scripts/generate-index.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$REPO_ROOT/index.yaml"

echo "# Spellbook Index" > "$INDEX"
echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$INDEX"
echo "# Do not edit manually. Run: ./scripts/generate-index.sh" >> "$INDEX"
echo "" >> "$INDEX"

# Skills
echo "skills:" >> "$INDEX"
for skill_dir in "$REPO_ROOT"/skills/*/; do
  skill_md="$skill_dir/SKILL.md"
  [ -f "$skill_md" ] || continue

  name=$(basename "$skill_dir")

  # Extract description from frontmatter
  desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{found=1; sub(/^description: *\|? */, ""); if ($0 != "" && $0 != "|") print; next} found && /^  /{sub(/^  /,""); printf "%s ", $0; next} found && !/^  /{found=0}' "$skill_md" | head -1 | sed 's/ *$//' | cut -c1-200)

  # Fallback: single-line description
  if [ -z "$desc" ]; then
    desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: *"?/,""); sub(/"? *$/,""); print; exit}' "$skill_md")
  fi

  # Extract tags from description keywords
  tags=$(echo "$desc" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '\n' | \
    grep -v -E '^(the|and|for|use|when|with|this|that|from|into|your|each|are|not|all|can|has|will|been|have|does|its|any|our|you|was)$' | \
    sort -u | head -10 | tr '\n' ',' | sed 's/,$//')

  echo "  - name: $name" >> "$INDEX"
  echo "    description: \"$(echo "$desc" | sed 's/"/\\"/g')\"" >> "$INDEX"
  [ -n "$tags" ] && echo "    tags: [$tags]" >> "$INDEX"
done

echo "" >> "$INDEX"

# Agents
echo "agents:" >> "$INDEX"
agent_count=0
for agent_dir in "$REPO_ROOT"/agents/*/; do
  [ -d "$agent_dir" ] || continue
  name=$(basename "$agent_dir")
  echo "  - name: $name" >> "$INDEX"
  agent_count=$((agent_count + 1))
done
[ "$agent_count" -eq 0 ] && echo "  []" >> "$INDEX"

echo "" >> "$INDEX"

# Collections (just copy from collections.yaml reference)
echo "# Collections are defined in collections.yaml" >> "$INDEX"

skill_count=$(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
echo ""
echo "Generated index.yaml: $skill_count skills, $agent_count agents"
