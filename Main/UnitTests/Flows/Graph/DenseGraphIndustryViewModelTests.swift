import CoreGraphics
import Testing
@testable import BillionCode

@MainActor
@Suite("Dense graph industries")
struct DenseGraphIndustryViewModelTests {
    @Test("Overview uses the lightweight canvas layer")
    func overviewRenderingAvoidsInteractiveNodes() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)

        let frame = viewModel.renderFrame(in: CGSize(width: 390, height: 844))

        #expect(viewModel.usesOverviewRendering)
        #expect(viewModel.showsOverviewSections)
        #expect(viewModel.overviewMemberships.count >= 1_400)
        #expect(frame.nodes.isEmpty)
        #expect(frame.edges.isEmpty)
    }

    @Test("Selecting a section enters interactive detail")
    func sectionSelectionZoomsToDetail() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let viewport = CGSize(width: 390, height: 844)
        let visibleGraphFrame = CGRect(x: 0, y: 59, width: 390, height: 785)
        guard let section = viewModel.graph.sections.first else {
            Issue.record("Industry sections are missing")
            return
        }

        viewModel.focus(
            on: section,
            viewport: viewport,
            visibleGraphFrame: visibleGraphFrame
        )

        let sectionCenter = viewModel.camera.screenPoint(
            for: section.region.center,
            viewport: viewport
        )
        let frame = viewModel.renderFrame(in: viewport)
        #expect(!viewModel.usesOverviewRendering)
        #expect(visibleGraphFrame.contains(sectionCenter))
        #expect(!frame.nodes.isEmpty)
        #expect(frame.nodes.allSatisfy { $0.kind == .person })
        #expect(frame.nodes.allSatisfy {
            viewModel.graph.personSectionIDs[$0.id, default: []].contains(section.id)
        })
        #expect(frame.edges.isEmpty)
    }

    @Test("Dossier back navigation restores industry context")
    func dossierBackRestoresIndustryContext() {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
        let viewport = CGSize(width: 390, height: 844)
        let visibleGraphFrame = CGRect(x: 0, y: 59, width: 390, height: 785)
        guard
            let technology = viewModel.graph.section(id: "technology"),
            let musk = viewModel.graph.node(id: "person:elon-musk")
        else {
            Issue.record("Technology section or Elon Musk is missing")
            return
        }
        viewModel.focus(on: technology, viewport: viewport, visibleGraphFrame: visibleGraphFrame)
        viewModel.selectNode(id: musk.id)
        let sectionPosition = viewModel.displayPosition(for: musk)

        viewModel.navigate(to: "organization:tesla", viewport: viewport, visibleGraphFrame: visibleGraphFrame)
        viewModel.navigateBack()

        #expect(viewModel.focusedSectionID == technology.id)
        #expect(viewModel.selectedNodeID == musk.id)
        #expect(viewModel.displayPosition(for: musk) == sectionPosition)
    }
}
