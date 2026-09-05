import CoreGraphics

struct GraphCamera: Equatable, Sendable {
    private(set) var center: GraphPoint
    private(set) var scale: Double

    init(center: GraphPoint, scale: Double = .defaultGraphScale) {
        self.center = center.clampedToWorld
        self.scale = scale.clamped(to: .minimumGraphScale ... .maximumGraphScale)
    }

    func screenPoint(for worldPoint: GraphPoint, viewport: CGSize) -> CGPoint {
        CGPoint(
            x: viewport.width / 2 + (worldPoint.x - center.x) * scale,
            y: viewport.height / 2 + (worldPoint.y - center.y) * scale
        )
    }

    mutating func recenter(on point: GraphPoint) {
        recenter(
            on: point,
            horizontalRange: .zero ... .graphWorldSide,
            verticalRange: .zero ... .graphWorldSide
        )
    }

    mutating func recenter(
        on point: GraphPoint,
        horizontalRange: ClosedRange<Double>,
        verticalRange: ClosedRange<Double>
    ) {
        center = GraphPoint(
            x: point.x.clamped(to: horizontalRange),
            y: point.y.clamped(to: verticalRange)
        )
    }

    mutating func recenter(on point: GraphPoint, at screenPoint: CGPoint, viewport: CGSize) {
        recenter(
            on: point,
            at: screenPoint,
            viewport: viewport,
            horizontalRange: .zero ... .graphWorldSide,
            verticalRange: .zero ... .graphWorldSide
        )
    }

    mutating func recenter(
        on point: GraphPoint,
        at screenPoint: CGPoint,
        viewport: CGSize,
        horizontalRange: ClosedRange<Double>,
        verticalRange: ClosedRange<Double>
    ) {
        let viewportCenter = CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        center = GraphPoint(
            x: point.x - (screenPoint.x - viewportCenter.x) / scale,
            y: point.y - (screenPoint.y - viewportCenter.y) / scale
        )
        center = GraphPoint(
            x: center.x.clamped(to: horizontalRange),
            y: center.y.clamped(to: verticalRange)
        )
    }

    mutating func pan(by translation: CGSize) {
        pan(
            by: translation,
            horizontalRange: .zero ... .graphWorldSide,
            verticalRange: .zero ... .graphWorldSide
        )
    }

    mutating func pan(
        by translation: CGSize,
        horizontalRange: ClosedRange<Double>,
        verticalRange: ClosedRange<Double>
    ) {
        let nextCenter = GraphPoint(
            x: center.x - translation.width / scale,
            y: center.y - translation.height / scale
        )
        center = GraphPoint(
            x: nextCenter.x.clamped(to: horizontalRange),
            y: nextCenter.y.clamped(to: verticalRange)
        )
    }

    mutating func zoom(by factor: Double) {
        scale = (scale * factor).clamped(to: .minimumGraphScale ... .maximumGraphScale)
    }
}

// MARK: - Private extensions

private extension GraphPoint {
    var clampedToWorld: GraphPoint {
        GraphPoint(
            x: x.clamped(to: .zero ... .graphWorldSide),
            y: y.clamped(to: .zero ... .graphWorldSide)
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    static let defaultGraphScale = 0.04
    static let minimumGraphScale = 0.035
    static let maximumGraphScale = 0.24
    static let graphWorldSide = 10_000.0
}
