#!/usr/bin/env bash
set -euo pipefail

log() { printf '[app-screenshots] %s\n' "$*"; }

ensure_fastlane() {
  if command -v fastlane >/dev/null 2>&1; then
    log "fastlane found: $(fastlane --version | head -n 1)"
    return
  fi
  log "fastlane missing; installing via RubyGems (user install if needed)"
  if gem install fastlane --no-document >/dev/null 2>&1; then
    log "installed fastlane via gem"
    return
  fi
  gem install --user-install fastlane --no-document
  log "installed fastlane with --user-install"
  log "if fastlane not on PATH: export PATH=\"$(ruby -e 'print Gem.user_dir')/bin:$PATH\""
}

write_snapfile() {
  local dir="fastlane"
  local snapfile="${dir}/Snapfile"
  mkdir -p "${dir}"
  if [[ -f "${snapfile}" ]]; then
    log "Snapfile exists: ${snapfile} (skip)"
    return
  fi
  cat >"${snapfile}" <<'SNAPFILE'
# Fastlane snapshot config. Tune devices, languages, routes.
devices([
  "iPhone 15 Pro Max",
  "iPhone 15 Pro",
])

languages([
  "en-US",
  "es-ES",
])

scheme("App")
output_directory("screenshots/ios")
clear_previous_screenshots(true)
skip_open_summary(true)
launch_arguments(["-uiTesting", "1"])

# Optional:
# derived_data_path("./fastlane/DerivedData")
# concurrent_simulators(true)
SNAPFILE
  log "created ${snapfile}"
}

write_framefile() {
  local dir="fastlane"
  local framefile="${dir}/Framefile"
  mkdir -p "${dir}"
  if [[ -f "${framefile}" ]]; then
    log "Framefile exists: ${framefile} (skip)"
    return
  fi
  cat >"${framefile}" <<'FRAMEFILE'
# Fastlane frameit config. Customize background, text, fonts.
default(
  keyword: "YOUR_APP_KEYWORD",
  title: { color: "#FFFFFF", size: 96, font: "SF Pro Display" },
  padding: 48,
)

# Example device-specific overrides:
# "iPhone 15 Pro Max": { padding: 64 }
FRAMEFILE
  log "created ${framefile}"
}

main() {
  ensure_fastlane
  write_snapfile
  write_framefile
  log "next steps:"
  log "1) Edit fastlane/Snapfile (scheme, devices, languages, routes)."
  log "2) Ensure simulators/emulators installed for chosen devices."
  log "3) Run: ./skills/app-screenshots/scripts/capture.sh ios en-US,es-ES"
}

main "$@"

