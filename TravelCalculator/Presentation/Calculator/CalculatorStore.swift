import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CalculatorStore {
    private(set) var state: CalculatorState = .init()

    private let toastManager: ToastManager
    let currencyStore: AppCurrencyStore

    @ObservationIgnored private var previousCurrency: Currency
    @ObservationIgnored private var wasNegative: Bool = false

    init(toastManager: ToastManager, currencyStore: AppCurrencyStore) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
        self.previousCurrency = currencyStore.selectedCurrency
    }

    var displayModel: CalculatorDisplayModel {
        let currency = currencyStore.selectedCurrency
        let rate = mockRate(for: currency)
        let isInputKRW = currencyStore.conversionDirection == .krwToSelected
        return CalculatorDisplayModel.make(
            state: state,
            inputCurrency: currencyStore.fromCurrency,
            outputCurrency: currencyStore.toCurrency,
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

        checkCurrencyChange()
    }

    func toggleDirection() {
        let model = displayModel
        let rawValue = stripFormatting(model.resultDisplay.formattedAmount)
        send(.directionTogglePressed(rawValue))
        currencyStore.conversionDirection = currencyStore.conversionDirection == .selectedToKRW
            ? .krwToSelected
            : .selectedToKRW
        Haptic.impact(.medium)
    }

    private func checkCurrencyChange() {
        let current = currencyStore.selectedCurrency
        if current != previousCurrency {
            previousCurrency = current
            send(.resetForCurrencyChange)
        }
    }

    private func stripFormatting(_ formatted: String) -> String {
        // Remove thousands separators (commas), keep digits, dot, minus sign
        let stripped = formatted.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return stripped.isEmpty ? "0" : stripped
    }

    private func mockRate(for currency: Currency) -> Decimal {
        switch currency {
        case .USD: return 1350
        case .TWD: return 45
        case .KRW: return 1
        }
    }
}
