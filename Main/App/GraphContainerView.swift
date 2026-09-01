import SwiftUI

struct GraphContainerView: View {
    @State private var viewModel: GraphContainerViewModel

    init(viewModel: GraphContainerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let graph = viewModel.graph {
                GraphView(viewModel: GraphViewModel(graph: graph))
            } else if viewModel.didFail {
                ContentUnavailableView(
                    L10n.Content.Error.title,
                    systemImage: AppSymbols.contentUnavailable,
                    description: Text(L10n.Content.Error.message)
                )
            } else {
                ProgressView(L10n.Content.loading)
            }
        }
        .task { await viewModel.load() }
    }
}
