import SwiftUI
import AppKit

struct ContentView: View {
    let displayName: String
    let brightness: Double?

    @StateObject private var launchAtLogin = LaunchAtLogin()

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

            MenuRowButton(action: launchAtLogin.toggle) {
                Text("Launch at Login")
                Spacer()
                if launchAtLogin.requiresApproval {
                    Text("Needs approval")
                        .font(.system(size: 11))
                } else if launchAtLogin.isEnabled {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .accessibilityHidden(true)
                }
            }
            .accessibilityAddTraits(launchAtLogin.isEnabled ? .isSelected : [])

            MenuRowButton(action: { NSApp.terminate(nil) }) {
                Text("Quit")
                Spacer()
                Text("⌘Q")
                    .opacity(0.6)
                    .accessibilityHidden(true)
            }
            .keyboardShortcut("q")
        }
        .foregroundStyle(.primary)
        .padding(8)
        .frame(width: 240)
        .onAppear { launchAtLogin.refresh() }
    }
}

/// A full-width row that highlights on hover like a native menu item.
private struct MenuRowButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(content: label)
                .font(.system(size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .foregroundStyle(isHovered ? Color(nsColor: .selectedMenuItemTextColor) : Color.primary)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onDisappear { isHovered = false }
    }
}

#if DEBUG
#Preview {
    ContentView(displayName: "Built-in Retina Display", brightness: 0.42)
}
#endif
