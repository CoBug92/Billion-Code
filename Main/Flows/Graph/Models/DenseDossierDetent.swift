import CoreGraphics

enum DenseDossierDetent: CaseIterable, Equatable, Sendable {
    static let fallbackCollapsedHeight = CGFloat(140)

    case collapsed
    case compact
    case expanded

    static func compactBodyHeight(
        contentHeight: CGFloat,
        headerHeight: CGFloat,
        availableHeight: CGFloat,
        bottomSafeArea: CGFloat
    ) -> CGFloat {
        let maximumPanelHeight = expandedPanelHeight(
            availableHeight: availableHeight,
            bottomSafeArea: bottomSafeArea
        )
        return min(contentHeight, max(maximumPanelHeight - headerHeight, .zero))
    }

    static func fallbackCompactHeight(availableHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        min(max(availableHeight * 0.25 + bottomSafeArea, 190), 250)
    }

    var lowerNeighbor: DenseDossierDetent {
        switch self {
        case .collapsed, .compact: .collapsed
        case .expanded: .compact
        }
    }

    var upperNeighbor: DenseDossierDetent {
        switch self {
        case .collapsed: .compact
        case .compact, .expanded: .expanded
        }
    }

    func targetAfterDrag(translation: CGFloat, predictedTranslation: CGFloat) -> DenseDossierDetent {
        let predictedContinuesDirection = translation * predictedTranslation > .zero
        let travel = predictedContinuesDirection
            ? max(abs(translation), abs(predictedTranslation))
            : abs(translation)
        guard travel >= 44 else { return self }

        return translation > .zero ? lowerNeighbor : upperNeighbor
    }

    func height(
        collapsedHeight: CGFloat,
        compactHeight: CGFloat,
        availableHeight: CGFloat,
        bottomSafeArea: CGFloat
    ) -> CGFloat {
        switch self {
        case .collapsed:
            collapsedHeight
        case .compact:
            max(compactHeight, collapsedHeight)
        case .expanded:
            max(
                compactHeight,
                Self.expandedPanelHeight(
                    availableHeight: availableHeight,
                    bottomSafeArea: bottomSafeArea
                )
            )
        }
    }
}

// MARK: - Private methods

private extension DenseDossierDetent {
    static func expandedPanelHeight(availableHeight: CGFloat, bottomSafeArea: CGFloat) -> CGFloat {
        availableHeight - 12 + bottomSafeArea
    }
}
