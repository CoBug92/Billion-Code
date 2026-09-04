import SwiftUI

@MainActor
extension GraphChapter {
    var accentColor: Color {
        switch accentIndex % 5 {
        case 0: Asset.Colors.chapterCoral.swiftUIColor
        case 1: Asset.Colors.chapterBlue.swiftUIColor
        case 2: Asset.Colors.chapterViolet.swiftUIColor
        case 3: Asset.Colors.chapterAmber.swiftUIColor
        default: Asset.Colors.chapterTeal.swiftUIColor
        }
    }
}

enum GraphNodeVisualRole: Equatable {
    case hero
    case selected
    case member

    var diameter: CGFloat {
        switch self {
        case .hero: 92
        case .selected: 72
        case .member: 56
        }
    }
}
