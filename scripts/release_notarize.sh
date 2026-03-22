#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-NowCoiner}"
APP_PATH="${APP_PATH:-$HOME/Downloads/${APP_NAME}.app}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Downloads}"
DMG_PATH="${DMG_PATH:-$OUTPUT_DIR/${APP_NAME}.dmg}"
VOL_NAME="${VOL_NAME:-$APP_NAME}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-NowCoinerApp}"

# Required for real release signing and notarization
DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
ENTITLEMENTS="${ENTITLEMENTS:-$ROOT_DIR/NowCoiner.entitlements}"

usage() {
  cat <<USAGE
Usage:
  DEVELOPER_ID_APP="Developer ID Application: <Name> (<TEAMID>)" \\
  NOTARY_PROFILE="<keychain-profile>" \\
  ./scripts/release_notarize.sh

Optional env:
  APP_PATH, OUTPUT_DIR, DMG_PATH, VOL_NAME, EXECUTABLE_NAME, APP_NAME
USAGE
}

[[ -n "$DEVELOPER_ID_APP" ]] || { usage; echo "Missing DEVELOPER_ID_APP" >&2; exit 1; }
[[ -n "$NOTARY_PROFILE" ]] || { usage; echo "Missing NOTARY_PROFILE" >&2; exit 1; }
[[ -f "$ENTITLEMENTS" ]] || { echo "Entitlements file not found: $ENTITLEMENTS" >&2; exit 1; }

[[ -d "$APP_PATH" ]] || { echo "App not found: $APP_PATH" >&2; exit 1; }

# Release gate: this must pass before signing/notarization.
APP_PATH="$APP_PATH" EXECUTABLE_NAME="$EXECUTABLE_NAME" REQUIRE_SIGNABLE_LAYOUT=1 ./scripts/release_preflight.sh

echo "Signing app with Developer ID..."
codesign --force --options runtime --timestamp \
  --sign "$DEVELOPER_ID_APP" \
  --entitlements "$ENTITLEMENTS" \
  "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl -a -t exec -vv "$APP_PATH" || true

TMP_DMG="${DMG_PATH%.dmg}.tmp.dmg"
rm -f "$TMP_DMG" "$DMG_PATH"

echo "Creating DMG..."
hdiutil create -volname "$VOL_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$TMP_DMG" >/dev/null
mv "$TMP_DMG" "$DMG_PATH"

echo "Signing DMG..."
codesign --force --timestamp --sign "$DEVELOPER_ID_APP" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

echo "Submitting DMG for notarization..."
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "Stapling tickets..."
xcrun stapler staple "$APP_PATH"
xcrun stapler staple "$DMG_PATH"

xcrun stapler validate "$APP_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Release artifacts ready:"
echo "  $APP_PATH"
echo "  $DMG_PATH"
