struct DenseGraphSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let personCount: Int
    let region: Region
    let accentIndex: Int
}

extension DenseGraphSection {
    struct Region: Equatable, Sendable {
        let minimumX: Double
        let minimumY: Double
        let maximumX: Double
        let maximumY: Double

        var center: GraphPoint {
            GraphPoint(
                x: (minimumX + maximumX) / 2,
                y: (minimumY + maximumY) / 2
            )
        }

        var width: Double {
            maximumX - minimumX
        }

        var height: Double {
            maximumY - minimumY
        }

        func insetBy(dx: Double, dy: Double) -> Region {
            Region(
                minimumX: minimumX + dx,
                minimumY: minimumY + dy,
                maximumX: maximumX - dx,
                maximumY: maximumY - dy
            )
        }
    }
}
