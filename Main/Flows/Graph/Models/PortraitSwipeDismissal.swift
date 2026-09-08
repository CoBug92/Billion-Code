import CoreGraphics

struct PortraitSwipeDismissal {
    static func shouldDismiss(
        translation: CGSize,
        predictedEndTranslation: CGSize
    ) -> Bool {
        translation.magnitude >= .dismissalDistance
            || predictedEndTranslation.magnitude >= .predictedDismissalDistance
    }

    static func exitOffset(
        translation: CGSize,
        predictedEndTranslation: CGSize,
        distance: CGFloat
    ) -> CGSize {
        let vector = predictedEndTranslation.magnitude > translation.magnitude
            ? predictedEndTranslation
            : translation
        let magnitude = max(vector.magnitude, 1)
        return CGSize(
            width: vector.width / magnitude * distance,
            height: vector.height / magnitude * distance
        )
    }
}

private extension CGSize {
    var magnitude: CGFloat {
        hypot(width, height)
    }
}

private extension CGFloat {
    static let dismissalDistance = 72.0
    static let predictedDismissalDistance = 132.0
}
