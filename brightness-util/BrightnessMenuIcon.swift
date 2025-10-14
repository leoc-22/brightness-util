import SwiftUI
import AppKit

struct BrightnessMenuIcon: View {
    let filledCells: Int?

    private var accessibilityText: String {
        guard let filledCells else {
            return "Brightness unavailable"
        }
        return "Brightness \(filledCells) of \(BrightnessMenuIconRenderer.totalCells)"
    }

    var body: some View {
        Image(nsImage: BrightnessMenuIconRenderer.makeIcon(filledCells: filledCells))
            .interpolation(.none)
            .accessibilityLabel(accessibilityText)
    }
}

private enum BrightnessMenuIconRenderer {
    static let iconSize: CGFloat = 18
    static let columns = 4
    static let rows = 4
    static let totalCells = columns * rows

    private static let circleSize: CGFloat = 3
    private static let spacing: CGFloat = 1
    private static let cornerRadius: CGFloat = 5.5

    static func makeIcon(filledCells: Int?) -> NSImage {
        let size = NSSize(width: iconSize, height: iconSize)
        let image = NSImage(size: size, flipped: false) { rect in
            drawIcon(in: rect, filledCells: filledCells)
        }
        image.isTemplate = false
        return image
    }

    private static func drawIcon(in rect: NSRect, filledCells: Int?) -> Bool {
        guard let context = NSGraphicsContext.current else { return false }
        context.imageInterpolation = .none

        let backgroundRect = rect.insetBy(dx: 0.5, dy: 0.5)
        let backgroundPath = NSBezierPath(
            roundedRect: backgroundRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )
        NSColor(calibratedWhite: 0, alpha: 0.42).setFill()
        backgroundPath.fill()
        NSColor(calibratedWhite: 1.0, alpha: 0.2).setStroke()
        backgroundPath.lineWidth = 1
        backgroundPath.stroke()

        let contentWidth = CGFloat(columns) * circleSize + CGFloat(columns - 1) * spacing
        let contentHeight = CGFloat(rows) * circleSize + CGFloat(rows - 1) * spacing
        let startX = rect.midX - contentWidth / 2
        let startY = rect.midY - contentHeight / 2

        let clippedFilled = max(0, min(totalCells, filledCells ?? -1))
        let hasValue = filledCells != nil

        for row in 0..<rows {
            for column in 0..<columns {
                let index = row * columns + column
                let x = startX + CGFloat(column) * (circleSize + spacing)
                let y = startY + CGFloat(row) * (circleSize + spacing)
                let circleRect = NSRect(x: x, y: y, width: circleSize, height: circleSize)
                let circlePath = NSBezierPath(ovalIn: circleRect)

                if !hasValue {
                    NSColor(calibratedWhite: 1.0, alpha: 0.12).setFill()
                } else if index < clippedFilled {
                    NSColor.white.setFill()
                } else {
                    NSColor(calibratedWhite: 1.0, alpha: 0.15).setFill()
                }
                circlePath.fill()
            }
        }

        return true
    }
}
