#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CORE_DIR="$REPO_DIR/core"
PACKS_DIR="$REPO_DIR/packs"

usage() {
  echo "Usage: sync.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  claude | codex | factory | gemini | pi | all   Sync core skills"
  echo "  pack <name> <project-dir>                      Symlink pack into project"
  echo "  pack <name> --global                            Symlink pack globally"
  echo "  --prune <harness>                               Remove stale symlinks"
  echo ""
  echo "Options:"
  echo "  --dry-run    Preview without changes"
  exit 1
}

[[ $# -lt 1 ]] && usage

log() { echo "[sync] $*"; }
dry() { [[ "${DRY_RUN:-}" == "--dry-run" ]]; }

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

# Remove symlinks pointing to deleted skills
prune_harness() {
  local target_dir="$1"
  [[ ! -d "$target_dir" ]] && { log "SKIP: $target_dir does not exist"; return; }

  local count=0
  for link in "$target_dir"/*; do
    [[ ! -L "$link" ]] && continue
    local target
    target="$(readlink "$link")"
    if [[ ! -d "$target" ]]; then
      if dry; then
        log "[dry] prune stale: $link -> $target"
      else
        rm "$link"
      fi
      ((count++))
    fi
  done
  log "$target_dir: pruned $count stale symlinks"
}

# Sync all core skills into a target directory.
# $1 = target dir, $2... = skip patterns (optional)
sync_harness() {
  local target_dir="$1"
  shift
  local -a skip_patterns=("$@")

  [[ ! -d "$target_dir" ]] && { log "SKIP: $target_dir does not exist"; return; }

  # Prune stale symlinks first
  prune_harness "$target_dir"

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

    link_skill "$CORE_DIR/$skill_name" "$target_dir"
    ((count++))
  done

  log "$target_dir: $count skills synced"
}

# Sync specific skills only (for Pi shared skills)
sync_specific() {
  local target_dir="$1"
  shift
  local -a skills=("$@")

  [[ ! -d "$target_dir" ]] && { log "SKIP: $target_dir does not exist"; return; }

  for skill_name in "${skills[@]}"; do
    link_skill "$CORE_DIR/$skill_name" "$target_dir"
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

    # Link audit-references into core/audit/references/ so orchestrators find them
    if [[ "$dir_name" == "audit-references" ]]; then
      local audit_refs_dir="$CORE_DIR/audit/references"
      [[ ! -d "$audit_refs_dir" ]] && continue
      for ref_file in "$skill_dir"*.md; do
        [[ ! -f "$ref_file" ]] && continue
        local ref_name
        ref_name="$(basename "$ref_file")"
        local ref_dst="$audit_refs_dir/$ref_name"
        if [[ -L "$ref_dst" ]]; then
          local current
          current="$(readlink "$ref_dst")"
          [[ "$current" == "$ref_file" ]] && continue
          if dry; then
            log "[dry] repoint $ref_dst -> $ref_file"
          else
            rm "$ref_dst"
          fi
        fi
        if dry; then
          log "[dry] ln -s $ref_file -> $ref_dst"
        else
          ln -s "$ref_file" "$ref_dst"
        fi
      done
      log "Pack '$pack_name': audit-references linked into $audit_refs_dir"
      continue
    fi

    link_skill "$skill_dir" "$target_dir"
    ((count++))
  done

  log "Pack '$pack_name': $count skills synced to $target_dir"
}

do_claude() {
  log "=== Claude ==="
  sync_harness "$HOME/.claude/skills"
}

do_codex() {
  log "=== Codex ==="
  sync_harness "$HOME/.codex/skills" ".system"
}

do_factory() {
  log "=== Factory ==="
  sync_harness "$HOME/.factory/skills"
}

do_gemini() {
  log "=== Gemini ==="
  sync_harness "$HOME/.gemini/skills"

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
  local pi_skills="$HOME/Development/pi-agent-config/skills"
  local -a shared_skills=(
    agent-browser dogfood skill-creator design
  )
  sync_specific "$pi_skills" "${shared_skills[@]}"
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
  all)     do_claude; do_codex; do_factory; do_gemini; do_pi ;;
  pack)
    [[ $# -lt 2 ]] && { echo "Usage: sync.sh pack <name> <project-dir|--global>"; exit 1; }
    sync_pack "$1" "$2"
    ;;
  --prune)
    HARNESS="${1:-all}"
    case "$HARNESS" in
      claude)  prune_harness "$HOME/.claude/skills" ;;
      codex)   prune_harness "$HOME/.codex/skills" ;;
      factory) prune_harness "$HOME/.factory/skills" ;;
      gemini)  prune_harness "$HOME/.gemini/skills" ;;
      all)
        prune_harness "$HOME/.claude/skills"
        prune_harness "$HOME/.codex/skills"
        prune_harness "$HOME/.factory/skills"
        prune_harness "$HOME/.gemini/skills"
        ;;
      *)       echo "Unknown harness: $HARNESS"; exit 1 ;;
    esac
    ;;
  *)       usage ;;
esac

log "Done."
