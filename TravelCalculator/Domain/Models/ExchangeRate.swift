import Foundation

struct ExchangeRate: Sendable {
    nonisolated let currency: Currency
    nonisolated let currencyName: String
    nonisolated let rate: Decimal
}

struct ExchangeRateResponse: Sendable {
    nonisolated let rates: [ExchangeRate]
    nonisolated let fetchedAt: Date
    nonisolated let searchDate: String // "yyyyMMdd" KST 기준

    nonisolated func rate(for currency: Currency) -> Decimal? {
        currency == .KRW ? 1 : rates.first { $0.currency == currency }?.rate
    }
}

// MARK: - Codable (nonisolated — @MainActor 기본 격리 우회)

extension ExchangeRate: Codable {
    private enum CodingKeys: String, CodingKey { case currency, currencyName, rate }

    nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currency, forKey: .currency)
        try c.encode(currencyName, forKey: .currencyName)
        try c.encode(rate, forKey: .rate)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.currency = try c.decode(Currency.self, forKey: .currency)
        self.currencyName = try c.decode(String.self, forKey: .currencyName)
        self.rate = try c.decode(Decimal.self, forKey: .rate)
    }
}

extension ExchangeRateResponse: Codable {
    private enum CodingKeys: String, CodingKey { case rates, fetchedAt, searchDate }

    nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rates, forKey: .rates)
        try c.encode(fetchedAt, forKey: .fetchedAt)
        try c.encode(searchDate, forKey: .searchDate)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rates = try c.decode([ExchangeRate].self, forKey: .rates)
        self.fetchedAt = try c.decode(Date.self, forKey: .fetchedAt)
        self.searchDate = try c.decode(String.self, forKey: .searchDate)
    }
}
