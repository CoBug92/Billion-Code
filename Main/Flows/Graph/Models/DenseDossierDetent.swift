import CoreGraphics

enum DenseDossierDetent: Equatable, Sendable {
    case compact
    case expanded

    func height(availableHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        switch self {
        case .compact:
            min(max(availableHeight * 0.25 + bottomSafeArea, 190), 250)
        case .expanded:
            availableHeight + bottomSafeArea
        }
    }
}
