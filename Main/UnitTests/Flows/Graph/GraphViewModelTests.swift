import CoreGraphics
import Testing
@testable import BillionCode

@MainActor
@Suite("Graph view model")
struct GraphViewModelTests {
    @Test("Selecting a node recenters without changing layout")
    func selectionAndStableLayout() {
        let graph = GraphFixture.spike
        let originalPositions = graph.nodes.map(\.position)
        let viewModel = GraphViewModel(graph: graph)
        let target = graph.nodes[17]

        viewModel.selectNode(id: target.id)

        #expect(viewModel.selectedNodeID == target.id)
        #expect(viewModel.camera.center == target.position)
        #expect(viewModel.graph.nodes.map(\.position) == originalPositions)
    }

    @Test("A line is opened through the structured relationship collection")
    func structuredRelationshipLookup() {
        let viewModel = GraphViewModel(graph: GraphFixture.spike)
        let relationship = viewModel.selectedRelationships[0]

        let otherNode = viewModel.node(
            opposite: relationship,
            from: viewModel.selectedNodeID
        )

        #expect(viewModel.selectedRelationships.count == 39)
        #expect(otherNode?.id == relationship.targetID)
    }

    @Test("Camera gestures do not mutate graph coordinates")
    func cameraGesturesKeepLayoutStable() {
        let viewModel = GraphViewModel(graph: GraphFixture.spike)
        let originalPositions = viewModel.graph.nodes.map(\.position)

        viewModel.pan(by: CGSize(width: 80, height: 40))
        viewModel.zoom(by: 1.5)

        #expect(viewModel.graph.nodes.map(\.position) == originalPositions)
    }
}
