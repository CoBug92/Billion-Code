import SwiftUI

struct GraphContainerView: View {
    @State private var viewModel: GraphContainerViewModel

    init(viewModel: GraphContainerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let atlas = viewModel.atlas {
                GraphView(viewModel: GraphViewModel(atlas: atlas))
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
