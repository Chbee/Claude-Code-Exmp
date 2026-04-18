import Foundation

struct ExchangeRate: Sendable {
    nonisolated let currency: Currency
    nonisolated let currencyName: String
    nonisolated let rate: Decimal
}

struct ExchangeRateResponse: Sendable {
    nonisolated let rates: [ExchangeRate]
    nonisolated let fetchedAt: Date
    // 표시 전용 — cache validity 판정에 사용 금지 (API 발행 UTC→KST 변환이라 날짜 경계 어긋남).
    nonisolated let searchDate: String
    // API의 `time_next_update_unix` 기반 만료 시각 — isValid/isRefreshEnabled 기준.
    nonisolated let validUntil: Date

    nonisolated func rate(for currency: Currency) -> Decimal? {
        currency == .KRW ? 1 : rates.first { $0.currency == currency }?.rate
    }
}

// MARK: - Codable (nonisolated — JSONEncoder/Decoder의 비MainActor 호출 허용)

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
    private enum CodingKeys: String, CodingKey { case rates, fetchedAt, searchDate, validUntil }

    nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rates, forKey: .rates)
        try c.encode(fetchedAt, forKey: .fetchedAt)
        try c.encode(searchDate, forKey: .searchDate)
        try c.encode(validUntil, forKey: .validUntil)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rates = try c.decode([ExchangeRate].self, forKey: .rates)
        self.fetchedAt = try c.decode(Date.self, forKey: .fetchedAt)
        self.searchDate = try c.decode(String.self, forKey: .searchDate)
        // 레거시 캐시는 validUntil 필드가 없음 → distantPast로 두어 즉시 invalid 처리, 자동 재fetch.
        self.validUntil = try c.decodeIfPresent(Date.self, forKey: .validUntil) ?? .distantPast
    }
}
