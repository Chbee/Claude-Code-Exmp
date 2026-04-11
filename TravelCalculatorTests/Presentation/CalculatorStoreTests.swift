import Testing
import Foundation
@testable import TravelCalculator

private func makeResponse(rate: Decimal) -> ExchangeRateResponse {
    ExchangeRateResponse(
        rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: rate)],
        fetchedAt: .now,
        searchDate: "20260410"
    )
}

@MainActor
struct CalculatorStoreDisplayModelTests {

    @Test func displayModel_usesRealRate_whenLoaded() {
        let currencyStore = AppCurrencyStore()
        currencyStore.exchangeRateStatus = .loaded(makeResponse(rate: 1234))
        let store = CalculatorStore(toastManager: ToastManager(), currencyStore: currencyStore)

        #expect(store.displayModel.rateDisplay == "1 USD = 1,234 KRW")
    }

    @Test func displayModel_usesZeroRate_whenLoading() {
        let currencyStore = AppCurrencyStore()
        currencyStore.exchangeRateStatus = .loading
        let store = CalculatorStore(toastManager: ToastManager(), currencyStore: currencyStore)

        #expect(store.displayModel.rateDisplay == "1 USD = 0 KRW")
    }
}
