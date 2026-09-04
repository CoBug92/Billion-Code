import SwiftUI

struct CompactWealthCard: View {
    let wealth: DossierWealth
    let formattedAmount: String
    let onOpenSource: (DossierSource) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("СОСТОЯНИЕ")
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(Asset.Colors.chapterBlue.swiftUIColor)
                Text(formattedAmount)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("на \(wealth.asOf)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { onOpenSource(wealth.source) } label: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(Asset.Colors.chapterBlue.swiftUIColor)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background(
            LinearGradient(
                colors: [Asset.Colors.chapterBlue.swiftUIColor.opacity(0.2), .cyan.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}

struct CompactOrganizationCloud: View {
    let activity: String
    let founders: [DossierEntityLink]
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(activity, systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Asset.Colors.chapterAmber.swiftUIColor.opacity(0.18),
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 22,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 22,
                        topTrailingRadius: 12
                    )
                )
            if !founders.isEmpty {
                cloudLabel("Соучредители", links: founders)
            }
        }
    }

    private func cloudLabel(_ title: String, links: [DossierEntityLink]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased()).font(.caption2.bold()).tracking(0.8)
            FlowLayout(spacing: 7) {
                ForEach(links) { link in
                    Button(link.name) {
                        if let entityID = link.entityID { onNavigate(entityID) }
                    }
                    .font(.caption.bold())
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(height: 31)
                    .background(.white.opacity(0.52), in: Capsule())
                }
            }
        }
        .foregroundStyle(Asset.Colors.chapterBlue.swiftUIColor)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Asset.Colors.chapterBlue.swiftUIColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 24))
    }
}

struct CompactUniversityCloud: View {
    let type: String
    let location: String
    let alumni: [DossierEntityLink]
    let variant: UniversityCloudVariant
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            universityBubble
            if !alumni.isEmpty { alumniBubble }
        }
    }

    @ViewBuilder
    private var universityBubble: some View {
        switch variant {
        case .soft:
            VStack(alignment: .leading, spacing: 5) { cloudText }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(purple.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        case .orbit:
            HStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.5), in: Circle())
                VStack(alignment: .leading, spacing: 5) { cloudText }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(purple.opacity(0.2), in: Capsule())
        case .stacked:
            VStack(alignment: .leading, spacing: 0) {
                Text(type).font(.headline).padding(.horizontal, 15).frame(minHeight: 44)
                    .background(purple.opacity(0.25), in: Capsule())
                Text(location).font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 15).padding(.vertical, 9)
                    .background(purple.opacity(0.1), in: Capsule()).offset(x: 28, y: -4)
            }
        }
    }

    private var cloudText: some View {
        Group {
            Text(type).font(.headline)
            Text(location).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var alumniBubble: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ВЫПУСКНИКИ В ГРАФЕ").font(.caption2.bold()).tracking(0.8)
            FlowLayout(spacing: 7) {
                ForEach(alumni.prefix(4)) { link in
                    Button(link.name) {
                        if let entityID = link.entityID { onNavigate(entityID) }
                    }
                    .font(.caption.bold()).buttonStyle(.plain)
                    .padding(.horizontal, 10).frame(height: 31)
                    .background(.white.opacity(0.52), in: Capsule())
                }
            }
        }
        .foregroundStyle(Asset.Colors.chapterBlue.swiftUIColor)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Asset.Colors.chapterBlue.swiftUIColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 24))
    }

    private var purple: Color { Asset.Colors.chapterViolet.swiftUIColor }
}

enum UniversityCloudVariant: Int, CaseIterable {
    case soft = 1
    case orbit
    case stacked
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? 320
        var cursor = CGPoint.zero
        var rowHeight = CGFloat.zero
        var points: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if cursor.x > 0, cursor.x + size.width > width {
                cursor.x = 0
                cursor.y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(cursor)
            cursor.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: cursor.y + rowHeight), points)
    }
}
