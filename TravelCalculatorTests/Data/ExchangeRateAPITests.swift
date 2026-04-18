import Testing
import Foundation
@testable import TravelCalculator

// MARK: - Test Helpers

private actor CallCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

private struct MockURLSession: URLSessionProtocol {
    let handler: @Sendable (URL) async throws -> (Data, URLResponse)

    nonisolated func data(from url: URL) async throws -> (Data, URLResponse) {
        try await handler(url)
    }
}

private func makeHTTPResponse(statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://open.er-api.com/v6/latest/USD")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

private func makeOpenERJSON(
    result: String = "success",
    baseCode: String = "USD",
    timestamp: TimeInterval = 1_713_398_402, // 2024-04-18 UTC → 2024-04-18/19 KST
    rates: [String: Double] = ["USD": 1.0, "KRW": 1350.5, "TWD": 32.0]
) -> Data {
    var ratesJSON = "{"
    ratesJSON += rates.map { "\"\($0.key)\":\($0.value)" }.joined(separator: ",")
    ratesJSON += "}"
    return Data("""
    {"result":"\(result)","base_code":"\(baseCode)","time_last_update_unix":\(Int(timestamp)),"time_next_update_unix":\(Int(timestamp) + 86400),"rates":\(ratesJSON)}
    """.utf8)
}

private func makeTempCacheURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
}

private func todayKST() -> String { Date.now.yyyyMMddKST() }
private func yesterdayKST() -> String {
    Date.now.addingTimeInterval(-86_400).yyyyMMddKST()
}

// MARK: - Network Tests

struct ExchangeRateAPINetworkTests {

    @Test func fetchRates_cacheHit_doesNotCallAPI() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            await counter.increment()
            return (makeOpenERJSON(), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let cached = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1300)],
            fetchedAt: .now,
            searchDate: todayKST()
        )
        try await cache.save(cached)

        let api = ExchangeRateAPI(session: session, cache: cache)
        let response = try await api.fetchRates(for: [.USD])

        let callCount = await counter.count
        #expect(callCount == 0)
        #expect(response.rates.first?.rate == 1300)
    }

    @Test func fetchRates_cachedYesterdayKST_triggersNetworkCall() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            await counter.increment()
            return (makeOpenERJSON(), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let cached = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1300)],
            fetchedAt: .now,
            searchDate: yesterdayKST()
        )
        try await cache.save(cached)

        let api = ExchangeRateAPI(session: session, cache: cache)
        _ = try await api.fetchRates(for: [.USD])

        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test func fetchRates_noCache_apiSuccess_returnsResponse() async throws {
        let session = MockURLSession { _ in (makeOpenERJSON(), makeHTTPResponse()) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache)
        let response = try await api.fetchRates(for: [.USD])

        #expect(response.rates.first?.rate == Decimal(string: "1350.5"))
        let saved = await cache.load()
        #expect(saved != nil)
    }

    @Test func fetchRates_computesCrossRate_USDKRWdividedByUSDX() async throws {
        // KRW=1350, TWD=32 → TWD rate = 1350/32 = 42.1875
        let session = MockURLSession { _ in
            (makeOpenERJSON(rates: ["USD": 1.0, "KRW": 1350.0, "TWD": 32.0]), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache)
        let response = try await api.fetchRates(for: [.USD, .TWD])

        let twd = response.rates.first { $0.currency == .TWD }
        #expect(twd?.rate == Decimal(string: "42.1875"))
    }

    @Test func fetchRates_USDCurrency_rateEqualsUSDKRW() async throws {
        let session = MockURLSession { _ in
            (makeOpenERJSON(rates: ["USD": 1.0, "KRW": 1350.5]), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache)
        let response = try await api.fetchRates(for: [.USD])

        let usd = response.rates.first { $0.currency == .USD }
        #expect(usd?.rate == Decimal(string: "1350.5"))
    }

    @Test func fetchRates_resultError_throwsNoDataAvailable() async throws {
        let session = MockURLSession { _ in (makeOpenERJSON(result: "error"), makeHTTPResponse()) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }

    @Test func fetchRates_baseCodeNotUSD_throwsNoDataAvailable() async throws {
        let session = MockURLSession { _ in (makeOpenERJSON(baseCode: "EUR"), makeHTTPResponse()) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }

    @Test func fetchRates_missingKRWinRates_throwsNoDataAvailable() async throws {
        let session = MockURLSession { _ in
            (makeOpenERJSON(rates: ["USD": 1.0, "TWD": 32.0]), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }

    @Test func fetchRates_missingOneRequestedCurrency_skipsItIfOthersExist() async throws {
        // USD 없음, TWD 있음 → TWD만 반환
        let session = MockURLSession { _ in
            (makeOpenERJSON(rates: ["KRW": 1350.0, "TWD": 32.0]), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        let response = try await api.fetchRates(for: [.USD, .TWD])
        #expect(response.rates.count == 1)
        #expect(response.rates.first?.currency == .TWD)
    }

    @Test func fetchRates_allRequestedCurrenciesMissing_throwsNoDataAvailable() async throws {
        let session = MockURLSession { _ in
            (makeOpenERJSON(rates: ["KRW": 1350.0]), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD, .TWD])
        }
    }

    @Test func fetchRates_zeroOrNegativeUSDRate_currencyIsSkipped() async throws {
        let session = MockURLSession { _ in
            (makeOpenERJSON(rates: ["USD": 0.0, "KRW": 1350.0, "TWD": 32.0]), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        let response = try await api.fetchRates(for: [.USD, .TWD])
        #expect(response.rates.contains { $0.currency == .USD } == false)
        #expect(response.rates.contains { $0.currency == .TWD } == true)
    }

    @Test func fetchRates_searchDate_derivedFromTimeLastUpdateUnixAsKSTyyyyMMdd() async throws {
        // 1_713_398_402 = 2024-04-17 23:20:02 UTC = 2024-04-18 08:20:02 KST → "20240418"
        let ts: TimeInterval = 1_713_398_402
        let expected = Date(timeIntervalSince1970: ts).yyyyMMddKST()
        let session = MockURLSession { _ in (makeOpenERJSON(timestamp: ts), makeHTTPResponse()) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        let response = try await api.fetchRates(for: [.USD])
        #expect(response.searchDate == expected)
    }

    @Test func fetchRates_invalidJSON_throwsParsingError() async throws {
        let session = MockURLSession { _ in (Data("not-json".utf8), makeHTTPResponse()) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }

    @Test func fetchRates_non200_throwsServerError() async throws {
        let session = MockURLSession { _ in (makeOpenERJSON(), makeHTTPResponse(statusCode: 503)) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }

    @Test func fetchRates_apiFailure_returnsStaleCache() async throws {
        let session = MockURLSession { _ in throw URLError(.notConnectedToInternet) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let stale = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1200)],
            fetchedAt: Date(timeIntervalSinceNow: -90_000),
            searchDate: yesterdayKST()
        )
        try await cache.save(stale)

        let api = ExchangeRateAPI(session: session, cache: cache)
        let response = try await api.fetchRates(for: [.USD])

        #expect(response.rates.first?.rate == 1200)
    }

    @Test func fetchRates_apiFailure_noCacheAvailable_throws() async throws {
        let session = MockURLSession { _ in throw URLError(.notConnectedToInternet) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let api = ExchangeRateAPI(session: session, cache: cache)

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }
}
