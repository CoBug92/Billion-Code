import CoreGraphics

enum Margin {

    // MARK: - Properties

    static let x1: CGFloat = 2
    static let x2: CGFloat = x1 * 2
    static let x3: CGFloat = x1 * 3
    static let x4: CGFloat = x1 * 4
    static let x5: CGFloat = x1 * 5
    static let x6: CGFloat = x1 * 6
    static let x7: CGFloat = x1 * 7
    static let x8: CGFloat = x1 * 8
    static let x9: CGFloat = x1 * 9
    static let x10: CGFloat = x1 * 10

    // MARK: - Public methods

    static func x(_ value: CGFloat) -> CGFloat {
        x1 * value
    }
}
