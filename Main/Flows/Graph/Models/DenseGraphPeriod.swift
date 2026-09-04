import Foundation

struct DenseGraphPeriod: Equatable, Sendable {
    let startYear: Int
    let endYear: Int

    init?(_ value: String) {
        let years = value
            .split { !$0.isNumber }
            .compactMap { component -> Int? in
                guard component.count == 4 else { return nil }
                return Int(component)
            }
        guard let startYear = years.first else { return nil }

        self.startYear = startYear
        if value.contains("н.в.") {
            endYear = .distantFutureYear
        } else {
            endYear = years.dropFirst().first ?? startYear
        }
    }

    func overlaps(_ other: DenseGraphPeriod) -> Bool {
        max(startYear, other.startYear) <= min(endYear, other.endYear)
    }
}

private extension Int {
    static let distantFutureYear = 9_999
}
