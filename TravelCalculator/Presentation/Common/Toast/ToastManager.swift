import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class ToastManager {
    var currentToast: ToastPayload?

    @ObservationIgnored
    private var dismissTask: Task<Void, Never>?

    @ObservationIgnored
    private let animation = Animation.spring(response: 0.45, dampingFraction: 0.86)

    func show(_ payload: ToastPayload) {
        dismissTask?.cancel()
        withAnimation(animation) {
            currentToast = payload
        }
        triggerHaptic(for: payload.style)
        scheduleDismiss(for: payload)
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        guard currentToast != nil else { return }
        withAnimation(animation) {
            currentToast = nil
        }
    }

    private func scheduleDismiss(for payload: ToastPayload) {
        let nanoseconds = UInt64(max(payload.duration, 0) * 1_000_000_000)
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            self.dismiss()
        }
    }

    private func triggerHaptic(for style: ToastStyle) {
        switch style {
        case .success:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.success)
        case .info:
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred(intensity: 0.9)
        case .warning:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.warning)
        case .error:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.error)
        }
    }
}
