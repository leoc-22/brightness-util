import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var monitor: BrightnessMonitor

    private var percentageText: String {
        guard let cells = monitor.cellCount else { return "--%" }
        let percent = Int((Double(cells) / 16.0 * 100.0).rounded())
        return "\(percent)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Brightness")
                .font(.headline)

            Text(percentageText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            BrightnessTile(
                filledCells: monitor.cellCount,
                circleSize: 14,
                spacing: 8,
                cornerRadius: 18,
                columns: 4
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)

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

#if DEBUG
#Preview {
    ContentView(monitor: BrightnessMonitor())
}
#endif
