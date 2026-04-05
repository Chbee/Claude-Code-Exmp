import Foundation
import Observation

@MainActor
@Observable
final class CalculatorStore {
    private(set) var state: CalculatorState = .init()

    private let toastManager: ToastManager

    init(toastManager: ToastManager) {
        self.toastManager = toastManager
    }

    func send(_ intent: CalculatorIntent) {
        state = CalculatorReducer.reduce(state, intent: intent)
        if let toast = state.pendingToast {
            toastManager.show(toast)
            state.pendingToast = nil
        }
    }
}
