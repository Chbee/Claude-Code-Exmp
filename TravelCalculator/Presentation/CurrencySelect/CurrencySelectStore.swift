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
        switch intent {
        case .selectCurrency(let currency):
            guard currency != state.selectedCurrency else { return }
            currencyStore.selectedCurrency = currency
            state.selectedCurrency = currency
            toastManager.show(ToastPayload(
                style: .success,
                title: "통화 변경 완료",
                message: "\(currency.flag) \(currency.currencyUnit)"
            ))
            state.shouldDismiss = true

        case .dismiss:
            state.shouldDismiss = true
        }
    }
}
