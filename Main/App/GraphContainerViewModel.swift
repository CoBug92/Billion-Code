import Foundation
import Observation

@MainActor
@Observable
final class GraphContainerViewModel {
    private(set) var atlas: GraphAtlas?
    private(set) var didFail = false

    private let store: ContentStore
    private let projector: GraphAtlasProjector
    private let configuration: GraphAtlasConfiguration

    init(
        store: ContentStore,
        projector: GraphAtlasProjector = GraphAtlasProjector(),
        configuration: GraphAtlasConfiguration = .muskDesignSpike
    ) {
        self.store = store
        self.projector = projector
        self.configuration = configuration
    }

    func load() async {
        guard atlas == nil, !didFail else { return }
        let state = await store.bootstrap()
        guard let snapshot = state.snapshot else {
            didFail = true
            return
        }

        do {
            atlas = try projector.project(
                snapshot: snapshot,
                editionID: snapshot.fallbackEditionID,
                configuration: configuration
            )
        } catch {
            didFail = true
        }
    }
}
