#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-debug}"
SIGN_AND_NOTARIZE="${2:-dev}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${GREEDLESS_APP_NAME:-Greedless Manager}"
BUNDLE_ID="${GREEDLESS_BUNDLE_ID:-org.greedless.manager}"
case "$APP_NAME" in
  ''|.|..|*/*)
    echo "package-app: the app name must be a single directory name" >&2
    exit 1
    ;;
esac
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
GHOSTTY_LIBRARY_DIR="$("$ROOT_DIR/Scripts/ghostty-preflight.sh" print-library-dir)"
SWIFT_BUILD_ARGS=(-c "$CONFIG" --arch arm64)

SIGNING_IDENTITY="${GREEDLESS_SIGNING_IDENTITY:-}"
NOTARIZE_PROFILE="${GREEDLESS_NOTARIZE_PROFILE:-}"
ENTITLEMENTS="$ROOT_DIR/OmniWM.entitlements"

case "$SIGN_AND_NOTARIZE" in
  true)
    if [ -z "$SIGNING_IDENTITY" ] || [ -z "$NOTARIZE_PROFILE" ]; then
      echo "package-app: distribution signing requires GREEDLESS_SIGNING_IDENTITY and GREEDLESS_NOTARIZE_PROFILE" >&2
      exit 1
    fi
    echo "Running release checks..."
    make -C "$ROOT_DIR" release-check
    ;;
  dev|false) ;;
  *) echo "package-app: signing mode must be dev, false, or true" >&2; exit 1 ;;
esac

"$ROOT_DIR/Scripts/ghostty-preflight.sh" verify

echo "Building Greedless Manager arm64 binaries ($CONFIG)..."
LIBRARY_PATH="$GHOSTTY_LIBRARY_DIR${LIBRARY_PATH:+:$LIBRARY_PATH}" swift build "${SWIFT_BUILD_ARGS[@]}"
BUILD_DIR="$(LIBRARY_PATH="$GHOSTTY_LIBRARY_DIR${LIBRARY_PATH:+:$LIBRARY_PATH}" swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"
EXECUTABLE="$BUILD_DIR/OmniWM"
CLI_EXECUTABLE="$BUILD_DIR/greedlessctl"

echo "Verifying arm64 binaries..."
lipo -info "$EXECUTABLE"
lipo -info "$CLI_EXECUTABLE"

echo "Packaging $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/OmniWM"
cp "$CLI_EXECUTABLE" "$APP_DIR/Contents/MacOS/greedlessctl"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if command -v plutil >/dev/null 2>&1; then
  plutil -replace OMNIWMGitHash -string "$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo SNAPSHOT)" "$APP_DIR/Contents/Info.plist"
  if [ "$APP_NAME" != "Greedless Manager" ] || [ "$BUNDLE_ID" != "org.greedless.manager" ]; then
    plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_DIR/Contents/Info.plist"
    plutil -replace CFBundleName -string "$APP_NAME" "$APP_DIR/Contents/Info.plist"
    plutil -replace CFBundleDisplayName -string "$APP_NAME" "$APP_DIR/Contents/Info.plist"
  fi
fi
cp "$ROOT_DIR/Resources/GreedlessIcon.icns" "$APP_DIR/Contents/Resources/GreedlessIcon.icns"
cp -R "$BUILD_DIR/OmniWM_OmniWM.bundle" "$APP_DIR/Contents/Resources/"
python3 "$ROOT_DIR/Scripts/localization.py" package \
  --bundle "$BUILD_DIR/OmniWM_OmniWM.bundle" --app "$APP_DIR"

if command -v plutil >/dev/null 2>&1; then
  plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null
fi

if [ "$SIGN_AND_NOTARIZE" = "true" ]; then
  echo "Signing $APP_DIR with hardened runtime..."
  codesign --force --options runtime --sign "$SIGNING_IDENTITY" --timestamp "$APP_DIR/Contents/MacOS/greedlessctl"
  codesign --force --options runtime --entitlements "$ENTITLEMENTS" --sign "$SIGNING_IDENTITY" --timestamp "$APP_DIR/Contents/MacOS/OmniWM"
  codesign --force --options runtime --entitlements "$ENTITLEMENTS" --sign "$SIGNING_IDENTITY" --timestamp "$APP_DIR"

  echo "Verifying signature..."
  codesign --verify --verbose "$APP_DIR"

  echo "Creating ZIP for notarization..."
  ZIP_PATH="$ROOT_DIR/dist/$APP_NAME.zip"
  rm -f "$ZIP_PATH"
  ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

  echo "Submitting for notarization (this may take a few minutes)..."
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARIZE_PROFILE" --wait --timeout "${GREEDLESS_NOTARIZE_TIMEOUT:-30m}"

  echo "Stapling notarization ticket..."
  xcrun stapler staple "$APP_DIR"

  echo "Verifying notarization..."
  spctl --assess --verbose=2 "$APP_DIR"

  echo "Checking distribution readiness..."
  syspolicy_check distribution "$APP_DIR"

  rm -f "$ZIP_PATH"
  echo "Done! $APP_DIR is signed and notarized."
elif [ "$SIGN_AND_NOTARIZE" = "dev" ]; then
  echo "Ad-hoc signing $APP_DIR for local use..."
  codesign --force --sign - "$APP_DIR/Contents/MacOS/greedlessctl"
  codesign --force --entitlements "$ENTITLEMENTS" --sign - "$APP_DIR/Contents/MacOS/OmniWM"
  codesign --force --entitlements "$ENTITLEMENTS" --sign - "$APP_DIR"
  codesign --verify --verbose "$APP_DIR"
  echo "Done. Launch with 'open $APP_DIR' so LaunchServices assigns the app identity."
else
  echo "Done. Open $APP_DIR to grant Accessibility permissions."
  echo "Note: App is not signed. Distribution signing requires explicit credentials."
fi
