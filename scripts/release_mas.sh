#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-NowCoiner}"
APP_PATH="${APP_PATH:-$HOME/Downloads/${APP_NAME}.app}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Downloads}"
PKG_PATH="${PKG_PATH:-$OUTPUT_DIR/${APP_NAME}.pkg}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-NowCoinerApp}"

# Required for Mac App Store signing
APPLE_DISTRIBUTION="${APPLE_DISTRIBUTION:-}"   # "Apple Distribution: Name (TEAMID)"
MAS_INSTALLER="${MAS_INSTALLER:-}"             # "3rd Party Mac Developer Installer: Name (TEAMID)"
ENTITLEMENTS="${ENTITLEMENTS:-$ROOT_DIR/NowCoiner-mas.entitlements}"

usage() {
  cat <<USAGE
Usage:
  APPLE_DISTRIBUTION="Apple Distribution: <Name> (<TEAMID>)" \\
  MAS_INSTALLER="3rd Party Mac Developer Installer: <Name> (<TEAMID>)" \\
  ./scripts/release_mas.sh

Optional env:
  APP_PATH, OUTPUT_DIR, PKG_PATH, EXECUTABLE_NAME, APP_NAME, ENTITLEMENTS
USAGE
}

[[ -n "$APPLE_DISTRIBUTION" ]] || { usage; echo "Missing APPLE_DISTRIBUTION" >&2; exit 1; }
[[ -n "$MAS_INSTALLER" ]] || { usage; echo "Missing MAS_INSTALLER" >&2; exit 1; }
[[ -f "$ENTITLEMENTS" ]] || { echo "Entitlements file not found: $ENTITLEMENTS" >&2; exit 1; }
[[ -d "$APP_PATH" ]] || { echo "App not found: $APP_PATH" >&2; exit 1; }

# Release gate: verify app structure before signing.
APP_PATH="$APP_PATH" EXECUTABLE_NAME="$EXECUTABLE_NAME" REQUIRE_SIGNABLE_LAYOUT=1 ./scripts/release_preflight.sh

# Sign inside-out: nested bundles first, then the app itself.
echo "Signing nested bundles for Mac App Store..."
while IFS= read -r -d '' bundle; do
  codesign --force --options runtime --timestamp \
    --sign "$APPLE_DISTRIBUTION" \
    --entitlements "$ENTITLEMENTS" \
    "$bundle"
done < <(find "$APP_PATH/Contents" -type d -name "*.bundle" -print0)

echo "Signing app for Mac App Store..."
codesign --force --options runtime --timestamp \
  --sign "$APPLE_DISTRIBUTION" \
  --entitlements "$ENTITLEMENTS" \
  "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Creating installer package..."
rm -f "$PKG_PATH"
productbuild \
  --component "$APP_PATH" /Applications \
  --sign "$MAS_INSTALLER" \
  "$PKG_PATH"

echo ""
echo "Mac App Store package ready: $PKG_PATH"
echo ""
echo "Next step: Open Transporter and upload the .pkg file to App Store Connect."
