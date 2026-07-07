# OpenSS

OpenSS is a small macOS menu bar app for long screenshots. Click the menu bar icon or press `Cmd+Shift+L`, then click a visible window in the menu bar preview popover. OpenSS starts immediately, scrolls until the window stops changing, and stitches the captures into a single PNG on your Desktop.

Use `Content only` to crop browser chrome such as tabs, address bars, and bookmark bars from Chrome-like browser captures.

## Run from source

```bash
swift run
```

## Build an app bundle

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open build/OpenSS.app
```

## Website Demo

```bash
cd website
pnpm install
pnpm dev
```

The website is a faux macOS desktop that demonstrates the menu bar picker,
content-only capture option, and stitched long-screenshot result.

## Permissions

Long screenshots need both macOS permissions:

- Screen Recording, so OpenSS can capture the selected window.
- Accessibility, so OpenSS can send scroll gestures to the selected app.

OpenSS prompts for both when you start a capture. After granting Screen Recording or Accessibility, restart OpenSS from the popover so macOS refreshes the permission state for the running process.

The menu bar popover shows permissions in green when everything is ready and red when something needs attention. Window previews require Screen Recording permission.

## Current Behavior

OpenSS captures the selected window, scrolls down automatically, and stops when the next capture is visually the same as the previous one. It still has an internal safety limit to avoid infinite captures in unusual apps.
