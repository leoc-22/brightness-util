# brightness-util - Agent Notes

This repo was bootstrapped by Codex (GPT-5) in the Codex CLI. Everything below captures shortcuts and caveats discovered while wiring up the menu-bar brightness utility so future agents can move quickly.

## Project shape
- `brightness-util.xcodeproj` – standard SwiftUI macOS app set to build macOS 14+ (target currently disables App Sandbox & hardened runtime for SPI access).
- `brightness_utilApp.swift` – entry point that installs a `MenuBarExtra` with a label showing the brightness percentage and a simple sheet UI (`ContentView`).
- `BrightnessMonitor.swift` – ObservableObject that polls brightness; contains the interesting bits.

## Brightness reading strategy
The current implementation mirrors nriley/brightness#36; it follows the same DisplayServices → CoreDisplay → IOKit fallback chain described in that PR:
1. Try DisplayServices SPI (`DisplayServicesGetBrightness`).
2. Fall back to CoreDisplay SPI (`CoreDisplay_Display_GetUserBrightness`).
3. Fallback again to IOKit (`IODisplayGetFloatParameter`) using a matched `IODisplayConnect` service.
4. The display ID/service matching logic is cribbed from that PR. All SPI symbols are loaded at runtime via `dlopen`/`dlsym` with optional bindings.

Private APIs mean this app cannot ship through TestFlight/App Store without rework. For personal use, keep signing locally; if you re-enable the sandbox you’ll lose the SPI paths.

## Known runtime behavior
- When sandboxed the app is unable to talk to `backlightd`, so it shows `--%`. We disable the sandbox in `project.pbxproj` right now to avoid that.
- Even with the SPI checks some logs like “Unable to obtain a task name port right…” may show up on certain macOS builds; they’re benign but indicate the constraints above.

## Build/testing tips
- Builds require selecting a valid signing team in Xcode or running with `CODE_SIGNING_ALLOWED=NO` locally.
- Because of SPI usage, automated tests haven’t been added. If you need CI, add a mock layer around `BrightnessReader` and inject values.

## Future ideas
- Surfacing multiple displays would require mirroring more of nriley/brightness’s code; right now we only track `CGMainDisplayID()`.
- For App Store distribution, you’d need to replace the SPI usage with your own kernel extension or rely on user-granted screen-control privileges (there’s no sanctioned API yet).

Happy hacking! – Codex
