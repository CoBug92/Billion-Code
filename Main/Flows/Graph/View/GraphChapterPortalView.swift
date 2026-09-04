import SwiftUI

struct GraphChapterPortalView: View {
    let chapter: GraphChapter
    let direction: Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Margin.x2) {
                if direction == .previous {
                    Image(systemName: AppSymbols.previous)
                }
                Text(chapter.title.uppercased())
                    .font(.caption2.bold())
                    .tracking(1.4)
                    .lineLimit(1)
                if direction == .next {
                    Image(systemName: AppSymbols.next)
                }
            }
            .foregroundStyle(chapter.accentColor)
            .padding(.horizontal, Margin.x4)
            .frame(minHeight: .minimumTouchTarget)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            direction == .previous
                ? L10n.Graph.Chapter.previous(chapter.title)
                : L10n.Graph.Chapter.next(chapter.title)
        )
    }
}

extension GraphChapterPortalView {
    enum Direction {
        case previous
        case next
    }
}

private extension CGFloat {
    static let minimumTouchTarget = 44.0
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    GraphChapterPortalView(
        chapter: GraphAtlasFixture.editorial.chapters[1],
        direction: .next,
        action: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
