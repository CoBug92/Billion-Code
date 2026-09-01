import Foundation
import Observation

@MainActor
@Observable
final class GraphContainerViewModel {
    private(set) var graph: GraphData?
    private(set) var didFail = false

    private let store: ContentStore
    private let projector: GraphContentProjector

    init(
        store: ContentStore,
        projector: GraphContentProjector = GraphContentProjector()
    ) {
        self.store = store
        self.projector = projector
    }

    func load() async {
        guard graph == nil, !didFail else { return }
        let state = await store.bootstrap()
        guard let snapshot = state.snapshot else {
            didFail = true
            return
        }

        do {
            graph = try projector.project(
                snapshot: snapshot,
                editionID: snapshot.fallbackEditionID,
                displayMode: .peopleOnly
            )
        } catch {
            didFail = true
        }
    }
}
