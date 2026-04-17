import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CurrencySelectStore {
    private(set) var state: CurrencySelectState

    private let toastManager: ToastManager
    private let currencyStore: AppCurrencyStore
    private let onOnboardingComplete: (@MainActor @Sendable () -> Void)?

    init(
        toastManager: ToastManager,
        currencyStore: AppCurrencyStore,
        isOnboarding: Bool = false,
        onOnboardingComplete: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
        self.onOnboardingComplete = onOnboardingComplete
        var initial = CurrencySelectState(selectedCurrency: currencyStore.selectedCurrency)
        initial.isOnboarding = isOnboarding
        self.state = initial
    }

    func send(_ intent: CurrencySelectIntent) {
        let previousCurrency = state.selectedCurrency
        state = CurrencySelectReducer.reduce(state, intent: intent)

        switch intent {
        case .selectCurrency:
            if state.selectedCurrency != previousCurrency {
                currencyStore.selectedCurrency = state.selectedCurrency
                Haptic.notification(.success)
                if !state.isOnboarding {
                    toastManager.show(ToastPayload(
                        style: .success,
                        title: "통화 변경 완료",
                        message: "\(state.selectedCurrency.flag) \(state.selectedCurrency.currencyUnit)"
                    ))
                }
            }
            if state.isOnboarding {
                currencyStore.conversionDirection = .selectedToKRW
                onOnboardingComplete?()
            }
        case .dismiss:
            break
        }
    }
}
