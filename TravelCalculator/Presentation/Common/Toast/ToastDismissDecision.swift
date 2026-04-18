import CoreGraphics

nonisolated enum ToastDismissDecision {
    static let distanceThreshold: CGFloat = -40
    static let predictedEndThreshold: CGFloat = -120

    static func shouldDismiss(translation: CGSize, predictedEnd: CGSize) -> Bool {
        translation.height <= distanceThreshold
            || predictedEnd.height <= predictedEndThreshold
    }
}
