import SwiftUI

struct CompactWealthCard: View {
    let wealth: DossierWealth
    let formattedAmount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("СОСТОЯНИЕ").font(.caption2.bold()).tracking(1).foregroundStyle(blue)
            Text(formattedAmount).font(.system(.title2, design: .rounded, weight: .bold))
            Text("на \(wealth.asOf)").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [blue.opacity(0.2), .cyan.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

struct CompactPersonCloudGroups: View {
    let companies: [DossierEntityLink]
    let universities: [DossierEntityLink]
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            cloudGroup(title: "Компании", tint: amber) {
                ForEach(companies) { company in
                    companyButton(company)
                }
            }
            cloudGroup(title: "Вузы", tint: purple) {
                ForEach(universities) { university in
                    universityButton(university)
                }
            }
        }
    }

    private func cloudGroup<Content: View>(
        title: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 7, height: 7)
                Text(title.uppercased()).font(.caption2.bold()).tracking(0.9)
            }
            .foregroundStyle(tint)
            .padding(.leading, 3)
            FlowLayout(spacing: 7) { content() }
        }
    }

    private func companyButton(_ company: DossierEntityLink) -> some View {
        Button {
            if let entityID = company.entityID { onNavigate(entityID) }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(company.isCurrent ? Color.green : Color.secondary.opacity(0.55))
                    .frame(width: 6, height: 6)
                Text(company.name).lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(amber.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(amber.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .disabled(company.entityID == nil)
    }

    private func universityButton(_ university: DossierEntityLink) -> some View {
        Button(university.name) {
            if let entityID = university.entityID { onNavigate(entityID) }
        }
        .font(.caption.bold())
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            LinearGradient(
                colors: [purple.opacity(0.2), purple.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay(Capsule().stroke(purple.opacity(0.16)))
        .disabled(university.entityID == nil)
    }

    private var purple: Color { Asset.Colors.chapterViolet.swiftUIColor }
    private var amber: Color { Asset.Colors.chapterAmber.swiftUIColor }
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
