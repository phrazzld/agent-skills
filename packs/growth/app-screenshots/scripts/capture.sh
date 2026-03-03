#!/usr/bin/env bash
set -euo pipefail

log() { printf '[app-screenshots] %s\n' "$*"; }

usage() {
  cat <<'USAGE'
Usage:
  capture.sh <ios|android> [locales_csv] [devices_csv]

Examples:
  capture.sh ios en-US,es-ES "iPhone 15 Pro Max,iPhone 15 Pro"
  capture.sh android en-US "Pixel 8 Pro"
USAGE
}

require_fastlane() {
  command -v fastlane >/dev/null 2>&1 || {
    log "fastlane not found. Run: ./skills/app-screenshots/scripts/setup-fastlane.sh"
    exit 1
  }
}

run_ios_snapshot() {
  local locales_csv="$1"
  local devices_csv="$2"
  local args=()
  [[ -n "${locales_csv}" ]] && args+=("languages:${locales_csv}")
  [[ -n "${devices_csv}" ]] && args+=("devices:${devices_csv}")
  log "running: fastlane snapshot ${args[*]:-}"
  fastlane snapshot "${args[@]}"
}

run_android_screengrab() {
  local locales_csv="$1"
  local devices_csv="$2"
  local args=()
  [[ -n "${locales_csv}" ]] && args+=("languages:${locales_csv}")
  [[ -n "${devices_csv}" ]] && args+=("devices:${devices_csv}")
  log "running: fastlane screengrab ${args[*]:-}"
  fastlane screengrab "${args[@]}"
}

run_frameit() {
  local platform="$1"
  local path="$2"
  log "running: fastlane frameit ${platform} --path ${path}"
  fastlane frameit "${platform}" --path "${path}" --force
}

organize_ios() {
  local locales_csv="$1"
  local root="screenshots/ios"
  mkdir -p "${root}"
  if compgen -G "${root}/*.png" >/dev/null; then
    local default_locale="${locales_csv%%,*}"
    mkdir -p "${root}/${default_locale}"
    mv "${root}"/*.png "${root}/${default_locale}/"
  fi
  log "ios screenshots organized under ${root}/<locale>/<device>"
}

organize_android() {
  local root="screenshots/android"
  local meta_root="fastlane/metadata/android"
  mkdir -p "${root}"
  [[ -d "${meta_root}" ]] || {
    log "android metadata not found at ${meta_root}; skip organize"
    return
  }
  local locale_dir
  for locale_dir in "${meta_root}"/*; do
    [[ -d "${locale_dir}/images" ]] || continue
    local locale
    locale="$(basename "${locale_dir}")"
    local src
    for src in "${locale_dir}"/images/*Screenshots; do
      [[ -d "${src}" ]] || continue
      local bucket
      case "$(basename "${src}")" in
        phoneScreenshots) bucket="phone" ;;
        sevenInchScreenshots) bucket="tablet-7in" ;;
        tenInchScreenshots) bucket="tablet-10in" ;;
        *) bucket="$(basename "${src}")" ;;
      esac
      mkdir -p "${root}/${locale}/${bucket}"
      cp -f "${src}"/*.png "${root}/${locale}/${bucket}/" 2>/dev/null || true
    done
  done
  log "android screenshots organized under ${root}/<locale>/<bucket>"
}

main() {
  local platform="${1:-}"
  local locales_csv="${2:-en-US}"
  local devices_csv="${3:-}"
  [[ -n "${platform}" ]] || { usage; exit 1; }
  case "${platform}" in
    ios|android) ;;
    *) usage; exit 1 ;;
  esac

  require_fastlane
  if [[ "${platform}" == "ios" ]]; then
    run_ios_snapshot "${locales_csv}" "${devices_csv}"
    run_frameit ios "screenshots/ios"
    organize_ios "${locales_csv}"
    return
  fi

  run_android_screengrab "${locales_csv}" "${devices_csv}"
  run_frameit android "fastlane/metadata/android"
  organize_android
}

main "$@"

