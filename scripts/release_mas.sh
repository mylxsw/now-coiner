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
MAS_INSTALLER="${MAS_INSTALLER:-}"             # "Mac Installer Distribution: Name (TEAMID)"
ENTITLEMENTS="${ENTITLEMENTS:-$ROOT_DIR/NowCoiner-mas.entitlements}"
PROVISIONING_PROFILE="${PROVISIONING_PROFILE:-${MAS_PROVISIONING_PROFILE:-}}"

fail() {
  echo "$1" >&2
  exit 1
}

warn() {
  echo "$1" >&2
}

decode_profile_to_plist() {
  local profile_path="$1"
  local plist_path="$2"
  security cms -D -i "$profile_path" > "$plist_path" \
    || fail "Failed to decode provisioning profile: $profile_path"
}

build_signing_entitlements() {
  local profile_path="$1"
  local custom_entitlements_path="$2"
  local output_path="$3"
  local decoded_profile
  local profile_entitlements

  decoded_profile="$(mktemp /tmp/nowcoiner-profile-entitlements.XXXXXX)"
  profile_entitlements="$(mktemp /tmp/nowcoiner-signing-entitlements.XXXXXX)"

  decode_profile_to_plist "$profile_path" "$decoded_profile"
  /usr/libexec/PlistBuddy -x -c "Print :Entitlements" "$decoded_profile" > "$profile_entitlements" \
    || fail "Failed to extract entitlements from provisioning profile: $profile_path"

  cp "$profile_entitlements" "$output_path"

  # Ensure our app-specific sandbox capabilities remain enabled on top of the
  # profile-provided identity entitlements required by TestFlight/App Store.
  /usr/libexec/PlistBuddy -c "Set :com.apple.security.app-sandbox true" "$output_path" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :com.apple.security.app-sandbox bool true" "$output_path"
  /usr/libexec/PlistBuddy -c "Set :com.apple.security.network.client true" "$output_path" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :com.apple.security.network.client bool true" "$output_path"

  # If the custom entitlements file grows in the future, carry over any extra
  # top-level keys that aren't already present in the profile-derived payload.
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    if /usr/libexec/PlistBuddy -c "Print :$key" "$output_path" >/dev/null 2>&1; then
      continue
    fi

    local value_xml
    value_xml="$(plutil -extract "$key" xml1 -o - "$custom_entitlements_path" 2>/dev/null || true)"
    [[ -n "$value_xml" ]] || continue

    local value_payload
    value_payload="$(printf '%s\n' "$value_xml" | sed -n '/<plist/,/<\/plist>/p' | sed '1d;$d')"
    [[ -n "$value_payload" ]] || continue

    /usr/libexec/PlistBuddy -c "Add :$key $(printf '%s' "$value_payload")" "$output_path" >/dev/null 2>&1 || true
  done < <(plutil -p "$custom_entitlements_path" 2>/dev/null | sed -nE 's/^[[:space:]]*"([^"]+)" =>.*$/\1/p')

  rm -f "$decoded_profile" "$profile_entitlements"
}

validate_profile_certificate_match() {
  local profile_path="$1"
  local signing_identity="$2"
  local decoded_profile
  local cert_dir
  local i=0
  local matched=0
  local cert_names=()

  decoded_profile="$(mktemp /tmp/nowcoiner-profile.XXXXXX)"
  cert_dir="$(mktemp -d /tmp/nowcoiner-profile-certs.XXXXXX)"

  decode_profile_to_plist "$profile_path" "$decoded_profile"

  while true; do
    local cert_base64
    local cert_path
    local cert_subject
    local cert_name

    cert_base64="$(plutil -extract "DeveloperCertificates.$i" raw -expect data -o - "$decoded_profile" 2>/dev/null || true)"
    [[ -n "$cert_base64" ]] || break

    cert_path="$cert_dir/$i.cer"
    printf '%s' "$cert_base64" | openssl base64 -d -A > "$cert_path"
    cert_subject="$(openssl x509 -inform DER -in "$cert_path" -noout -subject 2>/dev/null || true)"
    cert_name="$(printf '%s\n' "$cert_subject" | sed -nE 's#^.*/CN=([^/]+).*$#\1#p')"
    if [[ -z "$cert_name" ]]; then
      cert_name="$(printf '%s\n' "$cert_subject" | sed -nE 's/^.*CN = ([^,]+).*$/\1/p')"
    fi

    if [[ -n "$cert_name" ]]; then
      cert_names+=("$cert_name")
      if [[ "$cert_name" == "$signing_identity" ]]; then
        matched=1
      fi
    fi
    i=$((i + 1))
  done

  if [[ "${#cert_names[@]}" -eq 0 ]]; then
    warn "Warning: unable to parse developer certificates from provisioning profile, skipping local certificate match check."
    rm -f "$decoded_profile"
    rm -rf "$cert_dir"
    return 0
  fi

  if [[ "$matched" -ne 1 ]]; then
    {
      echo "Signing identity does not match the provisioning profile."
      echo "APPLE_DISTRIBUTION: $signing_identity"
      echo "Allowed profile certificates:"
      if [[ "${#cert_names[@]}" -gt 0 ]]; then
        printf '  - %s\n' "${cert_names[@]}"
      else
        echo "  - <none parsed>"
      fi
    } >&2
    rm -f "$decoded_profile"
    rm -rf "$cert_dir"
    exit 1
  fi

  rm -f "$decoded_profile"
  rm -rf "$cert_dir"
}

usage() {
  cat <<USAGE
Usage:
  APPLE_DISTRIBUTION="Apple Distribution: <Name> (<TEAMID>)" \\
  MAS_INSTALLER="Mac Installer Distribution: <Name> (<TEAMID>)" \\
  PROVISIONING_PROFILE="/path/to/embedded.provisionprofile" \\
  ./scripts/release_mas.sh

Optional env:
  APP_PATH, OUTPUT_DIR, PKG_PATH, EXECUTABLE_NAME, APP_NAME, ENTITLEMENTS,
  PROVISIONING_PROFILE
USAGE
}

[[ -n "$APPLE_DISTRIBUTION" ]] || { usage; fail "Missing APPLE_DISTRIBUTION"; }
[[ -n "$MAS_INSTALLER" ]] || { usage; fail "Missing MAS_INSTALLER"; }
[[ -f "$ENTITLEMENTS" ]] || fail "Entitlements file not found: $ENTITLEMENTS"
[[ -n "$PROVISIONING_PROFILE" ]] || { usage; fail "Missing PROVISIONING_PROFILE"; }
[[ -f "$PROVISIONING_PROFILE" ]] || fail "Provisioning profile not found: $PROVISIONING_PROFILE"
[[ -d "$APP_PATH" ]] || fail "App not found: $APP_PATH"

echo "Validating provisioning profile certificate match..."
echo "  Profile: $PROVISIONING_PROFILE"
echo "  Signing identity: $APPLE_DISTRIBUTION"
validate_profile_certificate_match "$PROVISIONING_PROFILE" "$APPLE_DISTRIBUTION"

cp "$PROVISIONING_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"

if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
fi

# Release gate: verify app structure before signing.
APP_PATH="$APP_PATH" EXECUTABLE_NAME="$EXECUTABLE_NAME" REQUIRE_SIGNABLE_LAYOUT=1 ./scripts/release_preflight.sh

SIGNING_ENTITLEMENTS="$(mktemp /tmp/nowcoiner-app-entitlements.XXXXXX)"
build_signing_entitlements "$PROVISIONING_PROFILE" "$ENTITLEMENTS" "$SIGNING_ENTITLEMENTS"

echo "Signing app for Mac App Store..."
codesign --force --options runtime --timestamp \
  --sign "$APPLE_DISTRIBUTION" \
  --entitlements "$SIGNING_ENTITLEMENTS" \
  "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
rm -f "$SIGNING_ENTITLEMENTS"

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
