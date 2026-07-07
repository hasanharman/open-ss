#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${CONFIG:-release}"
APP_DIR="$ROOT/build/OpenSS.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
SIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
VERSION="${VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"

cd "$ROOT"
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  swift build -c "$CONFIG" --arch arm64 --arch x86_64
  PRODUCTS_DIR="$(swift build -c "$CONFIG" --arch arm64 --arch x86_64 --show-bin-path)"
else
  swift build -c "$CONFIG"
  PRODUCTS_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$PRODUCTS_DIR/OpenSS" "$MACOS/OpenSS"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
cp "Resources/OpenSS.icns" "$RESOURCES/OpenSS.icns"
chmod +x "$MACOS/OpenSS"

if [[ -n "$VERSION" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS/Info.plist"
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application|Apple Development/ { print $2; exit }')"
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="-"
fi

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  # Ad-hoc signature: no hardened runtime or timestamp available.
  codesign --force --sign - "$APP_DIR"
else
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
fi

codesign --verify --strict "$APP_DIR"

echo "$APP_DIR"
