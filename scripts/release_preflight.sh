#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${APP_PATH:-$HOME/Downloads/NowCoiner.app}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-NowCoinerApp}"
REQUIRE_SIGNABLE_LAYOUT="${REQUIRE_SIGNABLE_LAYOUT:-1}" # 1 for release, 0 for local run-only checks

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

warn() {
  echo "[WARN] $1"
}

pass() {
  echo "[PASS] $1"
}

echo "Preflight target: $APP_PATH"

[[ -d "$APP_PATH" ]] || fail "App bundle not found"
[[ -f "$APP_PATH/Contents/Info.plist" ]] || fail "Missing Info.plist"
[[ -x "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME" ]] || fail "Missing executable: $EXECUTABLE_NAME"
pass "Bundle skeleton exists"

plutil -lint "$APP_PATH/Contents/Info.plist" >/dev/null
pass "Info.plist is valid"

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
LSUIELEMENT="$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"

[[ -n "$BUNDLE_ID" ]] || fail "CFBundleIdentifier is empty"
[[ -n "$VERSION" ]] || fail "CFBundleShortVersionString is empty"
[[ -n "$BUILD" ]] || fail "CFBundleVersion is empty"
[[ "$LSUIELEMENT" == "true" ]] || warn "LSUIElement is not true (not a pure menu bar app)"
pass "Plist required keys exist (id/version/build)"

if [[ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]]; then
  pass "AppIcon.icns exists"
else
  warn "AppIcon.icns missing"
fi

if find "$APP_PATH" -maxdepth 1 -type d -name '*.bundle' | grep -q .; then
  ROOT_BUNDLES="$(find "$APP_PATH" -maxdepth 1 -type d -name '*.bundle' -print | tr '\n' ' ')"
  if [[ "$REQUIRE_SIGNABLE_LAYOUT" == "1" ]]; then
    fail "Found bundle(s) in app root (not signable for release): $ROOT_BUNDLES"
  else
    warn "Found bundle(s) in app root (run-only layout): $ROOT_BUNDLES"
  fi
else
  pass "No root-level .bundle payload"
fi

if command -v codesign >/dev/null 2>&1; then
  if codesign --verify --deep --strict --verbose=2 "$APP_PATH" >/dev/null 2>&1; then
    pass "codesign verify passed"
  else
    warn "codesign verify failed (expected before Developer ID signing)"
  fi
else
  warn "codesign not available"
fi

if command -v spctl >/dev/null 2>&1; then
  if spctl -a -t exec -vv "$APP_PATH" >/dev/null 2>&1; then
    pass "spctl assessment passed"
  else
    warn "spctl assessment failed (expected before notarization)"
  fi
else
  warn "spctl not available"
fi

echo "Preflight complete."
