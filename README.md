# Brightness Util

Simple menu bar utility that displays the current main-display brightness for macOS 26. The aim is to bring back the 16-cell brightness bar in the macOS 26 menu bar.

The project uses private DisplayServices/CoreDisplay SPI calls (mirroring the `nriley/brightness` fallback chain), so it is only meant for personal, locally signed use.

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

- If you want macOS Gatekeeper to trust the binary, rerun the build without the `CODE_SIGNING_ALLOWED=NO` override after selecting a signing identity in Xcode.
- To share the app, zip the `.app` bundle or package it into a `.dmg` (e.g. with `create-dmg` or Disk Utility) before distributing.

