import SwiftUI

@main
struct brightness_utilApp: App {
    @StateObject private var monitor = BrightnessMonitor()

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor)
        } label: {
            Text(displayText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.menu)
    }

    private var displayText: String {
        if let percentage = monitor.percentage {
            return "\(percentage)%"
        }
        return "--%"
    }
}
