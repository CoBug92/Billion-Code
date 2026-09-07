import SwiftUI

struct DenseGraphDossierPanel: View {
    let node: GraphNode
    let dossier: EntityDossier
    let canNavigateBack: Bool
    @Binding var detent: DenseDossierDetent
    let onNavigate: (GraphNode.ID) -> Void
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: .zero) {
            panelHeader
            Divider().opacity(0.42)
            dossierScrollView
        }
        .background(panelBackground)
        .accessibilityAction(named: detent == .compact ? "Развернуть" : "Свернуть") {
            toggleDetent()
        }
    }
}

// MARK: - Layout

private extension DenseGraphDossierPanel {
    var panelHeader: some View {
        DossierPanelHeader(
            node: node,
            eyebrowText: eyebrowText,
            metadataText: headerMetadata,
            detent: detent,
            canNavigateBack: canNavigateBack,
            onBack: onBack,
            onToggle: toggleDetent
        )
    }

    var dossierScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 17) {
                Color.clear.frame(height: 1).id(DossierScrollAnchor.top)
                primarySummary
                relationshipClouds

                if detent == .expanded {
                    expandedDetails
                        .transition(.opacity)
                } else if !dossier.timeline.isEmpty {
                    DossierTimelinePreview(
                        events: Array(dossier.timeline.prefix(3)),
                        tint: node.kind.denseGraphColor
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(node.id)
        .scrollBounceBehavior(.basedOnSize)
        .contentMargins(.bottom, 8, for: .scrollContent)
    }

    var panelBackground: some View {
        ZStack(alignment: .topLeading) {
            Asset.Colors.surfacePrimary.swiftUIColor
            RadialGradient(
                colors: [node.kind.denseGraphColor.opacity(0.1), .clear],
                center: .topLeading,
                startRadius: .zero,
                endRadius: 310
            )
            .frame(height: 240)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Compact summary

private extension DenseGraphDossierPanel {
    @ViewBuilder
    var primarySummary: some View {
        switch node.kind {
        case .person:
            if let wealth = dossier.wealth {
                CompactWealthCard(
                    formattedAmount: formatUSD(wealth.amountUSD)
                )
            }
        case .organization:
            CompactOrganizationCloud(
                activity: organizationActivity,
                title: L10n.Graph.Dossier.activity
            )
        case .university:
            CompactUniversityCloud(
                type: universityType,
                location: universityLocation
            )
        default:
            DossierLeadCard(
                title: dossier.facts.first?.label ?? node.kind.dossierTitle,
                value: dossier.facts.first?.value ?? node.summary,
                tint: node.kind.denseGraphColor,
                symbol: node.kind.dossierSymbol
            )
        }
    }

    @ViewBuilder
    var relationshipClouds: some View {
        switch node.kind {
        case .person:
            CompactPersonCloudGroups(
                companies: dossier.sortedLinks,
                universities: dossier.education,
                showsPastCompanies: detent == .expanded,
                usesFlowLayout: detent == .expanded,
                onNavigate: onNavigate
            )
        case .organization:
            OrganizationPeopleClouds(
                founders: organizationFounders,
                relatedPeople: detent == .expanded ? organizationRelatedPeople : [],
                usesFlowLayout: detent == .expanded,
                onNavigate: onNavigate
            )
        case .university:
            UniversityPeopleClouds(
                people: dossier.sortedLinks,
                showsStudyPeriod: detent == .expanded,
                usesFlowLayout: detent == .expanded,
                onNavigate: onNavigate
            )
        default:
            DossierCloudSection(
                title: "Связанные ноды",
                tint: node.kind.denseGraphColor,
                links: dossier.currentLinks.isEmpty ? dossier.sortedLinks : dossier.currentLinks,
                style: .person,
                usesFlowLayout: detent == .expanded,
                onNavigate: onNavigate
            )
        }
    }
}

// MARK: - Expanded dossier

private extension DenseGraphDossierPanel {
    var expandedDetails: some View {
        Group {
            DossierStorySection(
                title: node.kind == .person ? "Коротко о пути" : "Коротко о главном",
                text: dossier.description,
                tint: node.kind.denseGraphColor
            )

            if let wealth = dossier.wealth, !wealth.components.isEmpty {
                DossierWealthBreakdown(wealth: wealth)
            }

            if !supplementaryFacts.isEmpty {
                DossierFactsSection(
                    title: "Главное",
                    facts: supplementaryFacts,
                    tint: node.kind.denseGraphColor
                )
            }

            if !dossier.timeline.isEmpty {
                DossierTimelineSection(
                    title: node.kind == .person ? "Как сложился путь" : "Хронология связей",
                    events: dossier.timeline,
                    sectionTint: node.kind.denseGraphColor,
                    tintForEvent: timelineTint,
                    onNavigate: onNavigate
                )
            }

            Text("Обновлено: \(dossier.lastReviewedOn)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
        }
    }

    var supplementaryFacts: [DossierFact] {
        switch node.kind {
        case .organization:
            dossier.facts.filter { !$0.id.hasSuffix(":activity") }
        case .university:
            dossier.facts.filter {
                !$0.id.hasSuffix(":type")
                    && !$0.id.hasSuffix(":location")
                    && !$0.id.hasSuffix(":people")
            }
        case .person:
            []
        default:
            Array(dossier.facts.dropFirst())
        }
    }
}

// MARK: - Interaction

private extension DenseGraphDossierPanel {
    func toggleDetent() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.34)) {
            detent = detent.toggled
        }
    }
}

private enum DossierScrollAnchor {
    static let top = "dossier-top"
}
