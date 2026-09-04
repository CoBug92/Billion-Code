import Testing
@testable import BillionCode

@Suite("Dense dossier detents")
struct DenseDossierDetentTests {
    @Test("Compact dossier occupies about a quarter and includes bottom safe area")
    func compactHeight() {
        #expect(DenseDossierDetent.compact.height(availableHeight: 800, bottomSafeArea: 34) == 234)
    }

    @Test("Compact height stays usable on short and tall screens")
    func compactLimits() {
        #expect(DenseDossierDetent.compact.height(availableHeight: 500, bottomSafeArea: 0) == 190)
        #expect(DenseDossierDetent.compact.height(availableHeight: 1_200, bottomSafeArea: 34) == 250)
    }

    @Test("Expanded dossier covers the safe area")
    func expandedHeight() {
        #expect(DenseDossierDetent.expanded.height(availableHeight: 800, bottomSafeArea: 34) == 834)
    }
}
