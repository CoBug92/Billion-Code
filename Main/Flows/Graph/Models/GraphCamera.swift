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
        center = point.clampedToWorld
    }

    mutating func pan(by translation: CGSize) {
        let nextCenter = GraphPoint(
            x: center.x - translation.width / scale,
            y: center.y - translation.height / scale
        )
        center = nextCenter.clampedToWorld
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
