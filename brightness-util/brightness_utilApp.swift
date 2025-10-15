import SwiftUI
import AppKit

@main
struct brightness_utilApp: App {
    @StateObject private var monitor = BrightnessMonitor()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor)
        } label: {
            BrightnessMenuIcon(filledCells: monitor.cellCount)
        }
        .menuBarExtraStyle(.menu)
    }
}
