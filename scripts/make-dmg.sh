#!/usr/bin/env bash
set -euo pipefail

# Packages build/OpenSS.app into a DMG with a styled installer window
# (app on the left, Applications drop link on the right, background with
# a drag arrow). Requires create-dmg (brew install create-dmg); falls
# back to a plain hdiutil DMG when it is not installed.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/build/OpenSS.app"
VERSION="${VERSION:-dev}"
DIST="$ROOT/dist"
DMG_PATH="$DIST/OpenSS-$VERSION.dmg"

if [[ ! -d "$APP_DIR" ]]; then
  echo "build/OpenSS.app not found. Run scripts/build-app.sh first." >&2
  exit 1
fi

mkdir -p "$DIST"
rm -f "$DMG_PATH"

if command -v create-dmg > /dev/null; then
  create-dmg \
    --volname "OpenSS" \
    --volicon "$ROOT/Resources/OpenSS.icns" \
    --background "$ROOT/Resources/dmg-background.png" \
    --window-pos 200 160 \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "OpenSS.app" 140 190 \
    --app-drop-link 400 190 \
    --hide-extension "OpenSS.app" \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_DIR"
else
  echo "create-dmg not found; building a plain DMG without a styled window." >&2
  STAGING="$(mktemp -d)"
  cp -R "$APP_DIR" "$STAGING/OpenSS.app"
  ln -s /Applications "$STAGING/Applications"
  hdiutil create -volname "OpenSS" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH"
  rm -rf "$STAGING"
fi

echo "$DMG_PATH"
