import SwiftUI
struct DenseGraphDossierPanel: View {
    let node: GraphNode
    let dossier: EntityDossier
    let availableHeight: CGFloat
    let topSafeArea: CGFloat
    let bottomSafeArea: CGFloat
    let canNavigateBack: Bool
    @Binding var detent: DenseDossierDetent
    let onNavigate: (GraphNode.ID) -> Void
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var presentedSource: DossierSource?
    @GestureState private var dragTranslation = CGFloat.zero

    var body: some View {
        VStack(spacing: .zero) {
            panelHeader
            if detent == .compact {
                compactContent
                    .transition(.opacity)
            } else {
                expandedContent
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: currentHeight, alignment: .top)
        .background(panelBackground)
        .clipShape(panelShape)
        .overlay(panelShape.stroke(.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 22, y: -6)
        .animation(reduceMotion ? nil : .interactiveSpring(response: 0.36, dampingFraction: 0.86), value: detent)
        .accessibilityAction(named: detent == .compact ? "Развернуть" : "Свернуть") {
            setDetent(detent == .compact ? .expanded : .compact)
        }
        .sheet(item: $presentedSource) { source in
            DossierSourceView(source: source)
                .presentationDetents([.medium])
        }
    }
}
private extension DenseGraphDossierPanel {
    var compactHeight: CGFloat {
        let baseHeight = DenseDossierDetent.compact.height(
            availableHeight: availableHeight,
            topSafeArea: topSafeArea,
            bottomSafeArea: bottomSafeArea
        )
        let preferredContentHeight: CGFloat = switch node.kind {
        case .person: 420
        case .organization: 350
        case .university: 390
        default: 300
        }
        let maximumFraction = node.kind == .person ? 0.6 : 0.52
        return min(max(baseHeight, preferredContentHeight + bottomSafeArea), availableHeight * maximumFraction)
    }
    var restingHeight: CGFloat {
        detent.height(
            availableHeight: availableHeight,
            topSafeArea: topSafeArea,
            bottomSafeArea: bottomSafeArea
        )
    }
    var currentHeight: CGFloat {
        let effectiveDrag = detent == .compact ? min(dragTranslation, 0) : max(dragTranslation, 0)
        let expandedHeight = DenseDossierDetent.expanded.height(
            availableHeight: availableHeight,
            topSafeArea: topSafeArea,
            bottomSafeArea: bottomSafeArea
        )
        return min(max(restingHeight - effectiveDrag, compactHeight), expandedHeight)
    }

    var panelBackground: some ShapeStyle {
        AnyShapeStyle(Asset.Colors.surfacePrimary.swiftUIColor)
    }

    var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 28,
            style: .continuous
        )
    }

    var panelHeader: some View {
        DossierPanelHeader(
            node: node,
            eyebrowText: eyebrowText,
            personMetadata: personMetadata,
            detent: detent,
            canNavigateBack: canNavigateBack,
            onBack: onBack,
            onToggle: { setDetent(detent == .compact ? .expanded : .compact) }
        )
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    var eyebrowText: String? {
        switch node.kind {
        case .person: nil
        case .organization: dossier.facts.first { $0.id.hasSuffix(":activity") }?.value
        case .university: dossier.facts.first { $0.id.hasSuffix(":type") }?.value
        default: node.kind.dossierTitle
        }
    }

    var compactContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            compactPrimaryFact
            if node.kind == .person {
                compactLinks
                if !dossier.education.isEmpty {
                    CompactPersonUniversityCloud(
                        universities: dossier.education,
                        variant: personUniversityCloudVariant,
                        onNavigate: onNavigate
                    )
                }
            } else if node.kind != .organization && node.kind != .university {
                compactLinks
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 7)
        .padding(.bottom, bottomSafeArea + 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture)
    }

    @ViewBuilder
    var compactPrimaryFact: some View {
        switch node.kind {
        case .person:
            if let wealth = dossier.wealth {
                CompactWealthCard(
                    wealth: wealth,
                    formattedAmount: formatUSD(wealth.amountUSD),
                    variant: wealthCardVariant,
                    onOpenSource: { presentedSource = $0 }
                )
            }
        case .organization:
            CompactOrganizationCloud(
                activity: dossier.facts.first { $0.id.hasSuffix(":activity") }?.value ?? node.summary,
                founders: dossier.links.filter { link in
                    let role = link.role.lowercased()
                    return role.contains("основател") || role.contains("соосновател")
                },
                onNavigate: onNavigate
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
            if let first = dossier.facts.first { factLine(first) }
        }
    }

    var compactLinks: some View {
        let visible = dossier.currentLinks.isEmpty ? dossier.sortedLinks : dossier.currentLinks
        return FlowLayout(spacing: 7) {
            ForEach(visible) { link in
                linkChip(link)
            }
        }
    }

    var expandedContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    storyCard

                    if let wealth = dossier.wealth {
                        DossierWealthSection(
                            wealth: wealth,
                            formattedAmount: formatUSD(wealth.amountUSD),
                            onOpenSource: { presentedSource = $0 }
                        )
                    }

                    factsSection
                    linksSection
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
        }
    }

    var storyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(node.kind == .person ? "Коротко о пути" : "Коротко о главном", systemImage: "quote.opening")
                .font(.caption.bold())
                .foregroundStyle(node.kind.denseGraphColor)
            Text(dossier.description)
                .font(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        }
        .cardSurface(tint: node.kind.denseGraphColor)
    }

    var factsSection: some View {
        dossierSection(title: node.kind == .university ? "О вузе" : "Главное") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(dossier.facts) { fact in
                    factLine(fact)
                }
            }
        }
    }

    var linksSection: some View {
        dossierSection(title: linksTitle) {
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
                    timelineRow(event)
                        .id(event.id)
                }
            }
        }
    }

    func timelineIndex(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dossier.timeline) { event in
                    Button(String(event.year)) {
                        withAnimation(.smooth) { proxy.scrollTo(event.id, anchor: .top) }
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

    func factLine(_ fact: DossierFact) -> some View {
        DossierFactCard(fact: fact, tint: node.kind.denseGraphColor) { presentedSource = $0 }
    }

    func linkChip(_ link: DossierEntityLink) -> some View {
        DossierLinkChip(link: link, tint: color(for: link), onNavigate: onNavigate)
    }

    func linkRow(_ link: DossierEntityLink) -> some View {
        DossierLinkRow(link: link, tint: color(for: link), onNavigate: onNavigate)
    }

    func timelineRow(_ event: DossierTimelineEvent) -> some View {
        DossierTimelineCard(
            event: event,
            tint: node.kind.denseGraphColor,
            onNavigate: onNavigate,
            onOpenSource: { presentedSource = $0 }
        )
    }

    func dossierSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(tint: node.kind.denseGraphColor)
    }

    func sourceButton(_ source: DossierSource) -> some View {
        Button { presentedSource = source } label: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(node.kind.denseGraphColor)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Открыть источник: \(source.publisher)")
    }

    var linksTitle: String {
        switch node.kind {
        case .person: "Компании и активы"
        case .organization: "Основатели и связанные люди"
        case .university: "Люди и программы"
        default: "Связанные ноды"
        }
    }

    func color(for link: DossierEntityLink) -> Color {
        if link.entityID?.hasPrefix("organization:") == true {
            return GraphEntityKind.organization.denseGraphColor
        }
        if link.entityID?.hasPrefix("university:") == true {
            return GraphEntityKind.university.denseGraphColor
        }
        return GraphEntityKind.person.denseGraphColor
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let shouldExpand = value.predictedEndTranslation.height < -50
                let shouldCollapse = value.predictedEndTranslation.height > 50
                if shouldExpand { setDetent(.expanded) }
                else if shouldCollapse { setDetent(.compact) }
            }
    }

    func setDetent(_ newDetent: DenseDossierDetent) {
        if reduceMotion {
            detent = newDetent
        } else {
            withAnimation(.snappy) {
                detent = newDetent
            }
        }
    }

    func formatUSD(_ amount: UInt64) -> String {
        let value = Double(amount)
        if value >= 1_000_000_000 {
            return "~$" + (value / 1_000_000_000).formatted(.number.precision(.fractionLength(0...1))) + " млрд"
        }
        if value >= 1_000_000 {
            return "~$" + (value / 1_000_000).formatted(.number.precision(.fractionLength(0...1))) + " млн"
        }
        return "~$" + value.formatted(.number.notation(.compactName))
    }
}
