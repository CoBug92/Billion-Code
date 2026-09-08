import SwiftUI

@main
struct BillionCodeApp: App {
    var body: some Scene {
        WindowGroup {
            DenseGraphRootView(
                viewModel: Self.makeDenseGraphViewModel()
            )
        }
    }

    @MainActor
    private static func makeDenseGraphViewModel() -> DenseGraphViewModel {
        let viewModel = DenseGraphViewModel(graph: DenseGraphFixture.performance)
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-selectedNode"), arguments.indices.contains(flag + 1) {
            viewModel.selectNode(id: arguments[flag + 1])
        } else if arguments.contains("-dailyPerson") {
            viewModel.selectDailyPerson()
        }
#endif
        return viewModel
    }

    private static func makeContainerViewModel() -> GraphContainerViewModel {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let cache = FileContentCache(
            rootDirectory: applicationSupport.appendingPathComponent("BillionCode/Content", isDirectory: true)
        )
        let store = ContentStore(
            cache: cache,
            seedProvider: BundledSeedContentProvider(),
            validator: SpikeContentSnapshotValidator()
        )
        return GraphContainerViewModel(store: store)
    }
}
