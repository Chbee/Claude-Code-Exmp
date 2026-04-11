import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CurrencySelectStore {
    private(set) var state: CurrencySelectState

    private let toastManager: ToastManager
    private let currencyStore: AppCurrencyStore

    init(toastManager: ToastManager, currencyStore: AppCurrencyStore) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
        self.state = CurrencySelectState(selectedCurrency: currencyStore.selectedCurrency)
    }

    func send(_ intent: CurrencySelectIntent) {
        let previousCurrency = state.selectedCurrency
        state = CurrencySelectReducer.reduce(state, intent: intent)

        // 동일 통화 재선택 시 중복 toast/haptic 방지
        if state.selectedCurrency != previousCurrency {
            currencyStore.selectedCurrency = state.selectedCurrency
            Haptic.notification(.success)
            toastManager.show(ToastPayload(
                style: .success,
                title: "통화 변경 완료",
                message: "\(state.selectedCurrency.flag) \(state.selectedCurrency.currencyUnit)"
            ))
        }
    }
}
