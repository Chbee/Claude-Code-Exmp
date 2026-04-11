import Foundation

enum CurrencySelectReducer {
    static func reduce(_ state: CurrencySelectState, intent: CurrencySelectIntent) -> CurrencySelectState {
        var s = state
        switch intent {
        case .selectCurrency(let currency):
            s.selectedCurrency = currency
            s.shouldDismiss = true
        case .dismiss:
            s.shouldDismiss = true
        }
        return s
    }
}
