import SwiftUI
import UIKit

struct PersonAvatarView: View {
    let node: GraphNode
    let diameter: CGFloat

    var body: some View {
        Group {
            if let image = portraitImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: AppSymbols.person)
                    .resizable()
                    .scaledToFit()
                    .padding(diameter * .fallbackInsetRatio)
                    .foregroundStyle(.secondary)
                    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
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
}

private extension CGFloat {
    static let fallbackInsetRatio = 0.26
}
