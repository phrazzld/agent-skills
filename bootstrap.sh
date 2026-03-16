#!/usr/bin/env bash
set -euo pipefail

# Spellbook Bootstrap
# Installs the focus skill globally for each detected agent harness.
# Run: curl -sL https://raw.githubusercontent.com/phrazzld/spellbook/main/bootstrap.sh | bash

REPO="phrazzld/spellbook"
RAW="https://raw.githubusercontent.com/$REPO/main"
SKILL="focus"

info()  { printf '\033[0;34m%s\033[0m\n' "$*"; }
ok()    { printf '\033[0;32m%s\033[0m\n' "$*"; }
warn()  { printf '\033[0;33m%s\033[0m\n' "$*"; }
err()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }

install_skill() {
  local target="$1"
  local dir="$target/$SKILL"

  mkdir -p "$dir/references/harnesses"

  # Download focus skill files
  curl -sfL "$RAW/skills/$SKILL/SKILL.md" -o "$dir/SKILL.md" || { err "Failed to download SKILL.md"; return 1; }

  # Download harness references
  for ref in claude-code codex; do
    curl -sfL "$RAW/skills/$SKILL/references/harnesses/$ref.md" -o "$dir/references/harnesses/$ref.md" 2>/dev/null || true
  done

  # Download other references
  for ref in init sync search manifest; do
    curl -sfL "$RAW/skills/$SKILL/references/$ref.md" -o "$dir/references/$ref.md" 2>/dev/null || true
  done

  ok "  Installed $SKILL → $dir"
}

info "Spellbook Bootstrap"
info "Installing the focus skill globally..."
echo

installed=0

# Claude Code
if [ -d "$HOME/.claude" ] || command -v claude &>/dev/null; then
  info "Detected: Claude Code"
  install_skill "$HOME/.claude/skills"
  installed=$((installed + 1))
fi

# Codex
if [ -d "$HOME/.codex" ] || command -v codex &>/dev/null; then
  info "Detected: Codex"
  install_skill "$HOME/.codex/skills"
  installed=$((installed + 1))
fi

# Agents (generic .agents convention)
if [ -d "$HOME/.agents" ]; then
  info "Detected: .agents"
  install_skill "$HOME/.agents/skills"
  installed=$((installed + 1))
fi

# Pi
if [ -d "$HOME/.pi" ] || command -v pi &>/dev/null; then
  info "Detected: Pi"
  install_skill "$HOME/.pi/skills"
  installed=$((installed + 1))
fi

echo
if [ "$installed" -eq 0 ]; then
  warn "No agent harnesses detected."
  warn "Installing to ~/.claude/skills/ as default."
  install_skill "$HOME/.claude/skills"
  installed=1
fi

ok "Done. Installed focus skill to $installed harness(es)."
echo
info "Next steps:"
info "  1. Open any project"
info "  2. Run /focus to initialize"
info "  3. Edit .spellbook.yaml to customize"
