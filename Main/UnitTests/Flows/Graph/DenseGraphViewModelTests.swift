import Testing
@testable import BillionCode

@MainActor
@Suite("Dense graph selection")
struct DenseGraphViewModelTests {
    @Test("Selecting a person highlights institutions and their people")
    func personSelectionExpandsTwoHops() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)

        viewModel.selectNode(id: "person:elon-musk")

        #expect(viewModel.highlightedNodeIDs.contains("organization:tesla"))
        #expect(viewModel.highlightedNodeIDs.contains("university:stanford"))
        #expect(viewModel.highlightedNodeIDs.contains("person:jb-straubel"))
        #expect(viewModel.highlightedNodeIDs.contains("person:larry-page"))
        #expect(!viewModel.highlightedNodeIDs.contains("person:sam-altman"))
        #expect(!viewModel.highlightedNodeIDs.contains("person:jeff-bezos"))
        if let tesla = viewModel.graph.node(id: "organization:tesla"),
           let straubel = viewModel.graph.node(id: "person:jb-straubel") {
            #expect(viewModel.shouldShowLabel(for: tesla))
            #expect(!viewModel.shouldShowLabel(for: straubel))
        } else {
            Issue.record("Required fixture nodes are missing")
        }
    }

    @Test("Selecting an institution highlights only its direct neighborhood")
    func institutionSelectionUsesOneHop() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)

        viewModel.selectNode(id: "university:stanford")

        #expect(viewModel.highlightedNodeIDs.contains("person:elon-musk"))
        #expect(viewModel.highlightedNodeIDs.contains("person:sam-altman"))
        #expect(!viewModel.highlightedNodeIDs.contains("organization:tesla"))
    }

    @Test("Repeated selection clears the highlight")
    func repeatedSelectionClears() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)

        viewModel.selectNode(id: "person:elon-musk")
        viewModel.selectNode(id: "person:elon-musk")

        #expect(viewModel.selectedNodeID == nil)
        #expect(viewModel.highlightedNodeIDs.isEmpty)
        #expect(viewModel.highlightedEdgeIDs.isEmpty)
    }

    @Test("Dossier navigation records history and restores selection")
    func dossierNavigationBack() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        let originalCamera = viewModel.camera

        viewModel.navigate(to: "organization:tesla")

        #expect(viewModel.selectedNodeID == "organization:tesla")
        #expect(viewModel.canNavigateBack)
        #expect(viewModel.camera != originalCamera)

        viewModel.navigateBack()

        #expect(viewModel.selectedNodeID == "person:elon-musk")
        #expect(viewModel.camera == originalCamera)
        #expect(!viewModel.canNavigateBack)
    }

    @Test("Direct graph selection starts a new exploration path")
    func directSelectionClearsHistory() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        viewModel.navigate(to: "organization:tesla")

        viewModel.selectNode(id: "person:sam-altman")

        #expect(viewModel.selectedNodeID == "person:sam-altman")
        #expect(!viewModel.canNavigateBack)
    }
}
