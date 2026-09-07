import CoreGraphics
import SwiftUI
import Testing
@testable import BillionCode

@Suite("Dense dossier detents")
struct DenseDossierDetentTests {
    @Test("Dossier uses a compact preview and a modal large state")
    func presentationDetents() {
        #expect(DenseDossierDetent.compact.presentationDetent == .fraction(0.40))
        #expect(DenseDossierDetent.expanded.presentationDetent == .large)
    }

    @Test("Toggle always moves between the two stable states")
    func toggle() {
        #expect(DenseDossierDetent.compact.toggled == .expanded)
        #expect(DenseDossierDetent.expanded.toggled == .compact)
    }

    @Test("Native presentation values resolve back to app state")
    func resolution() {
        #expect(DenseDossierDetent.resolve(.fraction(0.40)) == .compact)
        #expect(DenseDossierDetent.resolve(.large) == .expanded)
    }

    @Test("Graph focus reserves the same area as the compact sheet")
    func estimatedCoveredHeight() {
        let height = DenseDossierDetent.estimatedCoveredHeight(
            availableHeight: 800,
            bottomSafeArea: 34
        )
        #expect(height == 354)
    }
}
