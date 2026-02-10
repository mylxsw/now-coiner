#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-NowCoiner}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-NowCoinerApp}"
BUNDLE_ID="${BUNDLE_ID:-com.mylxsw.nowcoiner}"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-14.0}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Downloads}"
SIGN_MODE="${SIGN_MODE:-none}"  # none | adhoc

swift build -c release --product "$EXECUTABLE_NAME"

BIN_DIR="$(swift build --show-bin-path -c release)"
BIN_PATH="$BIN_DIR/$EXECUTABLE_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
  echo "Release binary not found: $BIN_PATH" >&2
  exit 1
fi

APP_PATH="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

if [[ -e "$APP_PATH" ]]; then
  BACKUP_PATH="$OUTPUT_DIR/${APP_NAME}.app.bak.$(date +%Y%m%d%H%M%S)"
  mv "$APP_PATH" "$BACKUP_PATH"
  echo "Existing app moved to: $BACKUP_PATH"
fi

mkdir -p "$MACOS_PATH" "$RESOURCES_PATH"

install -m 755 "$BIN_PATH" "$MACOS_PATH/$EXECUTABLE_NAME"

# Copy localizations into standard app resources layout.
RESOURCE_SRC_DIR="$ROOT_DIR/Sources/NowCoinerApp/Resources"
if [[ -d "$RESOURCE_SRC_DIR" ]]; then
  while IFS= read -r -d '' lproj_dir; do
    cp -R "$lproj_dir" "$RESOURCES_PATH/"
  done < <(find "$RESOURCE_SRC_DIR" -maxdepth 1 -type d -name "*.lproj" -print0)
else
  echo "Warning: resource source dir not found: $RESOURCE_SRC_DIR" >&2
fi

# Optional icon file for Finder / app metadata
ICON_SOURCE="$ROOT_DIR/Sources/NowCoinerApp/Resources/AppIcon.icns"
if [[ -f "$ICON_SOURCE" ]]; then
  cp "$ICON_SOURCE" "$RESOURCES_PATH/AppIcon.icns"
  ICON_PLIST_LINE=$'\t<key>CFBundleIconFile</key>\n\t<string>AppIcon</string>'
else
  ICON_PLIST_LINE=""
fi

cat > "$CONTENTS_PATH/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>${APP_NAME}</string>
	<key>CFBundleExecutable</key>
	<string>${EXECUTABLE_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
${ICON_PLIST_LINE}
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${BUILD_NUMBER}</string>
	<key>LSMinimumSystemVersion</key>
	<string>${MIN_SYSTEM_VERSION}</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

case "$SIGN_MODE" in
  none)
    ;;
  adhoc)
    if command -v codesign >/dev/null 2>&1; then
      # Note: SwiftPM executable resources are loaded from app root by default.
      # Ad-hoc signing may fail with "unsealed contents present in the bundle root".
      codesign --force --deep --sign - "$APP_PATH"
      codesign --verify --deep --strict --verbose=2 "$APP_PATH" >/dev/null
    else
      echo "Warning: codesign not found, skip signing" >&2
    fi
    ;;
  *)
    echo "Invalid SIGN_MODE: $SIGN_MODE (expected: none or adhoc)" >&2
    exit 1
    ;;
esac

echo "Packaged app: $APP_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Version: $VERSION ($BUILD_NUMBER)"
