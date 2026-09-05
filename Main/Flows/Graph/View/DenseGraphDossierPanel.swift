import SwiftUI

struct DenseGraphDossierPanel: View {

    // MARK: - Properties

    let node: GraphNode
    let dossier: EntityDossier
    let availableHeight: CGFloat
    let bottomSafeArea: CGFloat
    let canNavigateBack: Bool
    @Binding var detent: DenseDossierDetent
    let onNavigate: (GraphNode.ID) -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    let onCompactHeightChange: (GraphNode.ID, CGFloat) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var compactBodyHeight = CGFloat.zero
    @State private var headerHeight = CGFloat.zero
    @State private var expandedScrollOffset = CGFloat.zero
    @State private var dragTranslation = CGFloat.zero

    // MARK: - Layout

    var body: some View {
        VStack(spacing: .zero) {
            panelHeader
            if detent == .expanded {
                expandedContent
            } else {
                compactContent
            }
        }
        .onChange(of: measuredCompactPanelHeight, initial: true) { _, newHeight in
            guard headerHeight > .zero, newHeight > headerHeight else { return }
            onCompactHeightChange(node.id, newHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(height: currentHeight, alignment: .top)
        .background(Asset.Colors.surfacePrimary.swiftUIColor)
        .clipShape(panelShape)
        .overlay(panelShape.stroke(.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 22, y: -6)
        .offset(y: dismissOffset)
        .accessibilityAction(named: detent == .expanded ? "Свернуть" : "Развернуть") {
            toggleDetent()
        }
        .accessibilityAction(named: L10n.Graph.Dossier.close) {
            onClose()
        }
    }
}

// MARK: - Layout

private extension DenseGraphDossierPanel {
    var restingHeight: CGFloat {
        detent.height(
            collapsedHeight: collapsedHeight,
            compactHeight: measuredCompactPanelHeight,
            availableHeight: availableHeight,
            bottomSafeArea: bottomSafeArea
        )
    }

    var currentHeight: CGFloat {
        let lowerHeight = detent.lowerNeighbor.height(
            collapsedHeight: collapsedHeight,
            compactHeight: measuredCompactPanelHeight,
            availableHeight: availableHeight,
            bottomSafeArea: bottomSafeArea
        )
        let upperHeight = detent.upperNeighbor.height(
            collapsedHeight: collapsedHeight,
            compactHeight: measuredCompactPanelHeight,
            availableHeight: availableHeight,
            bottomSafeArea: bottomSafeArea
        )
        return min(max(restingHeight - dragTranslation, lowerHeight), upperHeight)
    }

    var dismissOffset: CGFloat {
        detent == .collapsed ? max(dragTranslation, .zero) : .zero
    }

    var measuredCompactPanelHeight: CGFloat { measuredHeaderHeight + (compactBodyViewportHeight ?? .zero) }

    var collapsedHeight: CGFloat { measuredHeaderHeight + bottomSafeArea }

    var measuredHeaderHeight: CGFloat { headerHeight > .zero ? headerHeight : DenseDossierDetent.fallbackCollapsedHeight }

    var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 28,
            style: .continuous
        )
    }

    // MARK: - Content

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
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { _, newHeight in
            headerHeight = newHeight
        }
    }

    var compactContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 9) {
                compactPrimaryFact
                if node.kind == .person {
                    CompactPersonCloudGroups(
                        companies: dossier.sortedLinks,
                        universities: dossier.education,
                        onNavigate: onNavigate
                    )
                } else if node.kind == .organization {
                    organizationPeopleClouds
                } else if node.kind != .organization && node.kind != .university {
                    compactLinks
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 7)
            .padding(.bottom, bottomSafeArea + 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { _, newHeight in
                compactBodyHeight = newHeight
            }
        }
        .frame(height: compactBodyViewportHeight)
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .top) {
            if detent == .collapsed {
                Asset.Colors.surfacePrimary.swiftUIColor.frame(height: bottomSafeArea)
            }
        }
        .accessibilityHidden(detent == .collapsed)
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture)
    }

    var compactBodyViewportHeight: CGFloat? {
        guard compactBodyHeight > .zero else { return nil }
        return DenseDossierDetent.compactBodyHeight(
            contentHeight: compactBodyHeight,
            headerHeight: headerHeight,
            availableHeight: availableHeight,
            bottomSafeArea: bottomSafeArea
        )
    }

    @ViewBuilder
    var compactPrimaryFact: some View {
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
                type: dossier.facts.first { $0.id.hasSuffix(":type") }?.value ?? "Исследовательский университет",
                location: dossier.facts.first { $0.id.hasSuffix(":location") }?.value ?? "",
                alumni: dossier.links,
                variant: universityCloudVariant,
                onNavigate: onNavigate
            )
        default:
            if let first = dossier.facts.first { DossierFactCard(fact: first) }
        }
    }

    var compactLinks: some View {
        FlowLayout(spacing: 7) {
            ForEach(dossier.currentLinks.isEmpty ? dossier.sortedLinks : dossier.currentLinks) { link in
                linkChip(link)
            }
        }
    }

    var expandedContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if node.kind == .organization {
                        CompactOrganizationCloud(
                            activity: organizationActivity,
                            title: L10n.Graph.Dossier.activity
                        )
                        organizationPeopleClouds
                    } else if node.kind == .university {
                        universityTypeCard
                    } else {
                        storyCard
                    }

                    if let wealth = dossier.wealth {
                        DossierWealthSection(
                            wealth: wealth,
                            formattedAmount: formatUSD(wealth.amountUSD)
                        )
                    }

                    if node.kind == .person {
                        CompactPersonCloudGroups(
                            companies: dossier.sortedLinks,
                            universities: dossier.education,
                            onNavigate: onNavigate
                        )
                    }

                    if node.kind == .university {
                        universityPeopleSection
                    } else if node.kind != .person && node.kind != .organization {
                        factsSection
                        linksSection
                    }
                    timelineIndex(proxy: proxy)
                    timelineSection

                    Text("Обновлено: \(dossier.lastReviewedOn)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, bottomSafeArea + 28)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                expandedScrollOffset = newValue
            }
            .simultaneousGesture(expandedCollapseGesture)
        }
    }

    var storyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                "Коротко о пути",
                systemImage: AppSymbols.quote
            )
                .font(.caption.bold())
                .foregroundStyle(node.kind.denseGraphColor)
            Text(dossier.description)
                .font(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        }
        .cardSurface(tint: node.kind.denseGraphColor)
    }

    var factsSection: some View {
        dossierSection(title: "Главное") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(dossier.facts) { DossierFactCard(fact: $0) }
            }
        }
    }

    var linksSection: some View {
        dossierSection(title: "Связанные ноды") {
            LazyVStack(spacing: 8) {
                ForEach(dossier.sortedLinks) { link in
                    linkRow(link)
                }
            }
        }
    }

    var timelineSection: some View {
        dossierSection(title: node.kind == .person ? "Как сложился путь" : "Хронология связей") {
            LazyVStack(spacing: .zero) {
                ForEach(dossier.timeline) { event in
                    DossierTimelineCard(
                        event: event,
                        tint: timelineTint(for: event),
                        onNavigate: onNavigate
                    )
                        .id(event.id)
                }
            }
        }
    }

    // MARK: - Private methods

    func timelineIndex(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(timelineYearAnchors, id: \.year) { anchor in
                    Button(String(anchor.year)) {
                        withAnimation(.smooth) { proxy.scrollTo(anchor.eventID, anchor: .top) }
                    }
                    .font(.caption.bold())
                    .buttonStyle(.plain)
                    .foregroundStyle(node.kind.denseGraphColor)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(node.kind.denseGraphColor.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    func linkChip(_ link: DossierEntityLink) -> some View {
        DossierLinkChip(link: link, tint: color(for: link), onNavigate: onNavigate)
    }

    func linkRow(_ link: DossierEntityLink) -> some View {
        DossierLinkRow(link: link, tint: color(for: link), onNavigate: onNavigate)
    }

    func dossierSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(tint: node.kind.denseGraphColor)
    }

    // MARK: - Interaction

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { dragTranslation = $0.translation.height }
            .onEnded(finishDrag)
    }

    var expandedCollapseGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged {
                guard expandedScrollOffset <= 1, $0.translation.height > .zero else { return }
                dragTranslation = $0.translation.height
            }
            .onEnded { value in
                guard expandedScrollOffset <= 1, value.translation.height > .zero else {
                    setDetent(detent)
                    return
                }
                finishDrag(value)
            }
    }

    func setDetent(_ newDetent: DenseDossierDetent) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.94)) {
            detent = newDetent
            dragTranslation = .zero
        }
    }

    func toggleDetent() {
        switch detent {
        case .collapsed: setDetent(.compact)
        case .compact: setDetent(.expanded)
        case .expanded: setDetent(.compact)
        }
    }

    func finishDrag(_ value: DragGesture.Value) {
        let translation = value.translation.height
        let predictedTranslation = value.predictedEndTranslation.height
        if detent == .collapsed, translation > 90 {
            dragTranslation = .zero
            onClose()
            return
        }

        setDetent(detent.targetAfterDrag(translation: translation, predictedTranslation: predictedTranslation))
    }
}
