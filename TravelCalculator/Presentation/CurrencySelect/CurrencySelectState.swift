import Foundation

struct CurrencySelectState {
    var currencies: [Currency] = Currency.allCases.filter { $0 != .KRW }
    var selectedCurrency: Currency
    var shouldDismiss: Bool = false
    var isOnboarding: Bool = false
    var isRequestingLocation: Bool = false
}
