import CoreGraphics

enum DenseDossierDetent: CaseIterable, Equatable, Sendable {
    case compact
    case expanded

    static let compactFraction = CGFloat(0.40)

    var toggled: DenseDossierDetent {
        self == .compact ? .expanded : .compact
    }

    static func estimatedCoveredHeight(
        availableHeight: CGFloat,
        bottomSafeArea: CGFloat
    ) -> CGFloat {
        availableHeight * compactFraction + bottomSafeArea
    }
}
