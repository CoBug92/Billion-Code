import SwiftUI

struct GraphAtlasBackgroundView: View {
    let chapter: GraphChapter

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Asset.Colors.backgroundPrimary.swiftUIColor
            if colorScheme == .dark {
                Color.black.opacity(.darkOverlayOpacity)
            }
            glow
            title
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private extension GraphAtlasBackgroundView {
    var glow: some View {
        ZStack {
            Circle()
                .fill(chapter.accentColor.opacity(glowOpacity))
                .frame(width: .primaryGlowSize, height: .primaryGlowSize)
                .blur(radius: .primaryBlurRadius)
                .offset(x: -.primaryGlowOffsetX, y: -.primaryGlowOffsetY)
            Circle()
                .fill(chapter.accentColor.opacity(glowOpacity * 0.65))
                .frame(width: .secondaryGlowSize, height: .secondaryGlowSize)
                .blur(radius: .secondaryBlurRadius)
                .offset(x: .secondaryGlowOffsetX, y: .secondaryGlowOffsetY)
        }
    }

    var title: some View {
        Text(chapter.title.uppercased())
            .font(
                .system(
                    size: .chapterTitleSize,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(-3)
            .lineLimit(1)
            .minimumScaleFactor(.chapterTitleScale)
            .foregroundStyle(chapter.accentColor.opacity(titleOpacity))
            .padding(.horizontal, Margin.x8)
            .offset(y: -.chapterTitleOffsetY)
    }

    var glowOpacity: Double {
        colorScheme == .dark ? .darkGlowOpacity : .lightGlowOpacity
    }

    var titleOpacity: Double {
        colorScheme == .dark ? .darkTitleOpacity : .lightTitleOpacity
    }
}

private extension CGFloat {
    static let chapterTitleOffsetY = 82.0
    static let chapterTitleScale = 0.54
    static let chapterTitleSize = 78.0
    static let primaryBlurRadius = 68.0
    static let primaryGlowOffsetX = 88.0
    static let primaryGlowOffsetY = 110.0
    static let primaryGlowSize = 360.0
    static let secondaryBlurRadius = 54.0
    static let secondaryGlowOffsetX = 150.0
    static let secondaryGlowOffsetY = 210.0
    static let secondaryGlowSize = 260.0
}

private extension Double {
    static let darkGlowOpacity = 0.28
    static let darkOverlayOpacity = 0.46
    static let darkTitleOpacity = 0.13
    static let lightGlowOpacity = 0.13
    static let lightTitleOpacity = 0.09
}

// MARK: - Preview

#Preview("Dark") {
    GraphAtlasBackgroundView(chapter: GraphAtlasFixture.editorial.chapters[0])
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    GraphAtlasBackgroundView(chapter: GraphAtlasFixture.editorial.chapters[1])
        .preferredColorScheme(.light)
}
