import SwiftUI

struct GraphBottomPanel: View {
    let node: GraphNode
    let chapterTitle: String
    let chapterAccent: Color
    let relationships: [GraphRelationship]
    let graph: GraphData
    let availableHeight: CGFloat
    let topSafeArea: CGFloat
    let bottomSafeArea: CGFloat
    let onSelectNode: (GraphNode.ID) -> Void
    let onOpenRelationship: (GraphRelationship) -> Void

    @Binding var detent: GraphPanelDetent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var dragTranslation = CGFloat.zero

    var body: some View {
        Group {
            if detent == .collapsed {
                panelContent
                    .frame(height: .collapsedCardHeight, alignment: .top)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(
                            cornerRadius: .cornerRadius,
                            style: .continuous
                        )
                    )
                    .padding(.horizontal, Margin.x6)
                    .padding(.bottom, bottomSafeArea + Margin.x4)
            } else {
                panelContent
                    .frame(height: currentHeight, alignment: .top)
                    .background(
                        Asset.Colors.surfacePrimary.swiftUIColor,
                        in: UnevenRoundedRectangle(
                            topLeadingRadius: .cornerRadius,
                            bottomLeadingRadius: .zero,
                            bottomTrailingRadius: .zero,
                            topTrailingRadius: .cornerRadius,
                            style: .continuous
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: currentHeight, alignment: .bottom)
        .shadow(color: Color.black.opacity(.shadowOpacity), radius: .shadowRadius, y: -.shadowOffset)
        .accessibilityAction(named: L10n.Graph.Panel.expand) { move(up: true) }
        .accessibilityAction(named: L10n.Graph.Panel.collapse) { move(up: false) }
    }
}

private extension GraphBottomPanel {
    var panelContent: some View {
        VStack(spacing: .zero) {
            dragHeader
                .padding(.top, detent == .expanded ? topSafeArea : .zero)
            if detent != .collapsed {
                relationshipList
                    .transition(.opacity)
            }
        }
    }

    var currentHeight: CGFloat {
        let resting = detent.height(availableHeight: availableHeight, bottomSafeArea: bottomSafeArea)
        return min(max(resting - dragTranslation, .minimumPanelHeight), availableHeight + bottomSafeArea)
    }

    var dragHeader: some View {
        VStack(spacing: Margin.x4) {
            Capsule()
                .fill(Color.secondary.opacity(.handleOpacity))
                .frame(width: .handleWidth, height: .handleHeight)
                .padding(.top, Margin.x4)
            HStack(spacing: Margin.x6) {
                PersonAvatarView(
                    node: node,
                    diameter: .profileDiameter,
                    accentColor: chapterAccent
                )
                VStack(alignment: .leading, spacing: Margin.x2) {
                    Text(chapterTitle.uppercased())
                        .font(.caption2.bold())
                        .tracking(1.2)
                        .foregroundStyle(chapterAccent)
                    Text(node.name)
                        .font(.headline)
                        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    if detent != .collapsed || !dynamicTypeSize.isAccessibilitySize {
                        Text(node.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(detent == .collapsed ? 2 : 3)
                    }
                }
                Spacer(minLength: Margin.x3)
                Text(L10n.Graph.Card.relationships(relationships.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Margin.x8)
            .padding(.bottom, Margin.x5)
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(node.name)
        .accessibilityValue(L10n.Graph.Card.relationships(relationships.count))
        .accessibilityHint(node.summary)
    }

    var relationshipList: some View {
        VStack(alignment: .leading, spacing: Margin.x3) {
            Divider()
            Text(L10n.Graph.relationships)
                .font(.subheadline.bold())
                .padding(.horizontal, Margin.x8)

            if relationships.isEmpty {
                Text(L10n.Graph.Relationships.empty)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Margin.x8)
            } else {
                ScrollView {
                    LazyVStack(spacing: .zero) {
                        ForEach(relationships) { relationship in
                            relationshipRow(relationship)
                            Divider().padding(.leading, Margin.x8)
                        }
                    }
                    .padding(.bottom, bottomSafeArea + Margin.x8)
                }
            }
        }
    }

    func relationshipRow(_ relationship: GraphRelationship) -> some View {
        let other = otherNode(for: relationship)
        return HStack(spacing: Margin.x3) {
            Button {
                if let other { onSelectNode(other.id) }
            } label: {
                HStack(spacing: Margin.x5) {
                    Image(systemName: relationship.status.symbolName)
                        .foregroundStyle(relationship.status == .disputed ? Color.orange : Color.secondary)
                        .frame(width: .statusIconWidth)
                    VStack(alignment: .leading, spacing: Margin.x1) {
                        Text(other?.name ?? relationship.id)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                        Text("\(relationship.kind.localizedTitle) · \(relationship.status.localizedTitle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: Margin.x2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(other?.name ?? relationship.id)
            .accessibilityHint(L10n.Graph.Relationship.selectPerson)

            Button { onOpenRelationship(relationship) } label: {
                Image(systemName: AppSymbols.information)
                    .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Graph.Relationship.evidence)
        }
        .padding(.leading, Margin.x8)
        .padding(.trailing, Margin.x4)
        .frame(minHeight: .minimumRowHeight)
    }
}

private extension GraphBottomPanel {
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: .minimumDragDistance)
            .onChanged { dragTranslation = $0.translation.height }
            .onEnded { value in
                let target = detent.resolved(
                    predictedTranslation: value.predictedEndTranslation.height,
                    availableHeight: availableHeight,
                    bottomSafeArea: bottomSafeArea
                )
                setDetent(target)
            }
    }

    func move(up: Bool) {
        let all = GraphPanelDetent.allCases
        guard let index = all.firstIndex(of: detent) else { return }
        let targetIndex = min(max(index + (up ? 1 : -1), all.startIndex), all.index(before: all.endIndex))
        setDetent(all[targetIndex])
    }

    func setDetent(_ newValue: GraphPanelDetent) {
        if reduceMotion {
            detent = newValue
            dragTranslation = .zero
        } else {
            withAnimation(.snappy) {
                detent = newValue
                dragTranslation = .zero
            }
        }
    }

    func otherNode(for relationship: GraphRelationship) -> GraphNode? {
        let id = relationship.sourceID == node.id ? relationship.targetID : relationship.sourceID
        return graph.node(id: id)
    }
}

private extension CGFloat {
    static let collapsedCardHeight = 120.0
    static let cornerRadius = 28.0
    static let handleHeight = 5.0
    static let handleWidth = 40.0
    static let minimumDragDistance = 8.0
    static let minimumPanelHeight = 96.0
    static let minimumRowHeight = 56.0
    static let minimumTouchTarget = 44.0
    static let profileDiameter = 52.0
    static let shadowOffset = 2.0
    static let shadowRadius = 12.0
    static let statusIconWidth = 24.0
}

private extension Double {
    static let handleOpacity = 0.35
    static let shadowOpacity = 0.14
}

// MARK: - Preview

#Preview("Collapsed", traits: .sizeThatFitsLayout) {
    @Previewable @State var detent = GraphPanelDetent.collapsed
    let atlas = GraphAtlasFixture.editorial
    GraphBottomPanel(
        node: atlas.nodes[0],
        chapterTitle: atlas.chapters[0].title,
        chapterAccent: atlas.chapters[0].accentColor,
        relationships: atlas.relationships,
        graph: atlas.graphData,
        availableHeight: 844,
        topSafeArea: 59,
        bottomSafeArea: 34,
        onSelectNode: { _ in },
        onOpenRelationship: { _ in },
        detent: $detent
    )
    .frame(height: 180)
    .preferredColorScheme(.dark)
}
