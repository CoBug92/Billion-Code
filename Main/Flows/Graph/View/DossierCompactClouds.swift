import SwiftUI

// MARK: - Person dossier

struct CompactWealthCard: View {
    let formattedAmount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("СОСТОЯНИЕ")
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.78))
            Text(formattedAmount)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(
            LinearGradient(
                colors: [blue.opacity(0.98), blue.opacity(0.76), teal.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.09))
                .frame(width: 96, height: 96)
                .offset(x: 26, y: -44)
                .allowsHitTesting(false)
        }
        .shadow(color: blue.opacity(0.2), radius: 16, y: 7)
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
    private var teal: Color { Asset.Colors.chapterTeal.swiftUIColor }
}

struct CompactPersonCloudGroups: View {
    let companies: [DossierEntityLink]
    let universities: [DossierEntityLink]
    let showsPastCompanies: Bool
    let usesFlowLayout: Bool
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !currentCompanies.isEmpty {
                DossierCloudSection(
                    title: L10n.Graph.Dossier.currentCompanies,
                    tint: amber,
                    links: currentCompanies,
                    style: .company,
                    usesFlowLayout: usesFlowLayout,
                    onNavigate: onNavigate
                )
            }
            if !universities.isEmpty {
                DossierCloudSection(
                    title: "Вузы",
                    tint: purple,
                    links: universities,
                    style: .university,
                    usesFlowLayout: usesFlowLayout,
                    onNavigate: onNavigate
                )
            }
            if showsPastCompanies, !pastCompanies.isEmpty {
                DossierCloudSection(
                    title: L10n.Graph.Dossier.pastCompanies,
                    tint: .secondary,
                    links: pastCompanies,
                    style: .pastCompany,
                    usesFlowLayout: usesFlowLayout,
                    onNavigate: onNavigate
                )
            }
        }
    }

    private var currentCompanies: [DossierEntityLink] { companies.filter(\.isCurrent) }
    private var pastCompanies: [DossierEntityLink] { companies.filter { !$0.isCurrent } }
    private var purple: Color { Asset.Colors.chapterViolet.swiftUIColor }
    private var amber: Color { Asset.Colors.chapterAmber.swiftUIColor }
}

// MARK: - Organization dossier

struct CompactOrganizationCloud: View {
    let activity: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title.uppercased(), systemImage: AppSymbols.sparkles)
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.76))
            Text(activity)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [amber.opacity(0.98), amber.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .shadow(color: amber.opacity(0.16), radius: 14, y: 6)
    }

    private var amber: Color { Asset.Colors.chapterAmber.swiftUIColor }
}

struct OrganizationPeopleClouds: View {
    let founders: [DossierEntityLink]
    let relatedPeople: [DossierEntityLink]
    let usesFlowLayout: Bool
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !founders.isEmpty {
                DossierCloudSection(
                    title: L10n.Graph.Dossier.cofounders,
                    tint: blue,
                    links: founders,
                    style: .person,
                    usesFlowLayout: usesFlowLayout,
                    onNavigate: onNavigate
                )
            }
            if !relatedPeople.isEmpty {
                DossierCloudSection(
                    title: L10n.Graph.Dossier.relatedPeople,
                    tint: blue,
                    links: relatedPeople,
                    style: .person,
                    usesFlowLayout: usesFlowLayout,
                    onNavigate: onNavigate
                )
            }
        }
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

// MARK: - University dossier

struct CompactUniversityCloud: View {
    let type: String
    let location: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: AppSymbols.institution)
                .font(.title3.weight(.semibold))
                .foregroundStyle(purple)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.56), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(type)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                if !location.isEmpty {
                    Text(location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [purple.opacity(0.22), purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 29,
                topTrailingRadius: 20,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 29,
                topTrailingRadius: 20,
                style: .continuous
            )
            .stroke(purple.opacity(0.18))
        )
    }

    private var purple: Color { Asset.Colors.chapterViolet.swiftUIColor }
}

struct UniversityPeopleClouds: View {
    let people: [DossierEntityLink]
    let showsStudyPeriod: Bool
    let usesFlowLayout: Bool
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        DossierCloudSection(
            title: L10n.Graph.Dossier.alumni,
            tint: Asset.Colors.chapterBlue.swiftUIColor,
            links: people,
            style: showsStudyPeriod ? .personWithPeriod : .person,
            usesFlowLayout: usesFlowLayout,
            onNavigate: onNavigate
        )
    }
}

// MARK: - Shared clouds

struct DossierCloudSection: View {
    enum Style: Equatable {
        case company
        case pastCompany
        case university
        case person
        case personWithPeriod
    }

    let title: String
    let tint: Color
    let links: [DossierEntityLink]
    let style: Style
    let usesFlowLayout: Bool
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 7, height: 7)
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(tint)
            .padding(.leading, 2)

            if usesFlowLayout {
                FlowLayout(spacing: 7) { cloudButtons }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) { cloudButtons }
                        .padding(.horizontal, 1)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }

    private var cloudButtons: some View {
        ForEach(links) { link in
            Button {
                if let entityID = link.entityID { onNavigate(entityID) }
            } label: {
                HStack(spacing: 6) {
                    if style == .company || style == .pastCompany {
                        Circle()
                            .fill(style == .company ? Color.green : Color.secondary.opacity(0.55))
                            .frame(width: 6, height: 6)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(link.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        if style == .personWithPeriod {
                            Text(link.period)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.horizontal, 12)
                .frame(minHeight: style == .personWithPeriod ? 44 : 36)
                .background(cloudBackground, in: cloudShape)
                .overlay(cloudShape.stroke(tint.opacity(0.18)))
            }
            .buttonStyle(.plain)
            .disabled(link.entityID == nil)
            .accessibilityLabel(L10n.Graph.Dossier.openNode(link.name))
        }
    }

    private var cloudBackground: some ShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [tint.opacity(backgroundOpacity), tint.opacity(backgroundOpacity * 0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var backgroundOpacity: Double {
        style == .university ? 0.2 : 0.13
    }

    private var cloudShape: UnevenRoundedRectangle {
        switch style {
        case .university:
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 15,
                bottomTrailingRadius: 21,
                topTrailingRadius: 16,
                style: .continuous
            )
        default:
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 15,
                topTrailingRadius: 19,
                style: .continuous
            )
        }
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(
            proposal: ProposedViewSize(width: bounds.width, height: proposal.height),
            subviews: subviews
        )
        for (index, point) in result.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
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
