import CoreGraphics
import Foundation
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
            #expect(viewModel.shouldShowLabel(for: straubel))
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

    @Test("Daily person selection is stable per day and not fixed to Elon Musk")
    func dailyPersonSelection() {
        let calendar = Calendar(identifier: .gregorian)
        guard
            let today = DateComponents(calendar: calendar, year: 2026, month: 9, day: 8).date,
            let tomorrow = DateComponents(calendar: calendar, year: 2026, month: 9, day: 9).date
        else {
            Issue.record("Test dates could not be created")
            return
        }
        let first = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let second = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let nextDay = DenseGraphViewModel(graph: DenseGraphFixture.performance)

        first.selectDailyPerson(on: today, calendar: calendar)
        second.selectDailyPerson(on: today, calendar: calendar)
        nextDay.selectDailyPerson(on: tomorrow, calendar: calendar)

        #expect(first.selectedNodeID == second.selectedNodeID)
        #expect(first.selectedNode?.kind == .person)
        #expect(nextDay.selectedNode?.kind == .person)
        #expect(first.selectedNodeID != "person:elon-musk")
    }

    @Test("Dossier navigation keeps the selected node above the compact panel")
    func dossierNavigationFocusesVisibleGraphArea() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let viewport = CGSize(width: 390, height: 844)
        let visibleGraphFrame = CGRect(x: 0, y: 59, width: 390, height: 312)
        viewModel.selectNode(id: "person:elon-musk")

        viewModel.navigate(
            to: "organization:tesla",
            viewport: viewport,
            visibleGraphFrame: visibleGraphFrame
        )

        guard let selectedNode = viewModel.selectedNode else {
            Issue.record("Selected fixture node is missing")
            return
        }
        let selectedNodeScreenPoint = viewModel.camera.screenPoint(for: selectedNode.position, viewport: viewport)
        #expect(visibleGraphFrame.contains(selectedNodeScreenPoint))
    }

    @Test("Dossier navigation reveals hidden node kinds")
    func dossierNavigationRevealsHiddenKinds() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        viewModel.setNodeKind(.organization, isVisible: false)

        viewModel.navigate(to: "organization:tesla")

        #expect(viewModel.selectedNodeID == "organization:tesla")
        #expect(viewModel.isNodeKindVisible(.organization))
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

    @Test("Node filters hide nodes and their edges")
    func nodeKindFilters() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let viewport = CGSize(width: 10_000, height: 10_000)

        viewModel.setNodeKind(.person, isVisible: false)

        #expect(!viewModel.visibleNodes(in: viewport).contains { $0.kind == .person })
        #expect(!viewModel.graph.edges.contains { edge in
            viewModel.isEdgeVisible(edge)
                && (viewModel.graph.node(id: edge.sourceID)?.kind == .person
                    || viewModel.graph.node(id: edge.targetID)?.kind == .person)
        })
    }

    @Test("Render frame contains only edges connected to viewport nodes")
    func renderFrameCullsOffscreenEdges() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        var camera = viewModel.camera
        camera.zoom(by: 100)
        viewModel.updateCamera(camera)

        let frame = viewModel.renderFrame(in: CGSize(width: 390, height: 844))
        let visibleNodeIDs = Set(frame.nodes.map(\.id))

        #expect(frame.nodes.count < viewModel.graph.nodes.count)
        #expect(frame.edges.allSatisfy { edge in
            visibleNodeIDs.contains(edge.sourceID) || visibleNodeIDs.contains(edge.targetID)
        })
    }

    @Test("Panning during magnification preserves the current zoom")
    func panPreservesCurrentZoom() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let initialCamera = viewModel.camera
        var zoomedCamera = initialCamera
        zoomedCamera.zoom(by: 2)
        viewModel.updateCamera(zoomedCamera)

        viewModel.panCamera(from: initialCamera, by: CGSize(width: 80, height: -40))

        #expect(viewModel.camera.scale == zoomedCamera.scale)
        #expect(viewModel.camera.center != initialCamera.center)
    }

    @Test("Local focus keeps its anchor and isolates the selected neighborhood")
    func localFocusIsolatesNeighborhood() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        guard let selectedNode = viewModel.selectedNode else {
            Issue.record("Selected fixture node is missing")
            return
        }

        viewModel.enterLocalFocus()

        let frame = viewModel.renderFrame(in: CGSize(width: 100_000, height: 100_000))
        let renderedNodeIDs = Set(frame.nodes.map(\.id))
        #expect(viewModel.isLocalFocusActive)
        #expect(viewModel.displayPosition(for: selectedNode) == selectedNode.position)
        #expect(renderedNodeIDs.isSubset(of: viewModel.highlightedNodeIDs))
        #expect(renderedNodeIDs.count <= 20)
        #expect(frame.edges.allSatisfy { edge in
            renderedNodeIDs.contains(edge.sourceID) && renderedNodeIDs.contains(edge.targetID)
        })
    }

    @Test("Local focus fits its neighborhood into the visible graph area")
    func localFocusFitsVisibleGraphArea() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let viewport = CGSize(width: 390, height: 844)
        let visibleGraphFrame = CGRect(x: 0, y: 59, width: 390, height: 312)
        viewModel.selectNode(id: "person:elon-musk")

        viewModel.enterLocalFocus(viewport: viewport, visibleGraphFrame: visibleGraphFrame)

        let localFrame = viewModel.renderFrame(in: CGSize(width: 100_000, height: 100_000))
        let fittedFrame = visibleGraphFrame.insetBy(dx: -1, dy: -1)
        #expect(!localFrame.nodes.isEmpty)
        #expect(localFrame.nodes.allSatisfy { node in
            let point = viewModel.camera.screenPoint(
                for: viewModel.displayPosition(for: node),
                viewport: viewport
            )
            return fittedFrame.contains(point)
        })
    }

    @Test("Local focus keeps all of its edges at high zoom")
    func localFocusDoesNotCullEdgesByEndpoints() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        viewModel.enterLocalFocus()
        var camera = viewModel.camera
        camera.zoom(by: 100)
        viewModel.updateCamera(camera)

        let frame = viewModel.renderFrame(in: CGSize(width: 1, height: 1))
        let expectedEdges = viewModel.graph.edges.filter(viewModel.isEdgeVisible)

        #expect(frame.edges.count == expectedEdges.count)
        #expect(!frame.edges.isEmpty)
    }

    @Test("Local focus pan reaches every laid out node")
    func localFocusUsesLayoutPanBounds() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        viewModel.enterLocalFocus()
        let frame = viewModel.renderFrame(in: CGSize(width: 100_000, height: 100_000))
        let positions = frame.nodes.map(viewModel.displayPosition)
        guard
            let minimumX = positions.map(\.x).min(),
            let maximumX = positions.map(\.x).max(),
            let minimumY = positions.map(\.y).min(),
            let maximumY = positions.map(\.y).max()
        else {
            Issue.record("Local focus positions are missing")
            return
        }
        let initialCamera = viewModel.camera

        viewModel.panCamera(
            from: initialCamera,
            by: CGSize(width: 1_000_000, height: 1_000_000)
        )
        #expect(viewModel.camera.center == GraphPoint(x: minimumX - 800, y: minimumY - 800))

        viewModel.panCamera(
            from: initialCamera,
            by: CGSize(width: -1_000_000, height: -1_000_000)
        )
        #expect(viewModel.camera.center == GraphPoint(x: maximumX + 800, y: maximumY + 800))
    }

    @Test("Selecting a node inside local focus keeps its focused position")
    func localFocusSelectionKeepsAnchor() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        viewModel.enterLocalFocus()
        guard let tesla = viewModel.node(id: "organization:tesla") else {
            Issue.record("Tesla fixture node is missing")
            return
        }
        let focusedPosition = viewModel.displayPosition(for: tesla)

        viewModel.selectNode(id: tesla.id)

        #expect(viewModel.isLocalFocusActive)
        #expect(viewModel.selectedNodeID == tesla.id)
        #expect(viewModel.displayPosition(for: tesla) == focusedPosition)
    }

    @Test("Selecting a node outside local focus returns to the overview")
    func externalLocalFocusSelectionReturnsToOverview() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        let overviewCamera = viewModel.camera
        viewModel.enterLocalFocus()

        viewModel.selectNode(id: "person:jeff-bezos")

        #expect(!viewModel.isLocalFocusActive)
        #expect(viewModel.selectedNodeID == "person:jeff-bezos")
        #expect(viewModel.camera == overviewCamera)
    }

    @Test("Leaving local focus restores the overview camera and positions")
    func localFocusExitRestoresOverview() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")
        let overviewCamera = viewModel.camera
        guard let tesla = viewModel.node(id: "organization:tesla") else {
            Issue.record("Tesla fixture node is missing")
            return
        }

        viewModel.enterLocalFocus()
        var movedCamera = viewModel.camera
        movedCamera.pan(by: CGSize(width: 120, height: -80))
        viewModel.updateCamera(movedCamera)
        viewModel.exitLocalFocus()

        #expect(!viewModel.isLocalFocusActive)
        #expect(viewModel.camera == overviewCamera)
        #expect(viewModel.displayPosition(for: tesla) == tesla.position)
    }

    @Test("Hiding the selected node kind clears selection")
    func hidingSelectedKindClearsSelection() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        viewModel.selectNode(id: "person:elon-musk")

        viewModel.setNodeKind(.person, isVisible: false)

        #expect(viewModel.selectedNodeID == nil)
    }

    @Test("Search respects node filters")
    func searchRespectsFilters() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)

        #expect(viewModel.searchResults(matching: "Tesla").contains { $0.id == "organization:tesla" })

        viewModel.setNodeKind(.organization, isVisible: false)

        #expect(viewModel.searchResults(matching: "Tesla").isEmpty)
    }
}
