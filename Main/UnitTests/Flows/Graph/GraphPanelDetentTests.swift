import Testing
@testable import BillionCode

@Suite("GraphPanelDetent")
struct GraphPanelDetentTests {
    @Test("detent heights include expected safe-area contract")
    func heights() {
        #expect(GraphPanelDetent.collapsed.height(availableHeight: 800, bottomSafeArea: 34) == 162)
        #expect(GraphPanelDetent.medium.height(availableHeight: 800, bottomSafeArea: 34) == 416)
        #expect(GraphPanelDetent.expanded.height(availableHeight: 800, bottomSafeArea: 34) == 834)
    }

    @Test("predicted swipe selects nearest detent")
    func snapping() {
        #expect(
            GraphPanelDetent.collapsed.resolved(
                predictedTranslation: -300,
                availableHeight: 800,
                bottomSafeArea: 34
            ) == .medium
        )
        #expect(
            GraphPanelDetent.collapsed.resolved(
                predictedTranslation: -900,
                availableHeight: 800,
                bottomSafeArea: 34
            ) == .expanded
        )
        #expect(
            GraphPanelDetent.expanded.resolved(
                predictedTranslation: 700,
                availableHeight: 800,
                bottomSafeArea: 34
            ) == .collapsed
        )
    }
}
