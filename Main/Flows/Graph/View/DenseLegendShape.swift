import SwiftUI

enum DenseLegendShape {
    case circle
    case diamond
    case triangle

    @ViewBuilder
    func view(color: Color) -> some View {
        switch self {
        case .circle:
            Circle().fill(color)
        case .diamond:
            RoundedRectangle(cornerRadius: 1).fill(color).rotationEffect(.degrees(45))
        case .triangle:
            Image(systemName: AppSymbols.legendTriangle).resizable().foregroundStyle(color)
        }
    }
}
