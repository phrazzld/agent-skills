#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CORE_DIR="$REPO_DIR/core"
PACKS_DIR="$REPO_DIR/packs"
OVERLAYS_DIR="$REPO_DIR/overlays"
# Audit references now live under debug (audit absorbed into debug umbrella)
AUDIT_CORE_REFS_DIR="$CORE_DIR/debug/references"
AUDIT_GENERATED_REFS_DIR="$CORE_DIR/debug/generated-references"
FORAGE_INDEX="$CORE_DIR/forage/references/pack-index.md"

usage() {
  echo "Usage: sync.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  claude | codex | factory | gemini | pi | all   Sync core skills"
  echo "  pack <name> <project-dir>                      Symlink pack into project"
  echo "  pack <name> --global                            Symlink pack globally"
  echo "  detect <project-dir>                            Auto-detect and load packs"
  echo "  index                                           Rebuild pack skill index"
  echo "  --prune <harness>                               Remove stale symlinks"
  echo ""
  echo "Options:"
  echo "  --dry-run    Preview without changes"
  echo ""
  echo "Overlays:"
  echo "  overlays/<harness>/<skill>/ files are merged on top of core/<skill>/ at sync time."
  echo "  Special file: SKILL.append.md appends harness-specific instructions to SKILL.md."
  exit 1
}

[[ $# -lt 1 ]] && usage

log() { echo "[sync] $*"; }
dry() { [[ "${DRY_RUN:-}" == "--dry-run" ]]; }

is_skipped_skill() {
  local skill_name="$1"
  shift
  local pat
  for pat in "${@+"$@"}"; do
    [[ "$skill_name" == "$pat" ]] && return 0
  done
  return 1
}

# Symlink a single skill dir into target dir.
link_skill() {
  local src="$1" target_dir="$2"
  local skill_name
  skill_name="$(basename "$src")"
  local dst="$target_dir/$skill_name"

  [[ ! -d "$src" ]] && return

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      return  # already correct
    fi
    if dry; then
      log "[dry] repoint $dst -> $src"
    else
      rm "$dst"
    fi
  elif [[ -d "$dst" ]]; then
    if dry; then
      log "[dry] replace dir $dst with symlink"
    else
      /usr/bin/trash "$dst" 2>/dev/null || rm -rf "$dst"
    fi
  fi

  if dry; then
    log "[dry] ln -s $src -> $dst"
  else
    ln -s "$src" "$dst"
  fi
}

link_reference() {
  local src="$1" target_dir="$2"
  local ref_name dst
  ref_name="$(basename "$src")"
  dst="$target_dir/$ref_name"

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      return
    fi
    if dry; then
      log "[dry] repoint $dst -> $src"
    else
      rm "$dst"
    fi
  elif [[ -e "$dst" ]]; then
    if dry; then
      log "[dry] replace generated ref $dst"
    else
      /usr/bin/trash "$dst" 2>/dev/null || rm -rf "$dst"
    fi
  fi

  if dry; then
    log "[dry] ln -s $src -> $dst"
  else
    ln -s "$src" "$dst"
  fi
}

prune_legacy_pack_audit_references() {
  [[ ! -d "$AUDIT_CORE_REFS_DIR" ]] && return

  local count=0
  local ref
  for ref in "$AUDIT_CORE_REFS_DIR"/*.md; do
    [[ ! -e "$ref" && ! -L "$ref" ]] && continue
    [[ ! -L "$ref" ]] && continue

    local target
    target="$(readlink "$ref")"
    [[ "$target" != "$PACKS_DIR/"* ]] && continue

    if dry; then
      log "[dry] remove legacy pack audit ref $ref"
    else
      rm "$ref"
    fi
    ((count+=1))
  done

  if [[ "$count" -gt 0 ]]; then
    log "Pruned $count legacy pack audit refs from $AUDIT_CORE_REFS_DIR"
  fi
  return 0
}

prune_generated_audit_references() {
  [[ ! -d "$AUDIT_GENERATED_REFS_DIR" ]] && return

  local count=0
  local ref
  for ref in "$AUDIT_GENERATED_REFS_DIR"/*.md; do
    [[ ! -e "$ref" && ! -L "$ref" ]] && continue
    [[ ! -L "$ref" ]] && continue

    local target
    target="$(readlink "$ref")"
    if [[ ! -f "$target" ]]; then
      if dry; then
        log "[dry] prune stale generated audit ref $ref"
      else
        rm "$ref"
      fi
      ((count+=1))
    fi
  done

  if [[ "$count" -gt 0 ]]; then
    log "Pruned $count stale generated audit refs from $AUDIT_GENERATED_REFS_DIR"
  fi
  return 0
}

sync_pack_audit_references() {
  local source_dir="$1"
  [[ ! -d "$source_dir" ]] && return

  prune_legacy_pack_audit_references
  if dry; then
    log "[dry] mkdir -p $AUDIT_GENERATED_REFS_DIR"
  else
    mkdir -p "$AUDIT_GENERATED_REFS_DIR"
  fi
  prune_generated_audit_references

  local count=0
  local ref_file
  for ref_file in "$source_dir"/*.md; do
    [[ ! -f "$ref_file" ]] && continue
    link_reference "$ref_file" "$AUDIT_GENERATED_REFS_DIR"
    ((count+=1))
  done

  log "Pack audit-references: $count refs synced to $AUDIT_GENERATED_REFS_DIR"
}

# Build a merged skill directory from base + harness overlay.
# base dir always copied first, overlay files then override.
# Special overlay file SKILL.append.md is appended to SKILL.md.
materialize_overlay_skill() {
  local base_src="$1" overlay_src="$2" target_dir="$3" harness_name="$4"
  local skill_name dst
  skill_name="$(basename "$base_src")"
  dst="$target_dir/$skill_name"

  if dry; then
    log "[dry] materialize overlay skill $skill_name for $(basename "$(dirname "$overlay_src")")"
    return
  fi

  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -d "$dst" ]]; then
    /usr/bin/trash "$dst" 2>/dev/null || rm -rf "$dst"
  fi

  mkdir -p "$dst"
  cp -a "$base_src"/. "$dst"/

  for overlay_item in "$overlay_src"/*; do
    [[ ! -e "$overlay_item" ]] && continue
    [[ "$(basename "$overlay_item")" == "SKILL.append.md" ]] && continue
    cp -a "$overlay_item" "$dst"/
  done

  if [[ -f "$overlay_src/SKILL.append.md" && -f "$dst/SKILL.md" ]]; then
    cat >> "$dst/SKILL.md" <<'EOF'

EOF
    cat "$overlay_src/SKILL.append.md" >> "$dst/SKILL.md"
  fi

  cat > "$dst/.sync-managed" <<EOF
managed_by=sync.sh
harness=$harness_name
type=overlay
EOF
}

# Remove symlinks pointing to deleted skills
prune_harness() {
  local target_dir="$1"
  local harness_name="$2"
  shift 2
  local -a skip_patterns=("$@")
  [[ ! -d "$target_dir" ]] && { log "SKIP: $target_dir does not exist"; return; }

  local symlink_count=0
  local managed_dir_count=0
  local entry
  for entry in "$target_dir"/*; do
    [[ ! -e "$entry" && ! -L "$entry" ]] && continue

    if [[ -L "$entry" ]]; then
      local target
      target="$(readlink "$entry")"
      if [[ ! -d "$target" ]]; then
        if dry; then
          log "[dry] prune stale symlink: $entry -> $target"
        else
          rm "$entry"
        fi
        ((symlink_count+=1))
      fi
      continue
    fi

    [[ ! -d "$entry" ]] && continue
    [[ ! -f "$entry/.sync-managed" ]] && continue

    local skill_name
    skill_name="$(basename "$entry")"
    local base_skill="$CORE_DIR/$skill_name"
    local overlay_skill="$OVERLAYS_DIR/$harness_name/$skill_name"
    local should_prune=false

    if [[ ! -d "$base_skill" ]]; then
      should_prune=true
    elif is_skipped_skill "$skill_name" "${skip_patterns[@]+"${skip_patterns[@]}"}"; then
      should_prune=true
    elif [[ ! -d "$overlay_skill" ]]; then
      # Overlay no longer exists; next sync will relink this skill to core.
      should_prune=true
    fi

    if $should_prune; then
      if dry; then
        log "[dry] prune stale managed dir: $entry"
      else
        /usr/bin/trash "$entry" 2>/dev/null || rm -rf "$entry"
      fi
      ((managed_dir_count+=1))
    fi
  done
  log "$target_dir: pruned $symlink_count stale symlinks, $managed_dir_count stale managed dirs"
}

# Sync all core skills into a target directory.
# $1 = target dir, $2 = harness name, $3... = skip patterns (optional)
sync_harness() {
  local target_dir="$1"
  local harness_name="$2"
  shift 2
  local -a skip_patterns=("$@")

  [[ ! -d "$target_dir" ]] && { log "SKIP: $target_dir does not exist"; return; }

  # Prune stale symlinks first
  prune_harness "$target_dir" "$harness_name" "${skip_patterns[@]+"${skip_patterns[@]}"}"

  local count=0
  for skill_dir in "$CORE_DIR"/*/; do
    local skill_name
    skill_name="$(basename "$skill_dir")"

    # Skip protected patterns
    local skip=false
    for pat in "${skip_patterns[@]+"${skip_patterns[@]}"}"; do
      [[ "$skill_name" == "$pat" ]] && skip=true
    done
    $skip && continue

    local base_skill="$CORE_DIR/$skill_name"
    local overlay_skill="$OVERLAYS_DIR/$harness_name/$skill_name"

    if [[ -d "$overlay_skill" ]]; then
      materialize_overlay_skill "$base_skill" "$overlay_skill" "$target_dir" "$harness_name"
    else
      link_skill "$base_skill" "$target_dir"
    fi
    ((count+=1))
  done

  log "$target_dir: $count skills synced"
}

# Sync specific skills only (for Pi shared skills)
sync_specific() {
  local target_dir="$1"
  local harness_name="$2"
  shift
  shift
  local -a skills=("$@")

  [[ ! -d "$target_dir" ]] && { log "SKIP: $target_dir does not exist"; return; }

  for skill_name in "${skills[@]}"; do
    local base_skill="$CORE_DIR/$skill_name"
    local overlay_skill="$OVERLAYS_DIR/$harness_name/$skill_name"
    if [[ -d "$overlay_skill" ]]; then
      materialize_overlay_skill "$base_skill" "$overlay_skill" "$target_dir" "$harness_name"
    else
      link_skill "$base_skill" "$target_dir"
    fi
  done

  log "$target_dir: ${#skills[@]} shared skills synced"
}

# Sync a pack into a project or globally
sync_pack() {
  local pack_name="$1"
  local target="$2"
  local pack_dir="$PACKS_DIR/$pack_name"

  [[ ! -d "$pack_dir" ]] && { log "ERROR: pack '$pack_name' not found in $PACKS_DIR"; exit 1; }

  local target_dir
  if [[ "$target" == "--global" ]]; then
    target_dir="$HOME/.claude/skills"
  else
    target_dir="$target/.claude/skills"
    mkdir -p "$target_dir"
  fi

  local count=0
  for skill_dir in "$pack_dir"/*/; do
    [[ ! -d "$skill_dir" ]] && continue
    local dir_name
    dir_name="$(basename "$skill_dir")"

    # Pack audit references are runtime-generated, not linked into tracked source.
    if [[ "$dir_name" == "audit-references" ]]; then
      sync_pack_audit_references "$skill_dir"
      continue
    fi

    link_skill "$skill_dir" "$target_dir"
    ((count+=1))
  done

  log "Pack '$pack_name': $count skills synced to $target_dir"
}

do_claude() {
  log "=== Claude ==="
  sync_harness "$HOME/.claude/skills" "claude"
}

do_codex() {
  log "=== Codex ==="
  sync_harness "$HOME/.codex/skills" "codex" ".system"
}

do_factory() {
  log "=== Factory ==="
  sync_harness "$HOME/.factory/skills" "factory"
}

do_gemini() {
  log "=== Gemini ==="
  sync_harness "$HOME/.gemini/skills" "gemini"

  # Also handle antigravity/global_skills symlinks
  local ag_dir="$HOME/.gemini/antigravity/global_skills"
  if [[ -d "$ag_dir" ]]; then
    for link in "$ag_dir"/*; do
      [[ ! -L "$link" ]] && continue
      local name
      name="$(basename "$link")"
      [[ -d "$CORE_DIR/$name" ]] && link_skill "$CORE_DIR/$name" "$ag_dir"
    done
    log "$ag_dir: antigravity symlinks repointed"
  fi
}

do_pi() {
  log "=== Pi ==="
  # Pi is managed by pi-agent-config. Only repoint shared symlinks.
  # Note: agent-browser, dogfood, skill-creator, design moved to packs.
  # Pi sync now links core skills only; pack skills loaded separately.
  local pi_skills="$HOME/Development/pi-agent-config/skills"
  [[ ! -d "$pi_skills" ]] && { log "SKIP: $pi_skills does not exist"; return; }
  log "$pi_skills: Pi sync deferred (shared skills moved to packs)"
}

# Extract tags from a skill description (keywords for forage matching)
extract_tags() {
  local desc="$1"
  echo "$desc" | tr '[:upper:]' '[:lower:]' | \
    grep -oE '[a-z][a-z0-9.+-]+' | \
    grep -vE '^(the|and|for|use|when|with|from|into|this|that|all|any|are|was|will|can|not|has|have|does|been|each|also|via|per)$' | \
    sort -u | head -15 | tr '\n' ', ' | sed 's/, $//'
}

# Pack-level summary descriptions
pack_summary() {
  case "$1" in
    web)      echo "Frontend frameworks, UI, visual QA, browser testing, visualization" ;;
    design)   echo "Design systems, aesthetics, tokens, brand, visual identity" ;;
    agent)    echo "AI/LLM agent infrastructure, context engineering, skill engineering" ;;
    infra)    echo "DevOps, sysadmin, security, CI/CD, observability, data, reporting" ;;
    quality)  echo "Code quality, naming, patterns, linting, git workflows" ;;
    payments) echo "Stripe, Bitcoin, Lightning Network payment integrations" ;;
    growth)   echo "SEO, ads, CRO, analytics, content, brand, marketing" ;;
    scaffold) echo "Project scaffolding, migration, monorepo setup" ;;
    finance)  echo "Personal finance tracking, reporting, crypto gains" ;;
    *)        echo "" ;;
  esac
}

# Generate pack skill index for /forage
do_index() {
  [[ ! -d "$CORE_DIR/forage/references" ]] && mkdir -p "$CORE_DIR/forage/references"

  if dry; then
    log "[dry] would regenerate $FORAGE_INDEX"
    return
  fi

  cat > "$FORAGE_INDEX" <<'HEADER'
# Pack Skill Index

Generated by sync.sh. Do not edit manually.

## Summary

| Pack | Focus |
|------|-------|
HEADER

  # Write summary table
  for pack_dir in "$PACKS_DIR"/*/; do
    [[ ! -d "$pack_dir" ]] && continue
    local pname
    pname=$(basename "$pack_dir")
    local summary
    summary=$(pack_summary "$pname")
    [[ -n "$summary" ]] && echo "| $pname | $summary |" >> "$FORAGE_INDEX"
  done

  # Write per-pack skill entries with tags
  for pack_dir in "$PACKS_DIR"/*/; do
    [[ ! -d "$pack_dir" ]] && continue
    local pack_name
    pack_name=$(basename "$pack_dir")
    echo "" >> "$FORAGE_INDEX"
    echo "## $pack_name" >> "$FORAGE_INDEX"

    for skill_dir in "$pack_dir"/*/; do
      [[ ! -f "$skill_dir/SKILL.md" ]] && continue
      local dir_name
      dir_name=$(basename "$skill_dir")
      [[ "$dir_name" == "audit-references" ]] && continue

      local desc
      desc=$(awk '/^description:/{found=1; sub(/^description: *\|?/,""); if(length>0) printf "%s ", $0; next} found && /^  /{gsub(/^  /,""); printf "%s ", $0; next} found{exit}' "$skill_dir/SKILL.md" | sed 's/ *$//; s/^"//; s/"$//')

      local tags
      tags=$(extract_tags "$desc")

      echo "- **$dir_name** | $desc | Tags: $tags" >> "$FORAGE_INDEX"
    done
  done
  log "Pack index built: $FORAGE_INDEX"
}

# Auto-detect and load packs based on project dependencies
do_detect() {
  local project_dir="${1:-.}"
  project_dir="$(cd "$project_dir" && pwd)"
  local manifest="$PACKS_DIR/.pack-manifest.json"

  [[ ! -f "$manifest" ]] && { log "ERROR: $manifest not found"; exit 1; }

  # Requires jq
  command -v jq >/dev/null 2>&1 || { log "ERROR: jq required for pack detection"; exit 1; }

  local packs
  packs=$(jq -r 'keys[]' "$manifest")
  local loaded=0

  for pack in $packs; do
    # Skip manual-only packs
    local is_manual
    is_manual=$(jq -r --arg p "$pack" '.[$p].manual // false' "$manifest")
    [[ "$is_manual" == "true" ]] && continue

    local detect_patterns
    detect_patterns=$(jq -r --arg p "$pack" '.[$p].detect[]' "$manifest" 2>/dev/null)
    [[ -z "$detect_patterns" ]] && continue

    local dep_files
    dep_files=$(jq -r --arg p "$pack" '.[$p].files[]' "$manifest" 2>/dev/null)

    local found=false
    for dep_file in $dep_files; do
      local full_path="$project_dir/$dep_file"
      [[ ! -f "$full_path" ]] && continue

      for pattern in $detect_patterns; do
        if grep -q "$pattern" "$full_path" 2>/dev/null; then
          found=true
          log "Detected '$pattern' in $dep_file → loading pack '$pack'"
          break 2
        fi
      done
    done

    if $found; then
      sync_pack "$pack" "$project_dir"
      ((loaded+=1))
    fi
  done

  # Load packs declared in .claude/packs
  local packs_file="$project_dir/.claude/packs"
  if [[ -f "$packs_file" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^#|^[[:space:]]*$ ]] && continue
      local pack_name="${line%% *}"
      log "Declared pack '$pack_name' in .claude/packs"
      sync_pack "$pack_name" "$project_dir"
      ((loaded+=1))
    done < "$packs_file"
  fi

  if [[ "$loaded" -eq 0 ]]; then
    log "No packs auto-detected for $project_dir"
  else
    log "Auto-detected and loaded $loaded pack(s)"
  fi
}

# Parse arguments
DRY_RUN=""
COMMAND="$1"
shift

# Check for --dry-run in remaining args
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN="--dry-run"
done

case "$COMMAND" in
  claude)  do_claude ;;
  codex)   do_codex ;;
  factory) do_factory ;;
  gemini)  do_gemini ;;
  pi)      do_pi ;;
  all)     do_claude; do_codex; do_factory; do_gemini; do_pi; do_index ;;
  pack)
    [[ $# -lt 2 ]] && { echo "Usage: sync.sh pack <name> <project-dir|--global>"; exit 1; }
    sync_pack "$1" "$2"
    do_index
    ;;
  index)
    do_index
    ;;
  detect)
    [[ $# -lt 1 ]] && { echo "Usage: sync.sh detect <project-dir>"; exit 1; }
    do_detect "$1"
    ;;
  --prune)
    HARNESS="${1:-all}"
    case "$HARNESS" in
      claude)  prune_harness "$HOME/.claude/skills" "claude" ;;
      codex)   prune_harness "$HOME/.codex/skills" "codex" ".system" ;;
      factory) prune_harness "$HOME/.factory/skills" "factory" ;;
      gemini)  prune_harness "$HOME/.gemini/skills" "gemini" ;;
      all)
        prune_harness "$HOME/.claude/skills" "claude"
        prune_harness "$HOME/.codex/skills" "codex" ".system"
        prune_harness "$HOME/.factory/skills" "factory"
        prune_harness "$HOME/.gemini/skills" "gemini"
        ;;
      *)       echo "Unknown harness: $HARNESS"; exit 1 ;;
    esac
    ;;
  *)       usage ;;
esac

log "Done."
