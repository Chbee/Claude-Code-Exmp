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
        Date.now < response.validUntil
    }

    func delete() throws {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Raw API Response

private struct OpenERAPIResponse: Decodable {
    let result: String
    let base_code: String
    let time_last_update_unix: TimeInterval
    let time_next_update_unix: TimeInterval
    let rates: [String: Decimal]
}

// MARK: - ExchangeRateAPI

struct ExchangeRateAPI: ExchangeRateAPIProtocol {
    private static let endpoint = URL(string: "https://open.er-api.com/v6/latest/USD")!
    private static let maxAttempts = 3

    // spec §2.5.5: timeout 10s. URLSession.shared(60s)와 분리하기 위한 별도 인스턴스.
    nonisolated private static let defaultSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 10
        cfg.timeoutIntervalForResource = 30
        return URLSession(configuration: cfg)
    }()

    private let session: any URLSessionProtocol
    private let cache: ExchangeRateCacheActor
    private let retryDelay: Duration

    nonisolated init(
        session: any URLSessionProtocol = ExchangeRateAPI.defaultSession,
        cache: ExchangeRateCacheActor = ExchangeRateCacheActor(),
        retryDelay: Duration = .seconds(2)
    ) {
        self.session = session
        self.cache = cache
        self.retryDelay = retryDelay
    }

    func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse {
        let cachedResponse = await cache.load()
        if let cached = cachedResponse, await cache.isValid(cached) {
            return cached
        }

        do {
            let response = try await fetchFromAPI(currencies: currencies)
            try? await cache.save(response)
            return response
        } catch {
            if let stale = cachedResponse { return stale }
            throw ExchangeRateError.noCacheAvailable
        }
    }

    // MARK: - Internal

    private func fetchFromAPI(currencies: [Currency]) async throws -> ExchangeRateResponse {
        var lastError: Error = ExchangeRateError.networkError
        for attempt in 0..<Self.maxAttempts {
            do {
                return try await fetchAttempt(currencies: currencies)
            } catch let error as ExchangeRateError where Self.shouldRetry(error) {
                lastError = error
                if attempt < Self.maxAttempts - 1 {
                    try await Task.sleep(for: retryDelay)
                }
            }
        }
        throw lastError
    }

    private static func shouldRetry(_ error: ExchangeRateError) -> Bool {
        switch error {
        case .networkError: true
        case .serverError(let code): (500...599).contains(code)
        default: false
        }
    }

    private func fetchAttempt(currencies: [Currency]) async throws -> ExchangeRateResponse {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: Self.endpoint)
        } catch {
            throw ExchangeRateError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.networkError
        }
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoded: OpenERAPIResponse
        do {
            decoded = try JSONDecoder().decode(OpenERAPIResponse.self, from: data)
        } catch {
            throw ExchangeRateError.parsingError
        }

        guard decoded.result == "success",
              decoded.base_code == "USD",
              let usdToKrw = decoded.rates["KRW"],
              usdToKrw > 0,
              decoded.time_next_update_unix > 0,
              decoded.time_next_update_unix > decoded.time_last_update_unix else {
            throw ExchangeRateError.noDataAvailable
        }

        let rounding = NSDecimalNumberHandler(
            roundingMode: .bankers,
            scale: 8,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )

        let rates: [ExchangeRate] = currencies
            .filter { $0 != .KRW }
            .compactMap { currency -> ExchangeRate? in
                guard let usdToX = decoded.rates[currency.rawValue], usdToX > 0 else { return nil }
                let cross = (NSDecimalNumber(decimal: usdToKrw)
                    .dividing(by: NSDecimalNumber(decimal: usdToX), withBehavior: rounding))
                    .decimalValue
                return ExchangeRate(currency: currency, currencyName: currencyName(for: currency), rate: cross)
            }

        guard !rates.isEmpty else { throw ExchangeRateError.noDataAvailable }

        let searchDate = Date(timeIntervalSince1970: decoded.time_last_update_unix).yyyyMMddKST()
        let validUntil = Date(timeIntervalSince1970: decoded.time_next_update_unix)
        return ExchangeRateResponse(rates: rates, fetchedAt: .now, searchDate: searchDate, validUntil: validUntil)
    }

    private nonisolated func currencyName(for currency: Currency) -> String {
        switch currency {
        case .KRW: "대한민국 원"
        case .USD: "미국 달러"
        case .TWD: "대만 달러"
        }
    }
}
