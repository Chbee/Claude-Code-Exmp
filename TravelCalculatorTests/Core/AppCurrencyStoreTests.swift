import Testing
import Foundation
@testable import TravelCalculator

// MARK: - Mocks

private struct MockExchangeRateAPI: ExchangeRateAPIProtocol {
    enum Behavior: Sendable {
        case success(ExchangeRateResponse)
        case failure(ExchangeRateError)
    }

    let behavior: Behavior
    let counter: Counter?

    actor Counter { private(set) var count = 0; func increment() { count += 1 } }

    init(behavior: Behavior, counter: Counter? = nil) {
        self.behavior = behavior
        self.counter = counter
    }

    nonisolated func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse {
        await counter?.increment()
        switch behavior {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }
}

private func makeResponse(
    searchDate: String = "20260410",
    rate: Decimal = 1350,
    validUntil: Date = .distantFuture
) -> ExchangeRateResponse {
    ExchangeRateResponse(
        rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: rate)],
        fetchedAt: .now,
        searchDate: searchDate,
        validUntil: validUntil
    )
}

// MARK: - loadExchangeRates Tests

@MainActor
struct AppCurrencyStoreLoadTests {

    @Test func loadExchangeRates_success_setsLoadedStatus() async {
        let response = makeResponse()
        let api = MockExchangeRateAPI(behavior: .success(response))
        let store = AppCurrencyStore(exchangeRateAPI: api)

        await store.loadExchangeRates()

        if case .loaded(let r) = store.exchangeRateStatus {
            #expect(r.searchDate == "20260410")
        } else {
            Issue.record("Expected .loaded, got \(store.exchangeRateStatus)")
        }
    }

    @Test func loadExchangeRates_failure_setsErrorStatus() async {
        let api = MockExchangeRateAPI(behavior: .failure(.noCacheAvailable))
        let store = AppCurrencyStore(exchangeRateAPI: api)

        await store.loadExchangeRates()

        if case .error(let e) = store.exchangeRateStatus {
            #expect(e == .noCacheAvailable)
        } else {
            Issue.record("Expected .error, got \(store.exchangeRateStatus)")
        }
    }

    @Test func loadExchangeRates_nilAPI_setsNoCacheError() async {
        let store = AppCurrencyStore(exchangeRateAPI: nil)
        await store.loadExchangeRates()
        if case .error(let e) = store.exchangeRateStatus {
            #expect(e == .noCacheAvailable)
        } else {
            Issue.record("Expected .error(.noCacheAvailable), got \(store.exchangeRateStatus)")
        }
    }
}

// MARK: - Computed Property Tests

@MainActor
struct AppCurrencyStoreComputedTests {

    @Test func currentRate_whenLoaded_returnsCorrectRate() async {
        let response = makeResponse(rate: 1350)
        let api = MockExchangeRateAPI(behavior: .success(response))
        let store = AppCurrencyStore(exchangeRateAPI: api)
        store.selectedCurrency = .USD

        await store.loadExchangeRates()

        #expect(store.currentRate == 1350)
    }

    @Test func currentRate_whenNotLoaded_returnsNil() {
        let store = AppCurrencyStore(exchangeRateAPI: nil)
        #expect(store.currentRate == nil)
    }

    @Test func isRefreshEnabled_whenCacheBeforeValidUntil_returnsFalse() async {
        let response = makeResponse(validUntil: Date(timeIntervalSinceNow: 3600))
        let api = MockExchangeRateAPI(behavior: .success(response))
        let store = AppCurrencyStore(exchangeRateAPI: api)

        await store.loadExchangeRates()

        #expect(store.isRefreshEnabled == false)
    }

    @Test func isRefreshEnabled_whenCacheAfterValidUntil_returnsTrue() async {
        let response = makeResponse(validUntil: Date(timeIntervalSinceNow: -3600))
        let api = MockExchangeRateAPI(behavior: .success(response))
        let store = AppCurrencyStore(exchangeRateAPI: api, networkMonitor: MockNetworkMonitor(state: .online))

        await store.loadExchangeRates()

        #expect(store.isRefreshEnabled == true)
    }

    @Test func isRefreshEnabled_whenNotLoaded_returnsFalse() {
        let store = AppCurrencyStore(exchangeRateAPI: nil)
        #expect(store.isRefreshEnabled == false)
    }
}

// MARK: - refreshExchangeRates Tests

@MainActor
struct AppCurrencyStoreRefreshTests {

    @Test func refreshExchangeRates_whenOffline_noAPICall() async {
        let validResponse = makeResponse(validUntil: .distantFuture)
        let counter = MockExchangeRateAPI.Counter()
        let api = MockExchangeRateAPI(behavior: .success(validResponse), counter: counter)
        let store = AppCurrencyStore(
            exchangeRateAPI: api,
            networkMonitor: MockNetworkMonitor(state: .offline)
        )
        await store.loadExchangeRates()
        let initial = await counter.count

        await store.refreshExchangeRates()

        let after = await counter.count
        #expect(after == initial)
    }

    @Test func refreshExchangeRates_whenOnlineAndStoreLoaded_bypassesLoadedGate() async {
        // store의 .loaded 가드를 force=true로 우회 → api.fetchRates 호출이 일어나는 것까지만 검증.
        // 실 ExchangeRateAPI는 자체 캐시(validUntil 이전이면 즉시 반환)가 있어 네트워크는 호출되지 않으나,
        // 그 캐시 우선 동작은 ExchangeRateAPITests에서 별도 검증한다 (MockAPI는 캐시 layer 없음).
        let freshResponse = makeResponse(validUntil: .distantFuture)
        let counter = MockExchangeRateAPI.Counter()
        let api = MockExchangeRateAPI(behavior: .success(freshResponse), counter: counter)
        let store = AppCurrencyStore(
            exchangeRateAPI: api,
            networkMonitor: MockNetworkMonitor(state: .online)
        )
        await store.loadExchangeRates()
        let initial = await counter.count

        await store.refreshExchangeRates()

        let after = await counter.count
        #expect(after == initial + 1)
    }

    @Test func refreshExchangeRates_whenEnabled_bypassesLoadedGate() async {
        // 만료된 캐시 → .loaded 상태지만 isRefreshEnabled=true → 새 API 호출 트리거
        let expiredResponse = makeResponse(validUntil: Date(timeIntervalSinceNow: -3600))
        let counter = MockExchangeRateAPI.Counter()
        let api = MockExchangeRateAPI(behavior: .success(expiredResponse), counter: counter)
        let store = AppCurrencyStore(exchangeRateAPI: api, networkMonitor: MockNetworkMonitor(state: .online))
        await store.loadExchangeRates()
        let firstCount = await counter.count
        #expect(firstCount == 1)

        await store.refreshExchangeRates()

        // force 경로로 .loaded 게이트를 우회하고 API 재호출되어야 함
        let secondCount = await counter.count
        #expect(secondCount == 2)
    }
}
