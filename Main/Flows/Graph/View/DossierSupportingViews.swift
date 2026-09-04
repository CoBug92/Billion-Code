import SwiftUI

struct DossierWealthSection: View {
    let wealth: DossierWealth
    let formattedAmount: String
    let onOpenSource: (DossierSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Оценка состояния", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(Asset.Colors.chapterBlue.swiftUIColor)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedAmount)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Spacer()
                    Button { onOpenSource(wealth.source) } label: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Открыть источник: \(wealth.source.publisher)")
                }
                Text("На \(wealth.asOf)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(wealth.methodology)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(wealth.components) { component in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(component.label).font(.subheadline.bold())
                        Text(component.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if wealth.history.count >= 3 {
                    WealthHistoryView(points: wealth.history)
                        .frame(height: 120)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [Asset.Colors.chapterBlue.swiftUIColor.opacity(0.24), .cyan.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Asset.Colors.chapterBlue.swiftUIColor.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Asset.Colors.chapterBlue.swiftUIColor.opacity(0.08), radius: 14, y: 6)
    }
}

extension View {
    func cardSurface(tint: Color) -> some View {
        padding(16)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.105), .secondary.opacity(0.045)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            )
    }
}

struct DossierFactCard: View {
    let fact: DossierFact
    let tint: Color
    let onOpenSource: (DossierSource) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fact.label).font(.caption).foregroundStyle(.secondary)
                Text(fact.value).font(.subheadline.weight(.semibold))
            }
            Spacer()
            if let source = fact.source {
                Button { onOpenSource(source) } label: {
                    Image(systemName: "info.circle.fill").foregroundStyle(tint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct DossierLinkChip: View {
    let link: DossierEntityLink
    let tint: Color
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        Button {
            if let entityID = link.entityID { onNavigate(entityID) }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(link.isCurrent ? Color.green : Color.secondary.opacity(0.55))
                    .frame(width: 6, height: 6)
                Text(link.name).lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(tint.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .disabled(link.entityID == nil)
    }
}

struct DossierLinkRow: View {
    let link: DossierEntityLink
    let tint: Color
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        Button {
            if let entityID = link.entityID { onNavigate(entityID) }
        } label: {
            HStack(spacing: 12) {
                Circle().fill(link.isCurrent ? Color.green : Color.secondary.opacity(0.45)).frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(link.name).font(.subheadline.bold())
                    Text("\(link.role) · \(link.period)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if link.entityID != nil { Image(systemName: "chevron.right").font(.caption.bold()) }
            }
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .padding(12)
            .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.16)))
        }
        .buttonStyle(.plain)
        .disabled(link.entityID == nil)
    }
}

struct DossierTimelineCard: View {
    let event: DossierTimelineEvent
    let tint: Color
    let onNavigate: (GraphNode.ID) -> Void
    let onOpenSource: (DossierSource) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(event.year))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .frame(minWidth: 48, minHeight: 30)
                .background(tint.opacity(0.12), in: Capsule())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title).font(.subheadline.bold())
                    Spacer()
                    if let source = event.source {
                        Button { onOpenSource(source) } label: {
                            Image(systemName: "info.circle.fill").foregroundStyle(tint)
                        }.buttonStyle(.plain)
                    }
                }
                Text(event.description).font(.caption).foregroundStyle(.secondary)
                if let entityID = event.linkedEntityID {
                    Button("Перейти к ноде") { onNavigate(entityID) }
                        .font(.caption.bold()).buttonStyle(.plain).foregroundStyle(tint)
                }
            }
            .padding(.vertical, 3)
        }
        .padding(12)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.bottom, 9)
    }
}

struct DossierSourceView: View {
    let source: DossierSource

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Label("Источник", systemImage: "info.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(Color.accentColor)
                Text(source.publisher).font(.headline)
                Text(source.title).foregroundStyle(.secondary)
                if let url = source.url {
                    Link("Открыть публикацию", destination: url)
                        .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("Доказательство")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WealthHistoryView: View {
    let points: [DossierWealthPoint]

    var body: some View {
        GeometryReader { geometry in
            let values = points.map { Double($0.amountUSD) }
            let minimum = values.min() ?? .zero
            let maximum = values.max() ?? 1
            Path { path in
                for (index, point) in points.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                    let ratio = (Double(point.amountUSD) - minimum) / max(maximum - minimum, 1)
                    let y = geometry.size.height * (1 - CGFloat(ratio))
                    if index == .zero {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                Asset.Colors.chapterBlue.swiftUIColor,
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
        }
        .accessibilityLabel("Динамика оценки состояния")
    }
}

extension GraphEntityKind {
    var dossierTitle: String {
        switch self {
        case .person: "Человек"
        case .organization: "Компания"
        case .university: "Университет"
        case .foundation: "Фонд"
        case .family: "Семья"
        case .deal: "Сделка"
        case .event: "Событие"
        }
    }

    var dossierSymbol: String {
        switch self {
        case .person: AppSymbols.person
        case .organization: AppSymbols.organization
        case .university: AppSymbols.university
        case .foundation: AppSymbols.foundation
        case .family: AppSymbols.family
        case .deal: AppSymbols.deal
        case .event: AppSymbols.event
        }
    }
}
