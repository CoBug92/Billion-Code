import SwiftUI

struct DenseGraphSearchResultIcon: View {
    let node: GraphNode

    var body: some View {
        Group {
            if node.kind == .person {
                PersonAvatarView(
                    node: node,
                    diameter: .iconDiameter,
                    accentColor: node.kind.denseGraphColor
                )
            } else {
                Circle()
                    .fill(node.kind.denseGraphColor)
                    .frame(
                        width: .markerDiameter,
                        height: .markerDiameter
                    )
                    .frame(
                        width: .iconDiameter,
                        height: .iconDiameter
                    )
            }
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let iconDiameter = 30.0
    static let markerDiameter = 8.0
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    DenseGraphSearchResultIcon(node: GraphAtlasFixture.editorial.nodes[0])
        .padding()
}
