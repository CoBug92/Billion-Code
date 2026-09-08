import SwiftUI

extension DenseGraphEdge.Kind {
    @MainActor
    var color: Color {
        switch self {
        case .business:
            Asset.Colors.chapterCoral.swiftUIColor
        case .education:
            Asset.Colors.chapterViolet.swiftUIColor
        case .family:
            Asset.Colors.chapterTeal.swiftUIColor
        case .association:
            Asset.Colors.chapterBlue.swiftUIColor
        }
    }
}

extension GraphEntityKind {
    @MainActor
    var denseGraphColor: Color {
        switch self {
        case .person:
            Asset.Colors.chapterBlue.swiftUIColor
        case .organization:
            Asset.Colors.chapterAmber.swiftUIColor
        case .university:
            Asset.Colors.chapterViolet.swiftUIColor
        case .foundation, .family, .deal, .event:
            Asset.Colors.chapterTeal.swiftUIColor
        }
    }
}
