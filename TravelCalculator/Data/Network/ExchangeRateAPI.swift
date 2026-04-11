import Foundation

// MARK: - URLSessionProtocol

protocol URLSessionProtocol: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - ExchangeRateCacheActor

actor ExchangeRateCacheActor {
    private let fileURL: URL

    init() {
        self.fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("exchange_rates_cache.json")
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func save(_ response: ExchangeRateResponse) throws {
        let data = try JSONEncoder().encode(response)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() -> ExchangeRateResponse? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
    }

    func isValid(_ response: ExchangeRateResponse) -> Bool {
        Date.now.timeIntervalSince(response.fetchedAt) < 86_400 // 24h
    }

    func delete() throws {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Raw API Response

private struct RawExchangeRate: Codable {
    let cur_unit: String
    let cur_nm: String
    let deal_bas_r: String
    let result: Int
}

// MARK: - ExchangeRateAPI

struct ExchangeRateAPI: ExchangeRateAPIProtocol {
    private let session: any URLSessionProtocol
    private let cache: ExchangeRateCacheActor
    private let apiKey: String

    nonisolated init(
        session: any URLSessionProtocol = URLSession.shared,
        cache: ExchangeRateCacheActor = ExchangeRateCacheActor(),
        apiKey: String = APIKeys.exchangeRateAPIKey
    ) {
        self.session = session
        self.cache = cache
        self.apiKey = apiKey
    }

    func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse {
        let cachedResponse = await cache.load()
        if let cached = cachedResponse, await cache.isValid(cached) {
            return cached
        }

        // 오늘부터 최대 6일 전까지 순차 fallback (주말/공휴일 대응)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        for dayOffset in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            do {
                let response = try await fetchFromAPI(currencies: currencies, searchDate: Self.formatDate(date))
                try? await cache.save(response)
                return response
            } catch ExchangeRateError.noDataAvailable {
                continue
            } catch {
                break
            }
        }

        if let stale = cachedResponse { return stale }
        throw ExchangeRateError.noCacheAvailable
    }

    // MARK: - Internal

    nonisolated static func parseRate(_ raw: String) -> Decimal? {
        let cleaned = raw.replacingOccurrences(of: ",", with: "")
        guard let value = Decimal(string: cleaned), value > 0 else { return nil }
        return value
    }

    private func fetchFromAPI(currencies: [Currency], searchDate: String) async throws -> ExchangeRateResponse {
        var components = URLComponents(string: "https://www.koreaexim.go.kr/site/program/financial/exchangeJSON")!
        components.queryItems = [
            URLQueryItem(name: "authkey", value: apiKey),
            URLQueryItem(name: "searchdate", value: searchDate),
            URLQueryItem(name: "data", value: "AP01")
        ]
        guard let url = components.url else { throw ExchangeRateError.networkError }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.networkError
        }
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.serverError(statusCode: httpResponse.statusCode)
        }

        let rawRates = try JSONDecoder().decode([RawExchangeRate].self, from: data)

        // result != 1: 해당 날짜 데이터 없음 (주말/공휴일)
        guard rawRates.first?.result == 1 else {
            throw ExchangeRateError.noDataAvailable
        }

        let currencyRawValues = Set(currencies.filter { $0 != .KRW }.map { $0.rawValue })
        let rates: [ExchangeRate] = rawRates.compactMap { (raw: RawExchangeRate) -> ExchangeRate? in
            guard currencyRawValues.contains(raw.cur_unit),
                  let currency = Currency(rawValue: raw.cur_unit),
                  let rate = Self.parseRate(raw.deal_bas_r) else { return nil }
            return ExchangeRate(currency: currency, currencyName: raw.cur_nm, rate: rate)
        }

        guard !rates.isEmpty else { throw ExchangeRateError.noDataAvailable }
        return ExchangeRateResponse(rates: rates, fetchedAt: .now, searchDate: searchDate)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
