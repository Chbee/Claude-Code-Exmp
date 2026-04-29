import Foundation

struct CurrencySelectState {
    var currencies: [Currency] = Currency.allCases.filter { $0 != .KRW }
    var selectedCurrency: Currency
    var shouldDismiss: Bool = false
    var isOnboarding: Bool = false
    var isRequestingLocation: Bool = false
    var searchQuery: String = ""

    var filteredCurrencies: [Currency] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return currencies }
        return currencies.filter {
            $0.countryName.localizedCaseInsensitiveContains(q)
                || $0.currencyUnit.localizedCaseInsensitiveContains(q)
        }
    }
}
