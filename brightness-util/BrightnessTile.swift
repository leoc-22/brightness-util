import SwiftUI

struct BrightnessTile: View {
    @Environment(\.colorScheme) private var colorScheme

    let filledCells: Int?
    var circleSize: CGFloat = 6
    var spacing: CGFloat = 2
    var cornerRadius: CGFloat = 8
    var columns: Int = 4

    private let totalCells = 16

    private var clippedColumns: Int { max(1, columns) }
    private var rows: Int {
        Int(ceil(Double(totalCells) / Double(clippedColumns)))
    }

    private var horizontalPadding: CGFloat { spacing * 1.5 }
    private var verticalPadding: CGFloat { spacing * 1.5 }

    private var tileSize: CGSize {
        let width = CGFloat(clippedColumns) * circleSize
            + CGFloat(max(0, clippedColumns - 1)) * spacing
            + horizontalPadding * 2
        let height = CGFloat(rows) * circleSize
            + CGFloat(max(0, rows - 1)) * spacing
            + verticalPadding * 2
        return CGSize(width: width, height: height)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tileBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(tileBorder, lineWidth: 0.8)
                )

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<clippedColumns, id: \.self) { column in
                            let logicalRow = rows - 1 - row
                            let index = logicalRow * clippedColumns + column
                            if index < totalCells {
                                Circle()
                                    .frame(width: circleSize, height: circleSize)
                                    .foregroundStyle(color(for: index))
                            } else {
                                Color.clear
                                    .frame(width: circleSize, height: circleSize)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .frame(width: tileSize.width, height: tileSize.height)
        .accessibilityLabel(accessibilityText)
    }

    private func color(for index: Int) -> Color {
        let filledColor = Color.white
        let emptyColor = Color.white.opacity(0.15)
        let unavailableColor = Color.white.opacity(0.12)

        guard let filledCells else {
            return unavailableColor
        }

        let clippedFilled = max(0, min(totalCells, filledCells))
        return index < clippedFilled ? filledColor : emptyColor
    }

    private var tileBackground: Color {
        Color.black.opacity(colorScheme == .dark ? 0.32 : 0.42)
    }

    private var tileBorder: Color {
        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.2)
    }

    private var accessibilityText: String {
        guard let filledCells else {
            return "Brightness unavailable"
        }
        return "Brightness \(filledCells) of \(totalCells)"
    }
}
