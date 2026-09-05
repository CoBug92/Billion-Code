import SwiftUI

struct DossierPanelHeader: View {
    let node: GraphNode
    let eyebrowText: String?
    let metadataText: String?
    let detent: DenseDossierDetent
    let canNavigateBack: Bool
    let onBack: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(.secondary.opacity(0.38))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            HStack(spacing: 12) {
                if canNavigateBack { backButton }
                entityImage
                VStack(alignment: .leading, spacing: 3) {
                    if let eyebrowText {
                        Text(eyebrowText.uppercased())
                            .font(.caption2.bold())
                            .tracking(1.1)
                            .foregroundStyle(node.kind.denseGraphColor)
                            .lineLimit(1)
                    }
                    Text(node.name)
                        .font(node.kind == .person ? .title.bold() : .title2.bold())
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .lineLimit(2)
                    if let metadataText {
                        Text(metadataText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                toggleButton
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 7)
        }
        .background(
            LinearGradient(
                colors: [node.kind.denseGraphColor.opacity(0.16), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private var entityImage: some View {
        if node.kind == .person {
            PersonAvatarView(node: node, diameter: 56, accentColor: node.kind.denseGraphColor)
                .overlay(Circle().stroke(node.kind.denseGraphColor.opacity(0.32), lineWidth: 2))
        } else {
            Image(systemName: node.kind.dossierSymbol)
                .font(.headline)
                .foregroundStyle(node.kind.denseGraphColor)
                .frame(width: 48, height: 48)
                .background(node.kind.denseGraphColor.opacity(0.14), in: Circle())
                .overlay(Circle().stroke(node.kind.denseGraphColor.opacity(0.28)))
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .frame(width: 44, height: 44)
                .background(.secondary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Вернуться к предыдущей ноде")
    }

    private var toggleButton: some View {
        Button(action: onToggle) {
            Image(systemName: detent == .expanded ? "chevron.down" : "chevron.up")
                .frame(width: 44, height: 44)
                .background(.secondary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detent == .expanded ? "Свернуть досье" : "Развернуть досье")
    }
}
