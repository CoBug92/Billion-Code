import SwiftUI

// MARK: - Person dossier

struct CompactWealthCard: View {
    let formattedAmount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("СОСТОЯНИЕ").font(.caption2.bold()).tracking(1).foregroundStyle(blue)
            Text(formattedAmount).font(.system(.title2, design: .rounded, weight: .bold))
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
            if !currentCompanies.isEmpty {
                cloudGroup(
                    title: L10n.Graph.Dossier.currentCompanies,
                    tint: amber
                ) {
                    ForEach(currentCompanies) { company in
                        companyButton(
                            company,
                            tint: amber
                        )
                    }
                }
            }
            if !pastCompanies.isEmpty {
                cloudGroup(
                    title: L10n.Graph.Dossier.pastCompanies,
                    tint: pastCompanyTint
                ) {
                    ForEach(pastCompanies) { company in
                        companyButton(
                            company,
                            tint: pastCompanyTint
                        )
                    }
                }
            }
            if !universities.isEmpty {
                cloudGroup(
                    title: L10n.Graph.Dossier.education,
                    tint: purple
                ) {
                    ForEach(universities) { university in
                        universityButton(university)
                    }
                }
            }
        }
    }

    private var currentCompanies: [DossierEntityLink] {
        companies.filter(\.isCurrent)
    }

    private var pastCompanies: [DossierEntityLink] {
        companies.filter { !$0.isCurrent }
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

    private func companyButton(_ company: DossierEntityLink, tint: Color) -> some View {
        Button {
            if let entityID = company.entityID { onNavigate(entityID) }
        } label: {
            Text(company.name)
                .lineLimit(1)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(tint.opacity(0.11), in: Capsule())
                .overlay(Capsule().stroke(tint.opacity(0.18)))
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
    private var pastCompanyTint: Color { .secondary }
}

// MARK: - Organization dossier

struct CompactOrganizationCloud: View {
    let activity: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(0.9)
                .foregroundStyle(Asset.Colors.chapterAmber.swiftUIColor)
            Label(activity, systemImage: AppSymbols.sparkles)
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
        }
    }
}

struct OrganizationPeopleClouds: View {
    let founders: [DossierEntityLink]
    let relatedPeople: [DossierEntityLink]
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            if !founders.isEmpty {
                cloudGroup(title: L10n.Graph.Dossier.cofounders, links: founders)
            }
            if !relatedPeople.isEmpty {
                cloudGroup(title: L10n.Graph.Dossier.relatedPeople, links: relatedPeople)
            }
        }
    }

    private func cloudGroup(title: String, links: [DossierEntityLink]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(0.9)
                .foregroundStyle(blue)
                .padding(.leading, 3)
            FlowLayout(spacing: 7) {
                ForEach(links) { link in
                    personButton(link)
                }
            }
        }
    }

    private func personButton(_ link: DossierEntityLink) -> some View {
        Button(link.name) {
            if let entityID = link.entityID { onNavigate(entityID) }
        }
        .font(.caption.bold())
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .buttonStyle(.plain)
        .padding(.horizontal, 11)
        .frame(height: 34)
        .background(blue.opacity(0.16), in: Capsule())
        .overlay(Capsule().stroke(blue.opacity(0.24)))
        .disabled(link.entityID == nil)
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

// MARK: - University dossier

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
                Image(systemName: AppSymbols.institution)
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
            Text(L10n.Graph.Dossier.alumni.uppercased())
                .font(.caption2.bold())
                .tracking(0.8)
                .foregroundStyle(blue)
            ScrollView(.horizontal, showsIndicators: false) {
                UniversityPeopleClouds(
                    people: alumni,
                    showsStudyPeriod: true,
                    usesHorizontalLayout: true,
                    onNavigate: onNavigate
                )
            }
        }
    }

    private var purple: Color { Asset.Colors.chapterViolet.swiftUIColor }
    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

struct UniversityPeopleClouds: View {

    // MARK: - Properties

    let people: [DossierEntityLink]
    let showsStudyPeriod: Bool
    let usesHorizontalLayout: Bool
    let onNavigate: (GraphNode.ID) -> Void

    // MARK: - Layout

    @ViewBuilder
    var body: some View {
        if usesHorizontalLayout {
            HStack(spacing: 7) {
                peopleButtons
            }
        } else {
            FlowLayout(spacing: 7) {
                peopleButtons
            }
        }
    }

    // MARK: - Private methods

    private var peopleButtons: some View {
        ForEach(people) { person in
            personButton(person)
        }
    }

    private func personButton(_ person: DossierEntityLink) -> some View {
        Button {
            if let entityID = person.entityID { onNavigate(entityID) }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                if showsStudyPeriod {
                    Text(person.period)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(.horizontal, 11)
            .padding(.vertical, showsStudyPeriod ? 8 : 9)
            .background(blue.opacity(0.16), in: Capsule())
            .overlay(Capsule().stroke(blue.opacity(0.28)))
        }
        .buttonStyle(.plain)
        .disabled(person.entityID == nil)
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

enum UniversityCloudVariant: Int, CaseIterable {
    case soft = 1
    case orbit
    case stacked
}

// MARK: - Flow layout

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
