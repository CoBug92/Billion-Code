import CoreGraphics

enum GraphPanelDetent: CaseIterable, Equatable, Sendable {
    case collapsed
    case medium
    case expanded

    func height(availableHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        switch self {
        case .collapsed:
            128 + bottomSafeArea
        case .medium:
            availableHeight * 0.52
        case .expanded:
            availableHeight + bottomSafeArea
        }
    }

    func resolved(
        predictedTranslation: CGFloat,
        availableHeight: CGFloat,
        bottomSafeArea: CGFloat
    ) -> GraphPanelDetent {
        let projectedHeight = height(
            availableHeight: availableHeight,
            bottomSafeArea: bottomSafeArea
        ) - predictedTranslation
        return Self.allCases.min { left, right in
            abs(left.height(availableHeight: availableHeight, bottomSafeArea: bottomSafeArea) - projectedHeight)
                < abs(right.height(availableHeight: availableHeight, bottomSafeArea: bottomSafeArea) - projectedHeight)
        } ?? self
    }
}
