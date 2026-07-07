#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${CONFIG:-release}"
APP_DIR="$ROOT/build/OpenSS.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
SIGN_IDENTITY="${CODESIGN_IDENTITY:-}"

cd "$ROOT"
swift build -c "$CONFIG"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/$CONFIG/OpenSS" "$MACOS/OpenSS"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
cp "Resources/OpenSS.icns" "$RESOURCES/OpenSS.icns"
chmod +x "$MACOS/OpenSS"

if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk -F'\"' '/Apple Development/ { print $2; exit }')"
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="-"
fi

codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

echo "$APP_DIR"
