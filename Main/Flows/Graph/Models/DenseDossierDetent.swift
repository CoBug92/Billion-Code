import CoreGraphics

enum DenseDossierDetent: Equatable, Sendable {
    case compact
    case expanded

    func height(availableHeight: CGFloat, topSafeArea: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        switch self {
        case .compact:
            min(max(availableHeight * 0.25 + bottomSafeArea, 190), 250)
        case .expanded:
            max(
                DenseDossierDetent.compact.height(
                    availableHeight: availableHeight,
                    topSafeArea: topSafeArea,
                    bottomSafeArea: bottomSafeArea
                ),
                availableHeight - 12 + bottomSafeArea
            )
        }
    }
}
