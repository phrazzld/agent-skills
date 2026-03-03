#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  generate-assets.sh <source-image> [--background "#RRGGBB"]

Purpose:
  Generate Expo-friendly icons and splash screens into ./assets/.

Requirements:
  - ImageMagick 7+ ("magick" command)

Notes:
  - Source should be high-res and roughly square for best results.
  - Script is idempotent; it overwrites generated files.
EOF
}

log() { printf '[mobile-migrate] %s\n' "$*"; }
die() { printf '[mobile-migrate] ERROR: %s\n' "$*" >&2; exit 1; }

[[ $# -ge 1 ]] || { usage; exit 1; }

SRC_IMAGE=""
BACKGROUND="#ffffff"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --background)
      [[ $# -ge 2 ]] || die "--background requires a value"
      BACKGROUND="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$SRC_IMAGE" ]]; then
        SRC_IMAGE="$1"
        shift
      else
        die "unexpected argument: $1"
      fi
      ;;
  esac
done

[[ -n "$SRC_IMAGE" ]] || die "missing source image path"
[[ -f "$SRC_IMAGE" ]] || die "source image not found: $SRC_IMAGE"

if command -v magick >/dev/null 2>&1; then
  MAGICK="magick"
else
  die "ImageMagick not found (expected 'magick' on PATH)"
fi

ASSETS_DIR="assets"
IOS_DIR="$ASSETS_DIR/ios"
ANDROID_DIR="$ASSETS_DIR/android"
SPLASH_DIR="$ASSETS_DIR/splash"

mkdir -p "$IOS_DIR/icons"
mkdir -p \
  "$ANDROID_DIR/mipmap-mdpi" \
  "$ANDROID_DIR/mipmap-hdpi" \
  "$ANDROID_DIR/mipmap-xhdpi" \
  "$ANDROID_DIR/mipmap-xxhdpi" \
  "$ANDROID_DIR/mipmap-xxxhdpi"
mkdir -p "$SPLASH_DIR"

resize_square() {
  local input="$1"
  local size="$2"
  local output="$3"
  "$MAGICK" "$input" \
    -resize "${size}x${size}^" \
    -gravity center \
    -background "$BACKGROUND" \
    -extent "${size}x${size}" \
    "$output"
}

resize_rect() {
  local input="$1"
  local width="$2"
  local height="$3"
  local output="$4"
  "$MAGICK" "$input" \
    -resize "${width}x${height}^" \
    -gravity center \
    -background "$BACKGROUND" \
    -extent "${width}x${height}" \
    "$output"
}

log "generating iOS icons"
IOS_SIZES=(20 29 40 58 60 76 80 87 120 152 167 180 1024)
for size in "${IOS_SIZES[@]}"; do
  out="$IOS_DIR/icons/icon-${size}.png"
  resize_square "$SRC_IMAGE" "$size" "$out"
done

log "generating Android icons"
android_icon() {
  local density="$1"
  local size="$2"
  local out="$ANDROID_DIR/mipmap-${density}/ic_launcher.png"
  resize_square "$SRC_IMAGE" "$size" "$out"
}

android_icon mdpi 48
android_icon hdpi 72
android_icon xhdpi 96
android_icon xxhdpi 144
android_icon xxxhdpi 192

log "generating splash screens"
SPLASH_DIMS=(
  1080x1920
  1125x2436
  1170x2532
  1242x2208
  1242x2688
  1284x2778
  1536x2048
  1668x2388
  2048x2732
  2208x1242
  2436x1125
  2532x1170
  2688x1242
  2732x2048
  2778x1284
)

for dim in "${SPLASH_DIMS[@]}"; do
  width="${dim%x*}"
  height="${dim#*x}"
  out="$SPLASH_DIR/splash-${dim}.png"
  resize_rect "$SRC_IMAGE" "$width" "$height" "$out"
done

log "done. generated assets under: $ASSETS_DIR"
