import SwiftUI

struct CompactWealthCard: View {
    let wealth: DossierWealth
    let formattedAmount: String
    let variant: WealthCardVariant
    let onOpenSource: (DossierSource) -> Void

    @ViewBuilder
    var body: some View {
        switch variant {
        case .gradient:
            gradientCard
        case .ticker:
            tickerCard
        case .orb:
            orbCard
        }
    }

    private var gradientCard: some View {
        HStack(spacing: 12) {
            amountBlock
            Spacer()
            sourceButton(icon: "chart.line.uptrend.xyaxis")
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

    private var tickerCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("КАПИТАЛ").font(.caption2.bold()).tracking(1)
                Text(formattedAmount).font(.system(.title2, design: .rounded, weight: .black))
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(blue, in: UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22))
            .foregroundStyle(.white)
            VStack(spacing: 4) {
                sourceButton(icon: "arrow.up.right")
                Text(wealth.asOf).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
            }
            .frame(width: 88)
            .frame(minHeight: 72)
            .background(blue.opacity(0.11), in: UnevenRoundedRectangle(bottomTrailingRadius: 22, topTrailingRadius: 22))
        }
    }

    private var orbCard: some View {
        HStack(spacing: 13) {
            Image(systemName: "dollarsign")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(blue.gradient, in: Circle())
            amountBlock
            Spacer(minLength: 4)
            sourceButton(icon: "info")
        }
        .padding(10)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(blue.opacity(0.18)))
    }

    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("СОСТОЯНИЕ").font(.caption2.bold()).tracking(1).foregroundStyle(blue)
            Text(formattedAmount).font(.system(.title2, design: .rounded, weight: .bold))
            Text("на \(wealth.asOf)").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func sourceButton(icon: String) -> some View {
        Button { onOpenSource(wealth.source) } label: {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(blue)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.6), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

enum WealthCardVariant: Int, CaseIterable {
    case gradient = 1
    case ticker
    case orb
}

struct CompactPersonUniversityCloud: View {
    let universities: [DossierEntityLink]
    let variant: PersonUniversityCloudVariant
    let onNavigate: (GraphNode.ID) -> Void

    @ViewBuilder
    var body: some View {
        switch variant {
        case .cloud:
            cloud
        case .campus:
            campus
        case .stack:
            stack
        }
    }

    private var cloud: some View {
        VStack(alignment: .leading, spacing: 7) {
            title
            FlowLayout(spacing: 7) { universityButtons }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            purple.opacity(0.17),
            in: UnevenRoundedRectangle(
                topLeadingRadius: 27,
                bottomLeadingRadius: 15,
                bottomTrailingRadius: 28,
                topTrailingRadius: 16
            )
        )
    }

    private var campus: some View {
        HStack(spacing: 11) {
            Image(systemName: "building.columns.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(purple.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                title
                FlowLayout(spacing: 6) { universityButtons }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(purple.opacity(0.13), in: Capsule())
    }

    private var stack: some View {
        VStack(alignment: .leading, spacing: 6) {
            title.padding(.leading, 4)
            FlowLayout(spacing: 6) {
                ForEach(Array(universities.enumerated()), id: \.element.id) { index, university in
                    universityButton(university)
                        .background(purple.opacity(index.isMultiple(of: 2) ? 0.24 : 0.14), in: Capsule())
                }
            }
        }
    }

    private var title: some View {
        Label("ОБРАЗОВАНИЕ", systemImage: "graduationcap.fill")
            .font(.caption2.bold())
            .tracking(0.8)
            .foregroundStyle(purple)
    }

    @ViewBuilder
    private var universityButtons: some View {
        ForEach(universities) { university in
            universityButton(university)
                .background(.white.opacity(0.58), in: Capsule())
        }
    }

    private func universityButton(_ university: DossierEntityLink) -> some View {
        Button(university.name) {
            if let entityID = university.entityID { onNavigate(entityID) }
        }
        .font(.caption.bold())
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .frame(height: 31)
    }

    private var purple: Color { Asset.Colors.chapterViolet.swiftUIColor }
}

enum PersonUniversityCloudVariant: Int, CaseIterable {
    case cloud = 1
    case campus
    case stack
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
