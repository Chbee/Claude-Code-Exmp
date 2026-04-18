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
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

private func makeAPIJSON(result: Int = 1, dealBasR: String = "1,350.00") -> Data {
    Data("""
    [{"cur_unit":"USD","cur_nm":"미국 달러","deal_bas_r":"\(dealBasR)","result":\(result)}]
    """.utf8)
}

private func makeTempCacheURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
}

// MARK: - Parsing Tests

struct ExchangeRateAPIParsingTests {

    @Test func parseDealBasR_withComma_returnsDecimal() {
        let result = ExchangeRateAPI.parseRate("1,350.50")
        #expect(result == Decimal(string: "1350.50"))
    }

    @Test func parseDealBasR_withoutComma_returnsDecimal() {
        let result = ExchangeRateAPI.parseRate("1350")
        #expect(result == 1350)
    }

    @Test func parseDealBasR_zeroValue_isFiltered() {
        let result = ExchangeRateAPI.parseRate("0")
        #expect(result == nil)
    }

    @Test func parseDealBasR_negativeValue_isFiltered() {
        let result = ExchangeRateAPI.parseRate("-100.00")
        #expect(result == nil)
    }

    @Test func parseDealBasR_invalidString_returnsNil() {
        let result = ExchangeRateAPI.parseRate("N/A")
        #expect(result == nil)
    }
}

// MARK: - Network / Fallback Tests

struct ExchangeRateAPINetworkTests {

    // 유효 캐시가 있으면 API를 호출하지 않음
    @Test func fetchRates_cacheHit_doesNotCallAPI() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            await counter.increment()
            return (makeAPIJSON(), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let cached = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1300)],
            fetchedAt: .now,
            searchDate: "2026-04-11"
        )
        try await cache.save(cached)

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "TEST")
        let response = try await api.fetchRates(for: [.USD])

        let callCount = await counter.count
        #expect(callCount == 0)
        #expect(response.rates.first?.rate == 1300)
    }

    // 캐시 없을 때 API 성공 → 응답 반환 + 캐시 저장
    @Test func fetchRates_noCache_apiSuccess_returnsResponse() async throws {
        let session = MockURLSession { _ in (makeAPIJSON(), makeHTTPResponse()) }
        let cacheURL = makeTempCacheURL()
        let cache = ExchangeRateCacheActor(fileURL: cacheURL)

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "TEST")
        let response = try await api.fetchRates(for: [.USD])

        #expect(response.rates.first?.rate == Decimal(string: "1350.00"))
        // 캐시 저장 확인
        let saved = await cache.load()
        #expect(saved != nil)
    }

    // API 실패 → 만료 캐시 fallback
    @Test func fetchRates_apiFailure_returnsStaleCache() async throws {
        let session = MockURLSession { _ in throw URLError(.notConnectedToInternet) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let stale = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1200)],
            fetchedAt: Date(timeIntervalSinceNow: -90_000), // 25시간 전 (만료)
            searchDate: "2026-04-10"
        )
        try await cache.save(stale)

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "TEST")
        let response = try await api.fetchRates(for: [.USD])

        #expect(response.rates.first?.rate == 1200)
    }

    // API 실패 + 캐시 없음 → .noCacheAvailable throw
    @Test func fetchRates_apiFailure_noCacheAvailable_throws() async throws {
        let session = MockURLSession { _ in throw URLError(.notConnectedToInternet) }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "TEST")

        await #expect(throws: ExchangeRateError.noCacheAvailable) {
            try await api.fetchRates(for: [.USD])
        }
    }

    // API 키 빈 문자열 + 캐시 없음 → .missingAPIKey throw, 네트워크 호출 없음
    @Test func fetchRates_emptyAPIKey_noCache_throwsMissingAPIKey() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            await counter.increment()
            return (makeAPIJSON(), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "")

        await #expect(throws: ExchangeRateError.missingAPIKey) {
            try await api.fetchRates(for: [.USD])
        }
        let callCount = await counter.count
        #expect(callCount == 0)
    }

    // API 키 placeholder + 캐시 없음 → .missingAPIKey throw, 네트워크 호출 없음
    @Test func fetchRates_placeholderAPIKey_noCache_throwsMissingAPIKey() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            await counter.increment()
            return (makeAPIJSON(), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "YOUR_API_KEY_HERE")

        await #expect(throws: ExchangeRateError.missingAPIKey) {
            try await api.fetchRates(for: [.USD])
        }
        let callCount = await counter.count
        #expect(callCount == 0)
    }

    // API 키 placeholder + TTL 만료 캐시 → stale 캐시 반환, 네트워크 호출 없음
    // (TTL 유효 캐시는 상단 gate에서 반환되어 placeholder 가드에 도달하지 않으므로
    //  placeholder 경로의 stale fallback을 검증하려면 fetchedAt이 24h 이전이어야 함)
    @Test func fetchRates_placeholderAPIKey_staleCache_returnsStale() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            await counter.increment()
            return (makeAPIJSON(), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())
        let cached = ExchangeRateResponse(
            rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1300)],
            fetchedAt: Date.now.addingTimeInterval(-90_000), // 25h 전 (TTL 24h 초과)
            searchDate: "2026-04-11"
        )
        try await cache.save(cached)

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "YOUR_API_KEY_HERE")
        let response = try await api.fetchRates(for: [.USD])

        let callCount = await counter.count
        #expect(callCount == 0)
        #expect(response.rates.first?.rate == 1300)
    }

    // 주말/공휴일: 첫 날 result != 1 → 다음 날 시도
    @Test func fetchRates_weekendFallback_triesNextDate() async throws {
        let counter = CallCounter()
        let session = MockURLSession { [counter] _ in
            let n = await counter.count
            await counter.increment()
            // 첫 번째 날짜: result=2 (데이터 없음), 두 번째: result=1
            return n == 0
                ? (makeAPIJSON(result: 2), makeHTTPResponse())
                : (makeAPIJSON(result: 1), makeHTTPResponse())
        }
        let cache = ExchangeRateCacheActor(fileURL: makeTempCacheURL())

        let api = ExchangeRateAPI(session: session, cache: cache, apiKey: "TEST")
        let response = try await api.fetchRates(for: [.USD])

        let callCount = await counter.count
        #expect(callCount == 2)
        #expect(response.rates.first?.rate == Decimal(string: "1350.00"))
    }
}
