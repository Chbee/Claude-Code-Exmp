import Testing
import CoreGraphics
@testable import TravelCalculator

struct ToastDismissDecisionTests {
    @Test
    func distanceOverThresholdDismisses() {
        let decision = ToastDismissDecision.shouldDismiss(
            translation: CGSize(width: 0, height: -50),
            predictedEnd: CGSize(width: 0, height: -60)
        )
        #expect(decision == true)
    }

    @Test
    func predictedEndOverThresholdDismisses() {
        let decision = ToastDismissDecision.shouldDismiss(
            translation: CGSize(width: 0, height: -10),
            predictedEnd: CGSize(width: 0, height: -200)
        )
        #expect(decision == true)
    }

    @Test
    func smallUpwardDragDoesNotDismiss() {
        let decision = ToastDismissDecision.shouldDismiss(
            translation: CGSize(width: 0, height: -20),
            predictedEnd: CGSize(width: 0, height: -30)
        )
        #expect(decision == false)
    }

    @Test
    func downwardDragDoesNotDismiss() {
        let decision = ToastDismissDecision.shouldDismiss(
            translation: CGSize(width: 0, height: 80),
            predictedEnd: CGSize(width: 0, height: 200)
        )
        #expect(decision == false)
    }
}
