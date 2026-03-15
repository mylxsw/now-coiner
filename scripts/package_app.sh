#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-NowCoiner}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-NowCoinerApp}"
BUNDLE_ID="${BUNDLE_ID:-ai.gulu.app.nowcoiner}"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-14.0}"
APP_CATEGORY="${APP_CATEGORY:-public.app-category.finance}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/Downloads}"
SIGN_MODE="${SIGN_MODE:-none}"  # none | adhoc

swift build -c release --product "$EXECUTABLE_NAME"

BIN_DIR="$(swift build --show-bin-path -c release)"
RESOURCE_ACCESSOR_PATH="$(find "$BIN_DIR" -path "*/${EXECUTABLE_NAME}.build/DerivedSources/resource_bundle_accessor.swift" -print -quit)"
if [[ -n "$RESOURCE_ACCESSOR_PATH" ]] && ! grep -q 'Contents/Resources' "$RESOURCE_ACCESSOR_PATH"; then
  python3 - "$RESOURCE_ACCESSOR_PATH" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = '        let mainPath = Bundle.main.bundleURL.appendingPathComponent("NowCoiner_NowCoinerApp.bundle").path\n'
new = (
    '        let mainPath = Bundle.main.bundleURL.appendingPathComponent("NowCoiner_NowCoinerApp.bundle").path\n'
    '        let resourcesPath = Bundle.main.resourceURL?.appendingPathComponent("NowCoiner_NowCoinerApp.bundle").path\n'
)
if old in text and 'resourcesPath' not in text:
    text = text.replace(old, new, 1)
    text = text.replace(
        '        let preferredBundle = Bundle(path: mainPath)\n\n'
        '        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {\n',
        '        let preferredBundle = Bundle(path: mainPath)\n'
        '        let resourcesBundle = resourcesPath.flatMap(Bundle.init(path:))\n\n'
        '        guard let bundle = preferredBundle ?? resourcesBundle ?? Bundle(path: buildPath) else {\n',
        1,
    )
    text = text.replace(
        '            Swift.fatalError("could not load resource bundle: from \\(mainPath) or \\(buildPath)")\n',
        '            Swift.fatalError("could not load resource bundle: from \\(mainPath), \\(resourcesPath ?? "nil"), or \\(buildPath)")\n',
        1,
    )
    path.write_text(text)
PY
  swift build -c release --product "$EXECUTABLE_NAME"
  BIN_DIR="$(swift build --show-bin-path -c release)"
fi

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

# Copy SwiftPM resource bundles into standard app resources location.
while IFS= read -r -d '' bundle_dir; do
  cp -R "$bundle_dir" "$RESOURCES_PATH/"
done < <(find "$BIN_DIR" -maxdepth 1 -type d -name "*.bundle" -print0)

# Resource bundles should be sealed by the parent app signature rather than
# carrying their own nested code signature.
while IFS= read -r -d '' bundle_signature_dir; do
  rm -rf "$bundle_signature_dir"
done < <(find "$RESOURCES_PATH" -type d -path "*.bundle/_CodeSignature" -print0)

# SwiftPM resource bundles only contain a minimal Info.plist. App Store validation
# requires each nested bundle to have its own identifier and basic bundle metadata.
while IFS= read -r -d '' bundle_path; do
  bundle_name="$(basename "$bundle_path")"
  bundle_stem="${bundle_name%.bundle}"
  bundle_id_suffix="$(printf '%s' "$bundle_stem" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
  bundle_plist="$bundle_path/Info.plist"

  if [[ ! -f "$bundle_plist" ]]; then
    cat > "$bundle_plist" <<BUNDLEPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
BUNDLEPLIST
  fi

  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string ${BUNDLE_ID}.${bundle_id_suffix}" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}.${bundle_id_suffix}" "$bundle_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleName string ${bundle_stem}" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleName ${bundle_stem}" "$bundle_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string ${bundle_stem}" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ${bundle_stem}" "$bundle_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string BNDL" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundlePackageType BNDL" "$bundle_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleInfoDictionaryVersion 6.0" "$bundle_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${BUILD_NUMBER}" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "$bundle_plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${VERSION}" "$bundle_plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$bundle_plist"
done < <(find "$RESOURCES_PATH" -maxdepth 1 -type d -name "*.bundle" -print0)

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
	<key>LSApplicationCategoryType</key>
	<string>${APP_CATEGORY}</string>
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

# App Store upload rejects quarantined payload files. Clear the attribute after all
# resources have been copied into the assembled app bundle.
if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
fi

case "$SIGN_MODE" in
  none)
    ;;
  adhoc)
    if command -v codesign >/dev/null 2>&1; then
      # Resource bundles are in Contents/Resources, so --deep ad-hoc signing works correctly.
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
