import SwiftUI
import UIKit

struct PersonAvatarView: View {
    let node: GraphNode
    let diameter: CGFloat
    var accentColor = Asset.Colors.accentColor.swiftUIColor

    var body: some View {
        Group {
            if let image = portraitImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(.gradientEndOpacity)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(initials)
                        .font(
                            .system(
                                size: diameter * .monogramSizeRatio,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var portraitImage: Image? {
        guard
            let resource = node.portrait?.bundledResource,
            let url = Bundle.main.url(forResource: resource, withExtension: nil),
            let image = UIImage(contentsOfFile: url.path)
        else { return nil }
        return Image(uiImage: image)
    }

    private var initials: String {
        let words = node.name.split(separator: " ")
        return words.prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

private extension Double {
    static let gradientEndOpacity = 0.58
}

private extension CGFloat {
    static let monogramSizeRatio = 0.3
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    PersonAvatarView(
        node: GraphAtlasFixture.editorial.nodes[0],
        diameter: 92,
        accentColor: Asset.Colors.chapterCoral.swiftUIColor
    )
    .padding()
}
