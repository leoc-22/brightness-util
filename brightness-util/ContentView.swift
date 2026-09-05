import SwiftUI
import AppKit

struct ContentView: View {
    let displayName: String
    let brightness: Double?

    @State private var isQuitHovered = false

    private var percentageText: String {
        guard let brightness else { return "—" }
        let percent = Int((brightness * 100).rounded())
        return "\(percent)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text(displayName)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center) {
                    Text("Brightness")
                        .font(.subheadline)
                    Spacer()
                    Text(percentageText)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }

                HStack(spacing: 10) {
                    Image(systemName: "sun.min")
                    GeometryReader { geometry in
                        Capsule()
                            .fill(.primary.opacity(0.15))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(.primary)
                                    .frame(width: geometry.size.width * CGFloat(brightness ?? 0))
                            }
                    }
                    .frame(height: 4)
                    Image(systemName: "sun.max")
                }
                .font(.system(size: 12))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Brightness")
                .accessibilityValue(brightness == nil ? "Unavailable" : percentageText)

                if brightness == nil {
                    Text("Brightness unavailable for this display.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Text("Quit Brightness Util")
                    Spacer()
                    Text("⌘Q")
                        .foregroundStyle(isQuitHovered ? Color(nsColor: .selectedMenuItemTextColor) : Color.secondary)
                        .accessibilityHidden(true)
                }
                    .font(.system(size: 13))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .foregroundStyle(isQuitHovered ? Color(nsColor: .selectedMenuItemTextColor) : Color.primary)
                    .background {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(isQuitHovered ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isQuitHovered = $0 }
            .onDisappear { isQuitHovered = false }
            .keyboardShortcut("q")
        }
        .foregroundStyle(.primary)
        .padding(8)
        .frame(width: 240)
    }
}

#if DEBUG
#Preview {
    ContentView(displayName: "Built-in Retina Display", brightness: 0.42)
}
#endif
