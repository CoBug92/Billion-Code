import SwiftUI

struct DossierLeadCard: View {
    let title: String
    let value: String
    let tint: Color
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dossierSurface(tint: tint, cornerRadius: 22)
    }
}

struct DossierStorySection: View {
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: AppSymbols.quote)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.body)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 3)
        .padding(.leading, 15)
        .overlay(alignment: .leading) {
            Capsule().fill(tint).frame(width: 3)
        }
    }
}

struct DossierWealthBreakdown: View {
    let wealth: DossierWealth

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DossierSectionHeader(title: "Структура состояния", tint: blue)
            ForEach(wealth.components) { component in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(blue.opacity(0.7))
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(component.label).font(.subheadline.weight(.semibold))
                        Text(component.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if wealth.history.count >= 3 {
                WealthHistoryView(points: wealth.history)
                    .frame(height: 112)
            }
        }
        .padding(16)
        .dossierSurface(tint: blue, cornerRadius: 22)
    }

    private var blue: Color { Asset.Colors.chapterBlue.swiftUIColor }
}

struct DossierFactsSection: View {
    let title: String
    let facts: [DossierFact]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DossierSectionHeader(title: title, tint: tint)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 138), spacing: 9)], spacing: 9) {
                ForEach(facts) { fact in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fact.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fact.value)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                    .background(.secondary.opacity(0.065), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}

struct DossierTimelinePreview: View {
    let events: [DossierTimelineEvent]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DossierSectionHeader(title: "Ключевой путь", tint: tint)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(events) { event in
                        HStack(spacing: 7) {
                            Text(String(event.year))
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(tint)
                            Text(event.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(tint.opacity(0.09), in: Capsule())
                    }
                }
            }
        }
    }
}

struct DossierTimelineSection: View {
    let title: String
    let events: [DossierTimelineEvent]
    let sectionTint: Color
    let tintForEvent: (DossierTimelineEvent) -> Color
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            DossierSectionHeader(title: title, tint: sectionTint)
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                DossierTimelineRow(
                    event: event,
                    tint: tintForEvent(event),
                    isLast: index == events.count - 1,
                    onNavigate: onNavigate
                )
            }
        }
    }
}

private struct DossierTimelineRow: View {
    let event: DossierTimelineEvent
    let tint: Color
    let isLast: Bool
    let onNavigate: (GraphNode.ID) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: .zero) {
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Asset.Colors.surfacePrimary.swiftUIColor, lineWidth: 3))
                if !isLast {
                    Rectangle()
                        .fill(tint.opacity(0.22))
                        .frame(width: 2)
                        .frame(minHeight: 58)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(event.year))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tint)
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                Text(event.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? .zero : 13)

            Spacer(minLength: 4)
            if let entityID = event.linkedEntityID {
                Button {
                    onNavigate(entityID)
                } label: {
                    Image(systemName: AppSymbols.chevron)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 44, height: 44)
                        .background(tint.opacity(0.09), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Graph.Dossier.openNode(event.title))
            }
        }
    }
}

struct DossierSectionHeader: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(tint)
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
                    let y = 6 + (geometry.size.height - 12) * (1 - CGFloat(ratio))
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

extension View {
    func dossierSurface(tint: Color, cornerRadius: CGFloat) -> some View {
        background(
            LinearGradient(
                colors: [tint.opacity(0.11), .secondary.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(tint.opacity(0.15))
        )
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
