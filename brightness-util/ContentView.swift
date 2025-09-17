import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var monitor: BrightnessMonitor

    private var brightnessText: String {
        if let percentage = monitor.percentage {
            return "\(percentage)%"
        }
        return "--%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Brightness")
                .font(.headline)

            Text(brightnessText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            Divider()

            Button("Quit Brightness Util") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 200)
    }
}

#Preview {
    ContentView(monitor: BrightnessMonitor())
}
