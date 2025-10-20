# Brightness Util

Simple menu bar utility that displays the current main-display brightness for macOS 26. The aim is to bring back the 16-cell brightness bar in the macOS 26 menu bar.

![how the app looks like](./example.png)

The project uses private DisplayServices/CoreDisplay SPI calls (mirroring the `nriley/brightness` fallback chain).

## Features

- Menu bar extra that mimics the classic 16-cell brightness HUD with crisp dot rendering.
- Popover view showing both the dot grid and an exact percentage for the current brightness.
- Polling monitor that keeps the display in sync via DisplayServices/CoreDisplay/IOKit fallbacks.
- Runs as an accessory app so no Dock icon appears while the utility is active.
- SwiftUI-based implementation with reusable components for the tile and menu icon.

## Building from Terminal

You can build the app without opening Xcode using `xcodebuild`. From the repository root run:

```bash
xcodebuild -project brightness-util.xcodeproj \
           -scheme brightness-util \
           -configuration Release \
           -derivedDataPath build \
           CODE_SIGNING_ALLOWED=NO \
           clean build
```

This places the release `.app` bundle at `build/Build/Products/Release/brightness-util.app`.

## Launching

- To run immediately, execute `open build/Build/Products/Release/brightness-util.app`.
- For direct CLI execution, run `build/Build/Products/Release/brightness-util.app/Contents/MacOS/brightness-util`.
- Move the `.app` into `/Applications` (or anywhere else) to keep it handy between builds.

## Optional Signing & Distribution

- To share the app, zip the `.app` bundle or package it into a `.dmg` (e.g. with `create-dmg` or Disk Utility) before distributing. When zipping, use Finder’s **Compress** option or `ditto -c -k --sequesterRsrc --keepParent brightness-util.app brightness-util.zip` to avoid stripping resource forks.

## Clearing the “App is Damaged” Warning

Unsigned builds that travel over AirDrop, Messages, or a downloaded `.zip` pick up macOS’s quarantine flag. Gatekeeper interprets the unsigned/quarantined combo as “brightness-util.app is damaged and can’t be opened.” You just need to remove the quarantine attribute and reopen it.

1. Copy `brightness-util.app` to a writable folder (e.g. `~/Applications`).
2. Run the following in Terminal, substituting the actual path if it differs:

   ```bash
   xattr -dr com.apple.quarantine "/Users/<username>/Applications/brightness-util.app"
   ```

3. Double-click the app again. The first launch will still show the usual “Unknown developer” prompt—choose **Open** to continue.

If they already tried to launch it once, System Settings → Privacy & Security will show an **Open Anyway** button for `brightness-util`. Clicking that clears the quarantine flag for that copy without using Terminal.

## Development Notes

- The SwiftUI preview for `ContentView` sits behind `#if DEBUG` so release builds skip the preview helper and avoid instantiating `BrightnessMonitor` outside Xcode previews.
