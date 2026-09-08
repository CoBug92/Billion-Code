import CoreGraphics
import Testing
@testable import BillionCode

struct PortraitSwipeDismissalTests {
    @Test(
        "Свайп закрывает портрет в любом направлении",
        arguments: [
            CGSize(width: 80, height: .zero),
            CGSize(width: -80, height: .zero),
            CGSize(width: .zero, height: 80),
            CGSize(width: .zero, height: -80)
        ]
    )
    func dismissesInEveryDirection(translation: CGSize) {
        #expect(
            PortraitSwipeDismissal.shouldDismiss(
                translation: translation,
                predictedEndTranslation: translation
            )
        )
    }

    @Test("Короткое движение возвращает портрет на место")
    func keepsPortraitForShortMovement() {
        #expect(
            !PortraitSwipeDismissal.shouldDismiss(
                translation: CGSize(width: 20, height: 20),
                predictedEndTranslation: CGSize(width: 30, height: 30)
            )
        )
    }

    @Test("Быстрый короткий свайп закрывает портрет")
    func dismissesForPredictedMomentum() {
        #expect(
            PortraitSwipeDismissal.shouldDismiss(
                translation: CGSize(width: 30, height: .zero),
                predictedEndTranslation: CGSize(width: 150, height: .zero)
            )
        )
    }
}
