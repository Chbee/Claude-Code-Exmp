import Testing
@testable import TravelCalculator

struct ExchangeRateTests {

    // MARK: - rate(for:)

    @Test func rateForKRWAlwaysReturnsOne() {
        let response = ExchangeRateResponse(
            rates: [],
            fetchedAt: .now,
            searchDate: "20260411",
            validUntil: .distantFuture
        )
        #expect(response.rate(for: .KRW) == 1)
    }

    @Test func rateForKnownCurrencyReturnsCorrectRate() {
        let response = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1350)],
            fetchedAt: .now,
            searchDate: "20260411",
            validUntil: .distantFuture
        )
        #expect(response.rate(for: .USD) == 1350)
    }

    @Test func rateForMissingCurrencyReturnsNil() {
        let response = ExchangeRateResponse(
            rates: [],
            fetchedAt: .now,
            searchDate: "20260411",
            validUntil: .distantFuture
        )
        #expect(response.rate(for: .USD) == nil)
    }
}
