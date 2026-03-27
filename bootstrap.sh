#!/usr/bin/env bash
set -euo pipefail

# Spellbook Bootstrap
#
# Two modes:
#   LOCAL:  Symlinks harness dirs to a local spellbook checkout (fast, editable)
#   REMOTE: Downloads from GitHub (works on any machine without a checkout)
#
# Local mode is preferred. Remote is the fallback for fresh machines.
#
# Run: curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/master/bootstrap.sh | bash

REPO="phrazzld/spellbook"
RAW="https://raw.githubusercontent.com/$REPO/master"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf '\033[0;34m%s\033[0m\n' "$*"; }
ok()    { printf '\033[0;32m%s\033[0m\n' "$*"; }
warn()  { printf '\033[0;33m%s\033[0m\n' "$*"; }
err()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }

is_spellbook_checkout() {
  local dir="$1"
  [ -d "$dir/skills" ] && [ -d "$dir/agents" ] && [ -d "$dir/harnesses" ]
}

resolve_spellbook_dir() {
  if [ -n "${SPELLBOOK_DIR:-}" ] && is_spellbook_checkout "$SPELLBOOK_DIR"; then
    printf '%s\n' "$SPELLBOOK_DIR"
    return 0
  fi

  if is_spellbook_checkout "$SCRIPT_DIR"; then
    printf '%s\n' "$SCRIPT_DIR"
    return 0
  fi

  local candidate
  for candidate in \
    "$HOME/Development/spellbook" \
    "$HOME/dev/spellbook" \
    "$HOME/src/spellbook" \
    "$HOME/code/spellbook"
  do
    if is_spellbook_checkout "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

cleanup_symlinks_under_prefix() {
  local dir="$1"
  local prefix="$2"
  shift 2
  local expected=("$@")

  mkdir -p "$dir"

  local entry base target
  for entry in "$dir"/*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    [ -L "$entry" ] || continue
    target="$(readlink "$entry" || true)"
    case "$target" in
      "$prefix"/*)
        base="$(basename "$entry")"
        if ! contains "$base" "${expected[@]}"; then
          rm -rf "$entry"
          ok "    removed stale $(basename "$dir")/$base"
        fi
        ;;
    esac
  done
}

remove_path_if_symlink_to_prefix() {
  local path="$1"
  local prefix="$2"
  local label="$3"

  [ -L "$path" ] || return 0

  local target
  target="$(readlink "$path" || true)"
  case "$target" in
    "$prefix"/*)
      rm -f "$path"
      ok "    removed stale $label"
      ;;
  esac
}

link_file_if_present() {
  local src="$1"
  local dest="$2"
  local label="$3"

  [ -e "$src" ] || return 0

  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  ok "    $label"
}

link_dir_entries_if_present() {
  local src_dir="$1"
  local dest_dir="$2"
  local label="$3"

  [ -d "$src_dir" ] || return 0

  local expected=()
  local src
  for src in "$src_dir"/*; do
    [ -e "$src" ] || continue
    expected+=("$(basename "$src")")
  done

  cleanup_symlinks_under_prefix "$dest_dir" "$src_dir" "${expected[@]}"

  mkdir -p "$dest_dir"
  for src in "$src_dir"/*; do
    [ -e "$src" ] || continue
    ln -sfn "$src" "$dest_dir/$(basename "$src")"
  done

  ok "    $label"
}

sanitize_claude_settings_json() {
  local settings_file="$1"
  [ -f "$settings_file" ] || return 0

  python3 - "$settings_file" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

settings_path = Path(sys.argv[1]).expanduser()
data = json.loads(settings_path.read_text())

hook_path_re = re.compile(r'~/.claude/hooks/[^ "\']+')
changed = False

hooks = data.get("hooks")
if isinstance(hooks, dict):
    cleaned = {}
    for event, groups in hooks.items():
        if not isinstance(groups, list):
            cleaned[event] = groups
            continue

        kept_groups = []
        for group in groups:
            if not isinstance(group, dict):
                kept_groups.append(group)
                continue

            entries = group.get("hooks")
            if not isinstance(entries, list):
                kept_groups.append(group)
                continue

            kept_entries = []
            for entry in entries:
                if not isinstance(entry, dict):
                    kept_entries.append(entry)
                    continue

                command = entry.get("command", "")
                match = hook_path_re.search(command)
                if match:
                    hook_file = Path(os.path.expanduser(match.group(0)))
                    if not hook_file.exists():
                        changed = True
                        continue
                kept_entries.append(entry)

            if kept_entries:
                if len(kept_entries) != len(entries):
                    changed = True
                group = dict(group)
                group["hooks"] = kept_entries
                kept_groups.append(group)
            else:
                changed = True

        cleaned[event] = kept_groups

    data["hooks"] = cleaned

if changed:
    settings_path.write_text(json.dumps(data, indent=2) + "\n")
PY
}

copy_claude_settings_if_present() {
  local src="$1"
  local dest="$2"

  [ -f "$src" ] || return 0

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  sanitize_claude_settings_json "$dest"
  ok "    settings.json (copied)"
}

verify_no_broken_spellbook_symlinks() {
  local dir="$1"
  local maxdepth="$2"
  local broken=0
  local link target

  while IFS= read -r link; do
    target="$(readlink "$link" || true)"
    case "$target" in
      "$SPELLBOOK"/*)
        if [ ! -e "$link" ]; then
          err "Broken symlink: $link -> $target"
          broken=1
        fi
        ;;
    esac
  done < <(find "$dir" -maxdepth "$maxdepth" -type l 2>/dev/null)

  return "$broken"
}

discover_local() {
  local skill agent
  GLOBAL_SKILLS=()
  GLOBAL_AGENTS=()

  for skill in "$SPELLBOOK"/skills/*/SKILL.md; do
    [ -f "$skill" ] || continue
    GLOBAL_SKILLS+=("$(basename "$(dirname "$skill")")")
  done

  for agent in "$SPELLBOOK"/agents/*.md; do
    [ -f "$agent" ] || continue
    GLOBAL_AGENTS+=("$(basename "$agent" .md)")
  done
}

discover_remote() {
  GLOBAL_SKILLS=()
  GLOBAL_AGENTS=()

  local names
  names=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills" | \
    python3 -c "import sys,json; [print(d['name']) for d in json.load(sys.stdin) if d['type']=='dir']" 2>/dev/null) \
    || { err "Failed to list remote skills"; exit 1; }
  while IFS= read -r name; do
    [ -n "$name" ] && GLOBAL_SKILLS+=("$name")
  done <<< "$names"

  names=$(curl -sf "https://api.github.com/repos/$REPO/contents/agents" | \
    python3 -c "import sys,json; [print(f['name'].removesuffix('.md')) for f in json.load(sys.stdin) if f['name'].endswith('.md')]" 2>/dev/null) \
    || { err "Failed to list remote agents"; exit 1; }
  while IFS= read -r name; do
    [ -n "$name" ] && GLOBAL_AGENTS+=("$name")
  done <<< "$names"
}

SPELLBOOK="$(resolve_spellbook_dir || true)"

if [ -n "$SPELLBOOK" ]; then
  discover_local
else
  discover_remote
fi

if [ ${#GLOBAL_SKILLS[@]} -eq 0 ]; then
  err "No skills found"
  exit 1
fi

if [ ${#GLOBAL_AGENTS[@]} -eq 0 ]; then
  err "No agents found"
  exit 1
fi

link_parent_dir() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      ok "    $label (already linked)"
      return 0
    fi
    # Stale symlink to different location — replace
    rm -f "$dest"
  elif [ -d "$dest" ]; then
    # Migrate from per-entry symlinks to parent symlink.
    # Remove spellbook-managed symlinks; warn about non-symlink entries.
    local has_non_symlink=0
    local entry target
    for entry in "$dest"/*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      if [ -L "$entry" ]; then
        target="$(readlink "$entry" || true)"
        case "$target" in
          "$src"/*|"$SPELLBOOK"/*) rm -f "$entry" ;;
          *) has_non_symlink=1 ;;
        esac
      else
        has_non_symlink=1
      fi
    done
    if [ "$has_non_symlink" -eq 1 ]; then
      warn "    $label: non-spellbook entries exist, keeping per-entry links"
      return 1
    fi
    rmdir "$dest" 2>/dev/null || { warn "    $label: dir not empty after cleanup"; return 1; }
  fi

  ln -sfn "$src" "$dest"
  ok "    $label → $src"
}

link_local() {
  local harness="$1"        # e.g. "claude"
  local harness_dir="$2"    # e.g. "$HOME/.claude"
  local skills_dir="$harness_dir/skills"
  local agents_dir="$harness_dir/agents"

  info "  Linking skills..."
  if ! link_parent_dir "$SPELLBOOK/skills" "$skills_dir" "skills/"; then
    # Fallback: per-skill symlinks (when non-spellbook entries exist)
    local skill src
    local skill_names=("${GLOBAL_SKILLS[@]}")
    cleanup_symlinks_under_prefix "$skills_dir" "$SPELLBOOK/skills" "${skill_names[@]}"
    for skill in "${skill_names[@]}"; do
      src="$SPELLBOOK/skills/$skill"
      [ -d "$src" ] || { warn "    missing local skill: $skill"; continue; }
      ln -sfn "$src" "$skills_dir/$skill"
      ok "    $skill"
    done
  fi

  info "  Linking agents..."
  if ! link_parent_dir "$SPELLBOOK/agents" "$agents_dir" "agents/"; then
    # Fallback: per-agent symlinks
    local agent src
    local agent_files=()
    for agent in "${GLOBAL_AGENTS[@]}"; do agent_files+=("$agent.md"); done
    cleanup_symlinks_under_prefix "$agents_dir" "$SPELLBOOK/agents" "${agent_files[@]}"
    for agent in "${GLOBAL_AGENTS[@]}"; do
      src="$SPELLBOOK/agents/$agent.md"
      [ -f "$src" ] || { warn "    missing local agent: $agent"; continue; }
      ln -sfn "$src" "$agents_dir/$agent.md"
      ok "    $agent"
    done
  fi

  # Link harness-specific configs if they exist
  local harness_config="$SPELLBOOK/harnesses/$harness"
  if [ -d "$harness_config" ]; then
    info "  Linking harness config..."
    case "$harness" in
      claude)
        link_file_if_present "$SPELLBOOK/harnesses/shared/AGENTS.md" "$harness_dir/CLAUDE.md" "CLAUDE.md (← shared AGENTS.md)"
        link_dir_entries_if_present "$harness_config/hooks" "$harness_dir/hooks" "hooks/"
        copy_claude_settings_if_present "$harness_config/settings.json" "$harness_dir/settings.json"
        remove_path_if_symlink_to_prefix "$harness_dir/.claude/settings.local.json" "$SPELLBOOK" ".claude/settings.local.json"
        ;;
      codex)
        cleanup_symlinks_under_prefix "$harness_dir/config" "$harness_config" "config.toml"
        link_file_if_present "$harness_config/config.toml" "$harness_dir/config/config.toml" "config.toml"
        link_file_if_present "$SPELLBOOK/harnesses/shared/AGENTS.md" "$harness_dir/AGENTS.md" "AGENTS.md (← shared)"
        ;;
      pi)
        link_file_if_present "$SPELLBOOK/harnesses/shared/AGENTS.md" "$harness_dir/agent/AGENTS.md" "AGENTS.md (← shared)"
        remove_path_if_symlink_to_prefix "$harness_dir/agent/APPEND_SYSTEM.md" "$SPELLBOOK" "agent/APPEND_SYSTEM.md"
        link_file_if_present "$harness_config/settings.json" "$harness_dir/settings.json" "settings.json"
        cleanup_symlinks_under_prefix "$harness_dir/prompts" "$SPELLBOOK"
        remove_path_if_symlink_to_prefix "$harness_dir/persona.md" "$SPELLBOOK" "persona.md"
        ;;
    esac
  fi

  verify_no_broken_spellbook_symlinks "$harness_dir" 4
}

# --- Remote mode: download from GitHub ---

download_skill() {
  local skills_dir="$1"
  local name="$2"
  local target="$skills_dir/$name"
  mkdir -p "$target/references"

  curl -sfL "$RAW/skills/$name/SKILL.md" -o "$target/SKILL.md" || { err "Failed: $name/SKILL.md"; return 1; }

  # Best-effort: download references via GitHub API
  local refs
  refs=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills/$name/references" 2>/dev/null | \
    python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='file']" 2>/dev/null) || true
  if [ -n "$refs" ]; then
    echo "$refs" | while read -r fname; do
      curl -sfL "$RAW/skills/$name/references/$fname" -o "$target/references/$fname" 2>/dev/null || true
    done
  fi

  ok "  $name → $target"
}

download_agent() {
  local agents_dir="$1"
  local name="$2"
  mkdir -p "$agents_dir"
  curl -sfL "$RAW/agents/$name.md" -o "$agents_dir/$name.md" || { err "Failed: agent $name"; return 1; }
  ok "  $name → $agents_dir/$name.md"
}

install_remote() {
  local skills_dir="$1"
  local agents_dir="$2"

  for skill in "${GLOBAL_SKILLS[@]}"; do
    download_skill "$skills_dir" "$skill"
  done

  info "  Installing agents..."
  for agent in "${GLOBAL_AGENTS[@]}"; do
    download_agent "$agents_dir" "$agent"
  done
}

# --- Orchestration ---

info "Spellbook Bootstrap"
if [ -n "$SPELLBOOK" ]; then
  info "Local checkout detected: $SPELLBOOK"
  info "Mode: symlink"
else
  info "No local checkout found."
  info "Mode: download from GitHub"
fi
echo

installed=0

for harness in claude codex pi; do
  harness_dir="$HOME/.$harness"

  # Detect harness
  if [ ! -d "$harness_dir" ] && ! command -v "$harness" &>/dev/null; then
    continue
  fi

  info "Detected: $harness"
  mkdir -p "$harness_dir"

  if [ -n "$SPELLBOOK" ]; then
    link_local "$harness" "$harness_dir"
  else
    agents_dir="$harness_dir/agents"
    install_remote "$harness_dir/skills" "$agents_dir"
  fi

  installed=$((installed + 1))
  echo
done

if [ "$installed" -eq 0 ]; then
  warn "No agent harnesses detected."
  warn "Installing to ~/.claude/ as default."
  mkdir -p "$HOME/.claude"
  if [ -n "$SPELLBOOK" ]; then
    link_local "claude" "$HOME/.claude"
  else
    install_remote "$HOME/.claude/skills" "$HOME/.claude/agents"
  fi
  installed=1
fi

ok "Done. Installed to $installed harness(es)."
echo
info "Skills (${#GLOBAL_SKILLS[@]}): ${GLOBAL_SKILLS[*]}"
info "Agents (${#GLOBAL_AGENTS[@]}): ${GLOBAL_AGENTS[*]}"
echo
if [ -n "$SPELLBOOK" ]; then
  info "Mode: symlink (edits in $SPELLBOOK propagate instantly)"
else
  info "Mode: downloaded from GitHub"
  info "For symlink mode, clone spellbook and re-run."
fi
