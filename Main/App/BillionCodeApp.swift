import SwiftUI

@main
struct BillionCodeApp: App {
    var body: some Scene {
        WindowGroup {
            GraphContainerView(viewModel: Self.makeContainerViewModel())
        }
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
