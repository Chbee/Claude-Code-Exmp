import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CalculatorStore {
    private(set) var state: CalculatorState = .init()

    private let toastManager: ToastManager
    let currencyStore: AppCurrencyStore

    @ObservationIgnored private var wasNegative: Bool = false

    init(toastManager: ToastManager, currencyStore: AppCurrencyStore) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
    }

    var displayModel: CalculatorDisplayModel {
        let currency = currencyStore.selectedCurrency
        let rate = mockRate(for: currency)
        let isInputKRW = currencyStore.conversionDirection == .krwToSelected
        return CalculatorDisplayModel.make(
            state: state,
            inputCurrency: currencyStore.fromCurrency,
            outputCurrency: currencyStore.toCurrency,
            selectedCurrency: currency,
            exchangeRate: rate,
            isInputKRW: isInputKRW
        )
    }

    func send(_ intent: CalculatorIntent) {
        state = CalculatorReducer.reduce(state, intent: intent)
        if let toast = state.pendingToast {
            toastManager.show(toast)
            state.pendingToast = nil
        }

        if case .equalsPressed = intent {
            Haptic.impact(.light)
        }

        let isNegativeNow = state.display.hasPrefix("-")
        if isNegativeNow && !wasNegative {
            toastManager.show(ToastPayload(
                style: .warning,
                title: "음수 결과",
                message: "환율 변환 결과는 0으로 표시됩니다"
            ))
        }
        wasNegative = isNegativeNow
    }

    func toggleDirection() {
        let model = displayModel
        send(.directionTogglePressed(model.resultDisplay.rawAmount))
        currencyStore.conversionDirection = currencyStore.conversionDirection == .selectedToKRW
            ? .krwToSelected
            : .selectedToKRW
        Haptic.impact(.medium)
    }

    private func mockRate(for currency: Currency) -> Decimal {
        switch currency {
        case .USD: return 1350
        case .TWD: return 45
        case .KRW: return 1
        }
    }
}
