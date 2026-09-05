import CoreGraphics
import Testing
@testable import BillionCode

@Suite("Dense dossier detents")
struct DenseDossierDetentTests {
    @Test("Fallback compact height stays usable on short and tall screens")
    func fallbackCompactLimits() {
        #expect(DenseDossierDetent.fallbackCompactHeight(availableHeight: 500, bottomSafeArea: 0) == 190)
        #expect(DenseDossierDetent.fallbackCompactHeight(availableHeight: 800, bottomSafeArea: 34) == 234)
        #expect(DenseDossierDetent.fallbackCompactHeight(availableHeight: 1_200, bottomSafeArea: 34) == 250)
    }

    @Test("Compact body follows its content height until the screen limit")
    func compactBodyFollowsContentHeight() {
        let shortBodyHeight = DenseDossierDetent.compactBodyHeight(
            contentHeight: 180,
            headerHeight: 88,
            availableHeight: 800,
            bottomSafeArea: 34
        )
        let overflowingBodyHeight = DenseDossierDetent.compactBodyHeight(
            contentHeight: 1_000,
            headerHeight: 88,
            availableHeight: 800,
            bottomSafeArea: 34
        )

        #expect(shortBodyHeight == 180)
        #expect(overflowingBodyHeight == 734)
    }

    @Test("Three detents use header, content and screen heights")
    func detentHeights() {
        #expect(height(for: .collapsed) == 112)
        #expect(height(for: .compact) == 326)
        #expect(height(for: .expanded) == 822)
    }

    @Test("Each drag moves by one neighboring detent")
    func adjacentDragTarget() {
        #expect(DenseDossierDetent.collapsed.targetAfterDrag(translation: -80, predictedTranslation: -180) == .compact)
        #expect(DenseDossierDetent.compact.targetAfterDrag(translation: -80, predictedTranslation: -180) == .expanded)
        #expect(DenseDossierDetent.expanded.targetAfterDrag(translation: 80, predictedTranslation: 180) == .compact)
        #expect(DenseDossierDetent.compact.targetAfterDrag(translation: 80, predictedTranslation: 180) == .collapsed)
    }

    @Test("Prediction cannot reverse the actual drag direction")
    func actualDirectionWins() {
        #expect(DenseDossierDetent.compact.targetAfterDrag(translation: 80, predictedTranslation: -300) == .collapsed)
        #expect(DenseDossierDetent.compact.targetAfterDrag(translation: -80, predictedTranslation: 300) == .expanded)
    }

    @Test("Short drag returns to the current detent")
    func shortDragKeepsDetent() {
        #expect(DenseDossierDetent.compact.targetAfterDrag(translation: 20, predictedTranslation: 30) == .compact)
    }

    private func height(for detent: DenseDossierDetent) -> CGFloat {
        detent.height(
            collapsedHeight: 112,
            compactHeight: 326,
            availableHeight: 800,
            bottomSafeArea: 34
        )
    }

}
