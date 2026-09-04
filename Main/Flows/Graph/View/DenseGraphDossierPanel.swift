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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var presentedSource: DossierSource?
    @State private var dragTranslation = CGFloat.zero

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
        .shadow(color: .black.opacity(0.2), radius: 18, y: -4)
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
        DenseDossierDetent.compact.height(availableHeight: availableHeight, bottomSafeArea: bottomSafeArea)
    }
    var restingHeight: CGFloat {
        detent.height(availableHeight: availableHeight, bottomSafeArea: bottomSafeArea)
    }
    var currentHeight: CGFloat {
        min(max(restingHeight - dragTranslation, compactHeight), availableHeight + bottomSafeArea)
    }

    var panelBackground: some ShapeStyle {
        detent == .compact ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Asset.Colors.surfacePrimary.swiftUIColor)
    }

    var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: detent == .compact ? 28 : 0,
            bottomTrailingRadius: detent == .compact ? 28 : 0,
            topTrailingRadius: 28,
            style: .continuous
        )
    }

    var panelHeader: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(.secondary.opacity(0.38))
                .frame(width: 40, height: 5)
                .padding(.top, detent == .expanded ? topSafeArea + 8 : 10)

            HStack(spacing: 12) {
                if canNavigateBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Вернуться к предыдущей ноде")
                }

                Image(systemName: node.kind.dossierSymbol)
                    .font(.headline)
                    .foregroundStyle(node.kind.denseGraphColor)
                    .frame(width: 42, height: 42)
                    .background(node.kind.denseGraphColor.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.kind.dossierTitle.uppercased())
                        .font(.caption2.bold())
                        .tracking(1.1)
                        .foregroundStyle(node.kind.denseGraphColor)
                    Text(node.name)
                        .font(detent == .expanded ? .title2.bold() : .headline)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Button {
                    setDetent(detent == .compact ? .expanded : .compact)
                } label: {
                    Image(systemName: detent == .compact ? "chevron.up" : "chevron.down")
                        .frame(width: 44, height: 44)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(detent == .compact ? "Развернуть досье" : "Свернуть досье")
            }
            .padding(.horizontal, 18)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    var compactContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            compactPrimaryFact
            if !dynamicTypeSize.isAccessibilitySize {
                compactLinks
                if let first = dossier.timeline.first {
                    Text("\(first.year) · \(first.title): \(first.description)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 7)
        .padding(.bottom, bottomSafeArea + 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    var compactPrimaryFact: some View {
        if node.kind == .person {
            HStack(spacing: 6) {
                Text(dossier.wealth.map { formatUSD($0.amountUSD) } ?? "Оценка состояния не опубликована")
                    .font(.subheadline.bold())
                if let wealth = dossier.wealth {
                    Text("на \(wealth.asOf)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    sourceButton(wealth.source)
                }
            }
        } else if let first = dossier.facts.first {
            factLine(first)
        }
    }

    var compactLinks: some View {
        let visible = Array(dossier.sortedLinks.prefix(4))
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(visible) { link in
                    linkChip(link)
                }
                if dossier.links.count > visible.count {
                    Text("ещё \(dossier.links.count - visible.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(.secondary.opacity(0.1), in: Capsule())
                }
            }
        }
    }

    var expandedContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text(dossier.description)
                        .font(.body)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

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

                    Text("Проверено: \(dossier.lastReviewedOn)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, bottomSafeArea + 28)
            }
        }
    }

    var factsSection: some View {
        dossierSection(title: node.kind == .university ? "О вузе" : "Главное") {
            VStack(spacing: 12) {
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
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
        }
    }

    func factLine(_ fact: DossierFact) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fact.label).font(.caption).foregroundStyle(.secondary)
                Text(fact.value).font(.subheadline.weight(.semibold))
            }
            Spacer()
            if let source = fact.source { sourceButton(source) }
        }
    }

    func linkChip(_ link: DossierEntityLink) -> some View {
        Button {
            if let entityID = link.entityID { onNavigate(entityID) }
        } label: {
            HStack(spacing: 5) {
                if link.isCurrent {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                }
                Text(link.name).lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(.secondary.opacity(0.11), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(link.entityID == nil)
    }

    func linkRow(_ link: DossierEntityLink) -> some View {
        Button {
            if let entityID = link.entityID { onNavigate(entityID) }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(link.isCurrent ? Color.green : Color.secondary.opacity(0.45))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(link.name).font(.subheadline.bold())
                    Text("\(link.role) · \(link.period)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if link.entityID != nil { Image(systemName: "chevron.right").font(.caption.bold()) }
            }
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(12)
            .background(.secondary.opacity(0.075), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(link.entityID == nil)
    }

    func timelineRow(_ event: DossierTimelineEvent) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(event.year))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(node.kind.denseGraphColor)
                .frame(width: 42, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title).font(.subheadline.bold())
                    Spacer()
                    if let source = event.source { sourceButton(source) }
                }
                Text(event.description).font(.caption).foregroundStyle(.secondary)
                if let entityID = event.linkedEntityID {
                    Button("Перейти к ноде") { onNavigate(entityID) }
                        .font(.caption.bold())
                        .buttonStyle(.plain)
                        .foregroundStyle(node.kind.denseGraphColor)
                }
            }
            .padding(.bottom, 20)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(node.kind.denseGraphColor.opacity(0.3))
                    .frame(width: 1)
                    .offset(x: -8)
            }
        }
    }

    func dossierSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold())
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func sourceButton(_ source: DossierSource) -> some View {
        Button { presentedSource = source } label: {
            Image(systemName: source.status.symbolName)
                .foregroundStyle(source.status == .verified ? node.kind.denseGraphColor : Color.orange)
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

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragTranslation = value.translation.height
            }
            .onEnded { value in
                let shouldExpand = value.predictedEndTranslation.height < -60
                let shouldCollapse = value.predictedEndTranslation.height > 60
                if shouldExpand { setDetent(.expanded) }
                else if shouldCollapse { setDetent(.compact) }
                else { dragTranslation = .zero }
            }
    }

    func setDetent(_ newDetent: DenseDossierDetent) {
        if reduceMotion {
            detent = newDetent
            dragTranslation = .zero
        } else {
            withAnimation(.snappy) {
                detent = newDetent
                dragTranslation = .zero
            }
        }
    }

    func formatUSD(_ amount: UInt64) -> String {
        let value = Double(amount)
        if value >= 1_000_000_000 {
            return "$" + (value / 1_000_000_000).formatted(.number.precision(.fractionLength(0...1))) + " млрд"
        }
        return "$" + value.formatted(.number.notation(.compactName))
    }
}
