import CoreGraphics
import Observation

@MainActor
@Observable
final class GraphViewModel {

    // MARK: - Properties

    let atlas: GraphAtlas
    private(set) var activeChapterID: GraphChapter.ID
    private(set) var selectedNodeID: GraphNode.ID
    private(set) var magnification = 1.0
    private(set) var isMagnifying = false

    // MARK: - Init

    init(atlas: GraphAtlas) {
        precondition(!atlas.chapters.isEmpty, "The graph atlas must contain at least one chapter")
        precondition(atlas.nodes.count <= 40, "The graph atlas supports at most 40 people")
        self.atlas = atlas
        activeChapterID = atlas.leadChapter.id
        selectedNodeID = atlas.featuredNodeID
    }

    // MARK: - Computed properties

    var activeChapter: GraphChapter {
        atlas.chapter(id: activeChapterID) ?? atlas.leadChapter
    }

    var activeChapterIndex: Int {
        atlas.chapters.firstIndex { $0.id == activeChapterID } ?? .zero
    }

    var activeNodes: [GraphNode] {
        activeChapter.memberIDs.compactMap(atlas.node(id:))
    }

    var activeRoutes: [GraphRoute] {
        activeChapter.routes.filter { $0.connects(selectedNodeID) }
    }

    var selectedNode: GraphNode {
        atlas.node(id: selectedNodeID) ?? atlas.node(id: atlas.featuredNodeID) ?? atlas.nodes[0]
    }

    var selectedRelationships: [GraphRelationship] {
        let active = activeRoutes.map(\.relationship)
        let activeIDs = Set(active.map(\.id))
        let remaining = atlas.relationships(for: selectedNodeID).filter { !activeIDs.contains($0.id) }
        return active + remaining
    }

    var people: [GraphNode] {
        atlas.nodes
    }

    var previousChapter: GraphChapter? {
        guard activeChapterIndex > atlas.chapters.startIndex else { return nil }
        return atlas.chapters[atlas.chapters.index(before: activeChapterIndex)]
    }

    var nextChapter: GraphChapter? {
        let index = atlas.chapters.index(after: activeChapterIndex)
        guard index < atlas.chapters.endIndex else { return nil }
        return atlas.chapters[index]
    }

    // MARK: - Public methods

    func selectNode(id: GraphNode.ID) {
        guard atlas.node(id: id) != nil else { return }
        if !activeChapter.contains(id), let chapter = atlas.firstChapter(containing: id) {
            activeChapterID = chapter.id
        }
        selectedNodeID = id
        magnification = 1
    }

    func selectChapter(id: GraphChapter.ID) {
        guard let chapter = atlas.chapter(id: id) else { return }
        activeChapterID = chapter.id
        if !chapter.contains(selectedNodeID) {
            selectedNodeID = chapter.heroNodeID
        }
        magnification = 1
    }

    func selectNextChapter() {
        guard let nextChapter else { return }
        selectChapter(id: nextChapter.id)
    }

    func selectPreviousChapter() {
        guard let previousChapter else { return }
        selectChapter(id: previousChapter.id)
    }

    func updateMagnification(_ value: Double) {
        isMagnifying = true
        magnification = min(max(value, 1), 1.35)
    }

    func resetMagnification() {
        magnification = 1
    }

    func finishMagnificationGesture() {
        isMagnifying = false
    }

    func handleChapterSwipe(
        translation: CGSize,
        predictedEndTranslation: CGSize,
        panelDetent: GraphPanelDetent
    ) {
        guard
            panelDetent == .collapsed,
            !isMagnifying,
            magnification == 1,
            abs(translation.width) > abs(translation.height) * 1.2,
            abs(predictedEndTranslation.width) >= 64
        else { return }

        if predictedEndTranslation.width < 0 {
            selectNextChapter()
        } else {
            selectPreviousChapter()
        }
    }

    func node(opposite relationship: GraphRelationship, from nodeID: GraphNode.ID) -> GraphNode? {
        let otherID = relationship.sourceID == nodeID ? relationship.targetID : relationship.sourceID
        return atlas.node(id: otherID)
    }
}
