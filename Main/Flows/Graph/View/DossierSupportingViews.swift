import SwiftUI

struct DossierWealthSection: View {
    let wealth: DossierWealth
    let formattedAmount: String
    let onOpenSource: (DossierSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Оценка состояния").font(.title3.bold())
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedAmount)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Spacer()
                    Button { onOpenSource(wealth.source) } label: {
                        Image(systemName: wealth.source.status.symbolName)
                            .foregroundStyle(wealth.source.status == .verified ? Color.accentColor : Color.orange)
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
    }
}

struct DossierSourceView: View {
    let source: DossierSource

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Label("Источник", systemImage: source.status.symbolName)
                    .font(.title2.bold())
                    .foregroundStyle(source.status == .verified ? Color.accentColor : Color.orange)
                Text(source.publisher).font(.headline)
                Text(source.title).foregroundStyle(.secondary)
                if let url = source.url {
                    Link("Открыть публикацию", destination: url)
                        .buttonStyle(.borderedProminent)
                } else {
                    Text("Внешняя ссылка появится после публикационного аудита.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("Доказательство")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension DossierSource.Status {
    var symbolName: String {
        switch self {
        case .verified: "checkmark.seal.fill"
        case .requiresAudit: "exclamationmark.triangle.fill"
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
