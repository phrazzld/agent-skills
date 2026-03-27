#!/usr/bin/env bash
set -euo pipefail

# Spellbook Bootstrap
#
# Preferred mode: if this script is run from a Spellbook checkout, manage
# global harness dirs directly from that checkout via symlinks.
#
# Fallback mode: download global primitives from GitHub for machines that do
# not yet have a local checkout.
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
  [ -d "$dir/skills" ] && [ -d "$dir/agents" ] && [ -f "$dir/registry.yaml" ]
}

resolve_spellbook_dir() {
  if [ -n "${SPELLBOOK_DIR:-}" ] && is_spellbook_checkout "${SPELLBOOK_DIR}"; then
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
          rm -f "$entry"
          ok "    removed stale $(basename "$dir")/$base"
        fi
        ;;
    esac
  done
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

install_globals_local() {
  local harness="$1"
  local root_dir="$2"
  local skills_dir="$3"
  local agents_dir="$4"

  local skill_names=("${CUSTOM_INSTALL[@]}" "${GLOBAL_SKILLS[@]}")
  local expected_agents=()
  local skill agent src

  for agent in "${GLOBAL_AGENTS[@]}"; do
    expected_agents+=("$agent.md")
  done

  info "  Linking skills..."
  cleanup_symlinks_under_prefix "$skills_dir" "$SPELLBOOK/skills" "${skill_names[@]}"
  mkdir -p "$skills_dir"
  for skill in "${skill_names[@]}"; do
    src="$SPELLBOOK/skills/$skill"
    if [ ! -d "$src" ]; then
      warn "    missing local skill: $skill"
      continue
    fi
    ln -sfn "$src" "$skills_dir/$skill"
    ok "    $skill"
  done

  info "  Linking agents..."
  cleanup_symlinks_under_prefix "$agents_dir" "$SPELLBOOK/agents" "${expected_agents[@]}"
  mkdir -p "$agents_dir"
  for agent in "${GLOBAL_AGENTS[@]}"; do
    src="$SPELLBOOK/agents/$agent.md"
    if [ ! -f "$src" ]; then
      warn "    missing local agent: $agent"
      continue
    fi
    ln -sfn "$src" "$agents_dir/$agent.md"
    ok "    $agent"
  done

  case "$harness" in
    claude)
      info "  Linking harness config..."
      cleanup_symlinks_under_prefix "$root_dir/hooks" "$SPELLBOOK/harnesses/claude/hooks"
      link_file_if_present "$SPELLBOOK/CLAUDE.md" "$root_dir/CLAUDE.md" "CLAUDE.md"
      link_file_if_present "$SPELLBOOK/.claude/settings.local.json" "$root_dir/.claude/settings.local.json" ".claude/settings.local.json"
      sanitize_claude_settings_json "$root_dir/settings.json"
      ;;
    codex)
      info "  Linking harness config..."
      cleanup_symlinks_under_prefix "$root_dir/config" "$SPELLBOOK/harnesses/codex"
      link_file_if_present "$SPELLBOOK/AGENTS.md" "$root_dir/AGENTS.md" "AGENTS.md"
      ;;
    pi)
      info "  Linking harness config..."
      cleanup_symlinks_under_prefix "$root_dir/agent" "$SPELLBOOK/harnesses/pi/context/global"
      link_file_if_present "$SPELLBOOK/.pi/settings.json" "$root_dir/settings.json" "settings.json"
      link_file_if_present "$SPELLBOOK/.pi/persona.md" "$root_dir/persona.md" "persona.md"
      link_dir_entries_if_present "$SPELLBOOK/.pi/prompts" "$root_dir/prompts" "prompts/"
      link_dir_entries_if_present "$SPELLBOOK/.pi/agents" "$agents_dir" "pi agents/"
      ;;
    agents)
      info "  Linking harness config..."
      link_file_if_present "$SPELLBOOK/AGENTS.md" "$root_dir/AGENTS.md" "AGENTS.md"
      ;;
  esac

  verify_no_broken_spellbook_symlinks "$root_dir" 3
}

# --- Remote mode installers ---

install_focus() {
  local target="$1/focus"
  mkdir -p "$target/references/harnesses" "$target/scripts"

  curl -sfL "$RAW/skills/focus/SKILL.md" -o "$target/SKILL.md" || { err "Failed to download focus/SKILL.md"; return 1; }

  local ref
  for ref in claude-code codex; do
    curl -sfL "$RAW/skills/focus/references/harnesses/$ref.md" -o "$target/references/harnesses/$ref.md" 2>/dev/null || true
  done
  for ref in init sync search improve; do
    curl -sfL "$RAW/skills/focus/references/$ref.md" -o "$target/references/$ref.md" 2>/dev/null || true
  done

  curl -sfL "$RAW/skills/focus/scripts/search.py" -o "$target/scripts/search.py" 2>/dev/null || true

  ok "  focus → $target"
}

install_research() {
  local target="$1/research"
  mkdir -p "$target/references"

  curl -sfL "$RAW/skills/research/SKILL.md" -o "$target/SKILL.md" || { err "Failed to download research/SKILL.md"; return 1; }

  local ref
  for ref in web-search delegate thinktank introspect readwise exa-tools xai-search; do
    curl -sfL "$RAW/skills/research/references/$ref.md" -o "$target/references/$ref.md" 2>/dev/null || true
  done

  ok "  research → $target"
}

install_simple_skill() {
  local skills_dir="$1"
  local name="$2"
  local target="$skills_dir/$name"
  mkdir -p "$target/references"

  curl -sfL "$RAW/skills/$name/SKILL.md" -o "$target/SKILL.md" || { err "Failed to download $name/SKILL.md"; return 1; }

  local refs nested dname nfiles subdirs sdname sdfiles fname nfname sdfname

  refs=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills/$name/references" 2>/dev/null | \
    python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='file']" 2>/dev/null) || true
  if [ -n "$refs" ]; then
    while IFS= read -r fname; do
      [ -n "$fname" ] || continue
      curl -sfL "$RAW/skills/$name/references/$fname" -o "$target/references/$fname" 2>/dev/null || true
    done <<< "$refs"
  fi

  nested=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills/$name/references" 2>/dev/null | \
    python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='dir']" 2>/dev/null) || true
  if [ -n "$nested" ]; then
    while IFS= read -r dname; do
      [ -n "$dname" ] || continue
      mkdir -p "$target/references/$dname"
      nfiles=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills/$name/references/$dname" 2>/dev/null | \
        python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='file']" 2>/dev/null) || true
      if [ -n "$nfiles" ]; then
        while IFS= read -r nfname; do
          [ -n "$nfname" ] || continue
          curl -sfL "$RAW/skills/$name/references/$dname/$nfname" -o "$target/references/$dname/$nfname" 2>/dev/null || true
        done <<< "$nfiles"
      fi

      subdirs=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills/$name/references/$dname" 2>/dev/null | \
        python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='dir']" 2>/dev/null) || true
      if [ -n "$subdirs" ]; then
        while IFS= read -r sdname; do
          [ -n "$sdname" ] || continue
          mkdir -p "$target/references/$dname/$sdname"
          sdfiles=$(curl -sf "https://api.github.com/repos/$REPO/contents/skills/$name/references/$dname/$sdname" 2>/dev/null | \
            python3 -c "import sys,json; [print(f['name']) for f in json.load(sys.stdin) if f['type']=='file']" 2>/dev/null) || true
          if [ -n "$sdfiles" ]; then
            while IFS= read -r sdfname; do
              [ -n "$sdfname" ] || continue
              curl -sfL "$RAW/skills/$name/references/$dname/$sdname/$sdfname" -o "$target/references/$dname/$sdname/$sdfname" 2>/dev/null || true
            done <<< "$sdfiles"
          fi
        done <<< "$subdirs"
      fi
    done <<< "$nested"
  fi

  ok "  $name → $target"
}

install_agent() {
  local agents_dir="$1"
  local name="$2"
  mkdir -p "$agents_dir"

  curl -sfL "$RAW/agents/$name.md" -o "$agents_dir/$name.md" || { err "Failed to download agent $name"; return 1; }

  ok "  $name → $agents_dir/$name.md"
}

install_globals_remote() {
  local skills_dir="$1"
  local agents_dir="$2"
  local custom skill agent

  for custom in "${CUSTOM_INSTALL[@]}"; do
    case "$custom" in
      focus)    install_focus "$skills_dir" ;;
      research) install_research "$skills_dir" ;;
      *)        install_simple_skill "$skills_dir" "$custom" ;;
    esac
  done

  for skill in "${GLOBAL_SKILLS[@]}"; do
    install_simple_skill "$skills_dir" "$skill"
  done

  info "  Installing agents..."
  for agent in "${GLOBAL_AGENTS[@]}"; do
    install_agent "$agents_dir" "$agent"
  done
}

harness_root_for() {
  case "$1" in
    claude) printf '%s\n' "$HOME/.claude" ;;
    codex)  printf '%s\n' "$HOME/.codex" ;;
    pi)     printf '%s\n' "$HOME/.pi" ;;
    agents) printf '%s\n' "$HOME/.agents" ;;
    *)      return 1 ;;
  esac
}

skills_dir_for() {
  case "$1" in
    claude|codex|pi|agents) printf '%s\n' "$(harness_root_for "$1")/skills" ;;
    *) return 1 ;;
  esac
}

agents_dir_for() {
  case "$1" in
    claude|codex|pi|agents) printf '%s\n' "$(harness_root_for "$1")/agents" ;;
    *) return 1 ;;
  esac
}

harness_detected() {
  local harness="$1"
  local root
  root="$(harness_root_for "$harness")"

  case "$harness" in
    claude) [ -d "$root" ] || command -v claude >/dev/null 2>&1 ;;
    codex)  [ -d "$root" ] || command -v codex >/dev/null 2>&1 ;;
    pi)     [ -d "$root" ] || command -v pi >/dev/null 2>&1 ;;
    agents) [ -d "$root" ] && [ ! -L "$root/skills" ] ;;
    *)      return 1 ;;
  esac
}

SPELLBOOK="$(resolve_spellbook_dir || true)"

if [ -n "$SPELLBOOK" ]; then
  REGISTRY_YAML="$(cat "$SPELLBOOK/registry.yaml")"
else
  REGISTRY_YAML="$(curl -sfL "$RAW/registry.yaml")" || { err "Failed to fetch registry.yaml"; exit 1; }
fi

PARSED="$(mktemp)"
trap 'rm -f "$PARSED"' EXIT

echo "$REGISTRY_YAML" | python3 -c "
import re, sys

lines = sys.stdin.read().split('\n')

def extract_items(lines, path):
    depth = 0
    target_indent = [None] * len(path)
    items = []
    capturing = False
    for line in lines:
        if not line.strip() or line.strip().startswith('#'):
            continue
        indent = len(line) - len(line.lstrip())
        stripped = line.strip()
        if depth < len(path):
            key = path[depth] + ':'
            if stripped.startswith(key):
                target_indent[depth] = indent
                depth += 1
                if depth == len(path):
                    capturing = True
                    rest = stripped[len(key):].strip()
                    if rest.startswith('[') and rest.endswith(']'):
                        items = [v.strip() for v in rest[1:-1].split(',')]
                        break
                continue
        elif capturing:
            if indent <= target_indent[-1]:
                break
            if stripped.startswith('- '):
                items.append(stripped[2:].strip())
    return items

custom = extract_items(lines, ['global', 'skills', 'custom_install'])
standard = extract_items(lines, ['global', 'skills', 'standard'])
agents = extract_items(lines, ['global', 'agents'])

safe = re.compile(r'^[a-z0-9-]+$')
for name in custom + standard + agents:
    if not safe.match(name):
        print(f'INVALID: {name}', file=sys.stderr)
        sys.exit(1)

print('CUSTOM_INSTALL=(' + ' '.join(custom) + ')')
print('GLOBAL_SKILLS=(' + ' '.join(standard) + ')')
print('GLOBAL_AGENTS=(' + ' '.join(agents) + ')')
" > "$PARSED" || { err "Failed to parse registry.yaml"; exit 1; }

source "$PARSED"

if [ ${#GLOBAL_SKILLS[@]} -eq 0 ] && [ ${#CUSTOM_INSTALL[@]} -eq 0 ]; then
  err "No global skills found in registry.yaml"; exit 1
fi
if [ ${#GLOBAL_AGENTS[@]} -eq 0 ]; then
  err "No global agents found in registry.yaml"; exit 1
fi

info "Spellbook Bootstrap"
if [ -n "$SPELLBOOK" ]; then
  info "Mode: local symlink"
  info "Source: $SPELLBOOK"
else
  info "Mode: GitHub download"
  info "Source: $RAW"
fi
echo

installed=0
for harness in claude codex agents pi; do
  if ! harness_detected "$harness"; then
    continue
  fi

  info "Detected: $harness"
  root_dir="$(harness_root_for "$harness")"
  mkdir -p "$root_dir"

  if [ -n "$SPELLBOOK" ]; then
    install_globals_local "$harness" "$root_dir" "$(skills_dir_for "$harness")" "$(agents_dir_for "$harness")"
  else
    install_globals_remote "$(skills_dir_for "$harness")" "$(agents_dir_for "$harness")"
  fi

  installed=$((installed + 1))
  echo
done

if [ "$installed" -eq 0 ]; then
  warn "No supported harnesses detected."
  warn "Installing to ~/.claude/ as default."
  mkdir -p "$HOME/.claude"
  if [ -n "$SPELLBOOK" ]; then
    install_globals_local "claude" "$HOME/.claude" "$HOME/.claude/skills" "$HOME/.claude/agents"
  else
    install_globals_remote "$HOME/.claude/skills" "$HOME/.claude/agents"
  fi
  installed=1
fi

if [ -d "$HOME/.gemini" ] && [ -z "${SPELLBOOK_GEMINI_MANAGED:-}" ] && [ ! -d "$SPELLBOOK/.gemini" ] 2>/dev/null; then
  warn "Gemini detected, but this checkout does not define repo-managed Gemini config yet."
fi

ALL_SKILLS=("${CUSTOM_INSTALL[@]}" "${GLOBAL_SKILLS[@]}")
ok "Done. Installed to $installed harness(es)."
echo
info "Global skills (${#ALL_SKILLS[@]}): ${ALL_SKILLS[*]}"
info "Global agents (${#GLOBAL_AGENTS[@]}): ${GLOBAL_AGENTS[*]}"
