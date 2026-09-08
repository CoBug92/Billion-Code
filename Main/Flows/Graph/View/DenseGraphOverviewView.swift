import SwiftUI

struct DenseGraphOverviewView: View {
    let viewModel: DenseGraphViewModel
    let onSelectSection: (DenseGraphSection) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                overviewCanvas(viewport: geometry.size)
                if viewModel.showsOverviewSections {
                    sectionButtons(viewport: geometry.size)
                }
            }
        }
        .allowsHitTesting(viewModel.showsOverviewSections)
    }
}

// MARK: - Canvas

private extension DenseGraphOverviewView {
    func overviewCanvas(viewport: CGSize) -> some View {
        Canvas(rendersAsynchronously: true) { context, _ in
            drawSections(context: context, viewport: viewport)
            drawPeople(context: context, viewport: viewport)
        }
        .allowsHitTesting(false)
    }

    func drawSections(context: GraphicsContext, viewport: CGSize) {
        for section in viewModel.graph.sections {
            let rectangle = screenRectangle(for: section.region, viewport: viewport)
            guard rectangle.intersects(CGRect(origin: .zero, size: viewport)) else { continue }
            let path = Path(
                roundedRect: rectangle.insetBy(dx: .sectionScreenInset, dy: .sectionScreenInset),
                cornerRadius: .sectionCornerRadius
            )
            context.fill(path, with: .color(section.accentColor.opacity(.sectionFillOpacity)))
            context.stroke(
                path,
                with: .color(section.accentColor.opacity(.sectionStrokeOpacity)),
                lineWidth: .sectionStrokeWidth
            )
        }
    }

    func drawPeople(context: GraphicsContext, viewport: CGSize) {
        let bounds = CGRect(origin: .zero, size: viewport).insetBy(dx: -.nodeOverscan, dy: -.nodeOverscan)
        for membership in viewModel.overviewMemberships {
            let point = viewModel.camera.screenPoint(for: membership.position, viewport: viewport)
            guard bounds.contains(point), let section = viewModel.section(id: membership.sectionID) else { continue }
            let rectangle = CGRect(
                x: point.x - .overviewNodeRadius,
                y: point.y - .overviewNodeRadius,
                width: .overviewNodeDiameter,
                height: .overviewNodeDiameter
            )
            context.fill(
                Path(ellipseIn: rectangle),
                with: .color(section.accentColor.opacity(.overviewNodeOpacity))
            )
        }
    }

    func screenRectangle(for region: DenseGraphSection.Region, viewport: CGSize) -> CGRect {
        let minimum = viewModel.camera.screenPoint(
            for: GraphPoint(x: region.minimumX, y: region.minimumY),
            viewport: viewport
        )
        let maximum = viewModel.camera.screenPoint(
            for: GraphPoint(x: region.maximumX, y: region.maximumY),
            viewport: viewport
        )
        return CGRect(
            x: minimum.x,
            y: minimum.y,
            width: maximum.x - minimum.x,
            height: maximum.y - minimum.y
        )
    }
}

// MARK: - Section controls

private extension DenseGraphOverviewView {
    func sectionButtons(viewport: CGSize) -> some View {
        ForEach(visibleLabelSections) { section in
            Button {
                onSelectSection(section)
            } label: {
                VStack(spacing: Margin.x1) {
                    Text(section.title)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(.sectionTitleMinimumScale)
                        .allowsTightening(true)
                    Text(L10n.Graph.Industry.peopleCount(section.personCount))
                        .font(.system(size: .sectionCountFontSize, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.horizontal, Margin.x2)
                .padding(.vertical, Margin.x1)
                .frame(width: labelWidth(for: section))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Margin.x4))
                .overlay(
                    RoundedRectangle(cornerRadius: Margin.x4)
                        .stroke(section.accentColor.opacity(.sectionLabelStrokeOpacity))
                )
            }
            .buttonStyle(.plain)
            .position(
                viewModel.camera.screenPoint(
                    for: section.region.center,
                    viewport: viewport
                )
            )
            .accessibilityLabel(L10n.Graph.Industry.zoomHint(section.title, section.personCount))
        }
    }

    func labelWidth(for section: DenseGraphSection) -> CGFloat {
        let regionWidth = section.region.width * viewModel.camera.scale - Margin.x2
        return min(CGFloat(regionWidth), .maximumSectionLabelWidth)
    }

    var visibleLabelSections: [DenseGraphSection] {
        viewModel.graph.sections.filter { section in
            section.region.width * viewModel.camera.scale >= .minimumSectionLabelScreenWidth
                && section.region.height * viewModel.camera.scale >= .minimumSectionLabelScreenHeight
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let maximumSectionLabelWidth = 132.0
    static let nodeOverscan = 4.0
    static let overviewNodeDiameter = overviewNodeRadius * 2
    static let overviewNodeRadius = 1.45
    static let sectionCornerRadius = 10.0
    static let sectionCountFontSize = 8.0
    static let sectionScreenInset = 1.5
    static let sectionStrokeWidth = 0.7
    static let sectionTitleMinimumScale = 0.62
}

private extension Double {
    static let minimumSectionLabelScreenHeight = 42.0
    static let minimumSectionLabelScreenWidth = 58.0
    static let overviewNodeOpacity = 0.82
    static let sectionFillOpacity = 0.07
    static let sectionLabelStrokeOpacity = 0.24
    static let sectionStrokeOpacity = 0.18
}

// MARK: - Preview

#Preview("Industry overview") {
    DenseGraphOverviewView(
        viewModel: DenseGraphViewModel(graph: DenseGraphFixture.performance),
        onSelectSection: { _ in }
    )
    .preferredColorScheme(.dark)
}
