import CoreGraphics
import Testing
@testable import BillionCode

@MainActor
@Suite("Graph atlas view model")
struct GraphViewModelTests {
    @Test("Atlas starts in its lead chapter with the featured person selected")
    func initialState() {
        let atlas = GraphAtlasFixture.editorial
        let viewModel = GraphViewModel(atlas: atlas)

        #expect(viewModel.activeChapterID == atlas.leadChapter.id)
        #expect(viewModel.selectedNodeID == atlas.featuredNodeID)
        #expect(viewModel.activeRoutes.allSatisfy { $0.connects(atlas.featuredNodeID) })
    }

    @Test("Selecting a person outside the active chapter opens their first chapter")
    func selectionMovesToContainingChapter() {
        let atlas = selectionFixture()
        let viewModel = GraphViewModel(atlas: atlas)

        viewModel.selectNode(id: "person:c")

        #expect(viewModel.activeChapterID == "organization:second")
        #expect(viewModel.selectedNodeID == "person:c")
    }

    @Test("Chapter selection falls back to its hero when selection is absent")
    func chapterSelectionUsesHeroFallback() {
        let atlas = selectionFixture()
        let viewModel = GraphViewModel(atlas: atlas)

        viewModel.selectChapter(id: "organization:second")

        #expect(viewModel.selectedNodeID == "person:c")
    }

    @Test("Temporary magnification is clamped and resets")
    func magnification() {
        let viewModel = GraphViewModel(atlas: GraphAtlasFixture.editorial)

        viewModel.updateMagnification(1.8)
        #expect(viewModel.magnification == 1.35)
        viewModel.updateMagnification(0.7)
        #expect(viewModel.magnification == 1)
        viewModel.resetMagnification()
        #expect(viewModel.magnification == 1)
    }

    @Test("Only a dominant horizontal swipe on a collapsed panel changes chapter")
    func chapterSwipeGating() {
        let viewModel = GraphViewModel(atlas: GraphAtlasFixture.editorial)

        viewModel.handleChapterSwipe(
            translation: CGSize(width: -90, height: 16),
            predictedEndTranslation: CGSize(width: -140, height: 20),
            panelDetent: .medium
        )
        #expect(viewModel.activeChapterIndex == 0)

        viewModel.handleChapterSwipe(
            translation: CGSize(width: -50, height: 70),
            predictedEndTranslation: CGSize(width: -130, height: 90),
            panelDetent: .collapsed
        )
        #expect(viewModel.activeChapterIndex == 0)

        viewModel.handleChapterSwipe(
            translation: CGSize(width: -90, height: 16),
            predictedEndTranslation: CGSize(width: -140, height: 20),
            panelDetent: .collapsed
        )
        #expect(viewModel.activeChapterIndex == 1)
    }

    @Test("Pinch state blocks chapter swipe until the gesture finishes")
    func pinchBlocksSwipe() {
        let viewModel = GraphViewModel(atlas: GraphAtlasFixture.editorial)
        viewModel.updateMagnification(1.2)
        viewModel.resetMagnification()

        viewModel.handleChapterSwipe(
            translation: CGSize(width: -90, height: 10),
            predictedEndTranslation: CGSize(width: -140, height: 12),
            panelDetent: .collapsed
        )
        #expect(viewModel.activeChapterIndex == 0)

        viewModel.finishMagnificationGesture()
        viewModel.handleChapterSwipe(
            translation: CGSize(width: -90, height: 10),
            predictedEndTranslation: CGSize(width: -140, height: 12),
            panelDetent: .collapsed
        )
        #expect(viewModel.activeChapterIndex == 1)
    }

    private func selectionFixture() -> GraphAtlas {
        let nodes = ["person:a", "person:b", "person:c"].map {
            GraphNode(
                id: $0,
                kind: .person,
                name: $0,
                shortName: $0,
                summary: "",
                portrait: nil,
                position: GraphPoint(x: 0, y: 0)
            )
        }
        return GraphAtlas(
            featuredNodeID: "person:a",
            nodes: nodes,
            chapters: [
                GraphChapter(
                    id: "organization:first",
                    title: "First",
                    heroNodeID: "person:a",
                    memberIDs: ["person:a", "person:b"],
                    routes: [],
                    accentIndex: 0
                ),
                GraphChapter(
                    id: "organization:second",
                    title: "Second",
                    heroNodeID: "person:c",
                    memberIDs: ["person:c"],
                    routes: [],
                    accentIndex: 1
                )
            ],
            relationships: [],
            sources: [],
            layoutVersion: 1
        )
    }
}
