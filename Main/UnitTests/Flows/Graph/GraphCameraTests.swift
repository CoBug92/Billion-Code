import CoreGraphics
import Testing
@testable import BillionCode

@Suite("Graph camera transform")
struct GraphCameraTests {
    @Test("World center maps to viewport center")
    func centeredProjection() {
        let camera = GraphCamera(center: GraphPoint(x: 5_000, y: 5_000), scale: 0.1)

        let point = camera.screenPoint(
            for: GraphPoint(x: 5_000, y: 5_000),
            viewport: CGSize(width: 390, height: 600)
        )

        #expect(point == CGPoint(x: 195, y: 300))
    }

    @Test("Pan changes only the camera center")
    func panDoesNotMutateWorldPoint() {
        let worldPoint = GraphPoint(x: 4_200, y: 6_100)
        var camera = GraphCamera(center: GraphPoint(x: 5_000, y: 5_000), scale: 0.1)

        camera.pan(by: CGSize(width: 100, height: -50))

        #expect(camera.center == GraphPoint(x: 4_000, y: 5_500))
        #expect(worldPoint == GraphPoint(x: 4_200, y: 6_100))
    }

    @Test("Zoom is clamped to the supported spike range")
    func zoomRange() {
        var camera = GraphCamera(center: GraphPoint(x: 5_000, y: 5_000))

        camera.zoom(by: 100)
        #expect(camera.scale == 0.24)

        camera.zoom(by: 0.001)
        #expect(camera.scale == 0.035)
    }
}
