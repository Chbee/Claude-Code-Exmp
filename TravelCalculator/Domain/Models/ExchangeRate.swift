import Foundation

struct ExchangeRate: Codable, Sendable {
    let currency: Currency
    let currencyName: String
    let rate: Decimal
}

struct ExchangeRateResponse: Codable, Sendable {
    let rates: [ExchangeRate]
    let fetchedAt: Date
    let searchDate: String // "yyyy-MM-dd" KST 기준

    nonisolated func rate(for currency: Currency) -> Decimal? {
        currency == .KRW ? 1 : rates.first { $0.currency == currency }?.rate
    }
}
