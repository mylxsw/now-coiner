#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <source-image> [output-dir]" >&2
  echo "Example: $0 ~/Downloads/logo.png Sources/NowCoinerApp/Resources" >&2
  exit 1
fi

SOURCE_IMAGE="${1/#\~/$HOME}"
OUTPUT_DIR="${2:-Sources/NowCoinerApp/Resources}"

if [[ ! -f "$SOURCE_IMAGE" ]]; then
  echo "Source image not found: $SOURCE_IMAGE" >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips not found. This script requires macOS built-in sips." >&2
  exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
  echo "iconutil not found. This script requires macOS built-in iconutil." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
ICONSET_DIR="$OUTPUT_DIR/AppIcon.iconset"
ICNS_FILE="$OUTPUT_DIR/AppIcon.icns"
BASE_PNG="$OUTPUT_DIR/AppIcon-1024.png"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Tune this ratio if the source has lots of white margin.
# 0.62 means: center-crop to 62% of the shorter edge before resizing.
CROP_RATIO="${ICON_CROP_RATIO:-0.62}"

WIDTH="$(sips -g pixelWidth "$SOURCE_IMAGE" | awk '/pixelWidth/ {print $2}')"
HEIGHT="$(sips -g pixelHeight "$SOURCE_IMAGE" | awk '/pixelHeight/ {print $2}')"

if [[ -z "$WIDTH" || -z "$HEIGHT" ]]; then
  echo "Failed to read source image size: $SOURCE_IMAGE" >&2
  exit 1
fi

MIN_SIDE="$WIDTH"
if (( HEIGHT < WIDTH )); then
  MIN_SIDE="$HEIGHT"
fi

CROP_SIZE="$(awk -v m="$MIN_SIDE" -v r="$CROP_RATIO" 'BEGIN { v=int(m*r); if (v<128) v=128; print v }')"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CROPPED="$TMP_DIR/cropped.png"
# Center crop so the middle symbol becomes the icon focus.
sips -c "$CROP_SIZE" "$CROP_SIZE" "$SOURCE_IMAGE" --out "$CROPPED" >/dev/null
sips -z 1024 1024 "$CROPPED" --out "$BASE_PNG" >/dev/null

cp "$BASE_PNG" "$ICONSET_DIR/icon_512x512@2x.png"
sips -z 16 16   "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32   "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32   "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64   "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"

echo "Generated:"
echo "  $BASE_PNG"
echo "  $ICONSET_DIR"
echo "  $ICNS_FILE"
echo
echo "Tip: If symbol is still too small or too big, rerun with ICON_CROP_RATIO, e.g.:"
echo "  ICON_CROP_RATIO=0.70 $0 \"$SOURCE_IMAGE\" \"$OUTPUT_DIR\""
