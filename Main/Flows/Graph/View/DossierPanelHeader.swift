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
        HStack(spacing: 12) {
            if canNavigateBack { backButton }
            entityImage
            VStack(alignment: .leading, spacing: 3) {
                if let eyebrowText {
                    Text(eyebrowText.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(node.kind.denseGraphColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .allowsTightening(true)
                }
                Text(node.name)
                    .font(.system(node.kind == .person ? .title2 : .title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                if let metadataText {
                    Text(metadataText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            toggleButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [node.kind.denseGraphColor.opacity(0.14), .clear],
                startPoint: .topLeading,
                endPoint: .trailing
            )
        )
    }

    @ViewBuilder
    private var entityImage: some View {
        if node.kind == .person {
            PersonAvatarView(node: node, diameter: 58, accentColor: node.kind.denseGraphColor)
                .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 2))
                .shadow(color: node.kind.denseGraphColor.opacity(0.18), radius: 8, y: 3)
        } else {
            Image(systemName: node.kind.dossierSymbol)
                .font(.headline)
                .foregroundStyle(node.kind.denseGraphColor)
                .frame(width: 52, height: 52)
                .background(node.kind.denseGraphColor.opacity(0.14), in: Circle())
                .overlay(Circle().stroke(node.kind.denseGraphColor.opacity(0.28)))
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .frame(width: 44, height: 44)
                .background(.secondary.opacity(0.1), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Вернуться к предыдущей ноде")
    }

    private var toggleButton: some View {
        Button(action: onToggle) {
            Image(systemName: detent == .expanded ? "chevron.down" : "chevron.up")
                .frame(width: 44, height: 44)
                .background(.secondary.opacity(0.1), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(detent == .expanded ? "Свернуть досье" : "Развернуть досье")
    }
}
