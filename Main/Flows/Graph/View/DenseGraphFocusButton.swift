import SwiftUI

struct DenseGraphFocusButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isActive ? L10n.Graph.Focus.showAll : L10n.Graph.Focus.local)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(
                    Asset.Colors.surfacePrimary.swiftUIColor.opacity(0.96),
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(
                        Asset.Colors.chapterBlue.swiftUIColor.opacity(isActive ? 0.7 : 0.38)
                    )
                )
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .leading)))
    }
}

// MARK: - Preview

#Preview("Focus actions", traits: .sizeThatFitsLayout) {
    VStack {
        DenseGraphFocusButton(isActive: false, action: {})
        DenseGraphFocusButton(isActive: true, action: {})
    }
    .padding()
    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
}
