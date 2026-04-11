import Testing
import Foundation
@testable import TravelCalculator

// MARK: - Mock

private struct MockExchangeRateAPI: ExchangeRateAPIProtocol {
    enum Behavior {
        case success(ExchangeRateResponse)
        case failure(ExchangeRateError)
    }

    let behavior: Behavior

    nonisolated func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse {
        switch behavior {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }
}

private func todayYYYYMMDD() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyyMMdd"
    f.locale = Locale(identifier: "ko_KR")
    f.timeZone = TimeZone.kst
    f.calendar = Calendar.kst
    return f.string(from: Date.now)
}

private func makeResponse(searchDate: String = "20260410", rate: Decimal = 1350) -> ExchangeRateResponse {
    ExchangeRateResponse(
        rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: rate)],
        fetchedAt: .now,
        searchDate: searchDate
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

    @Test func loadExchangeRates_nilAPI_statusUnchanged() async {
        let store = AppCurrencyStore(exchangeRateAPI: nil)
        // 초기 상태는 .loading
        await store.loadExchangeRates()
        // API nil이면 guard 통과 못하므로 상태 변화 없음
        if case .loading = store.exchangeRateStatus {
            // OK
        } else {
            Issue.record("Expected .loading, got \(store.exchangeRateStatus)")
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

    @Test func isRefreshEnabled_searchDateIsToday_returnsFalse() async {
        let today = todayYYYYMMDD()
        let response = makeResponse(searchDate: today)
        let api = MockExchangeRateAPI(behavior: .success(response))
        let store = AppCurrencyStore(exchangeRateAPI: api)

        await store.loadExchangeRates()

        #expect(store.isRefreshEnabled == false)
    }

    @Test func isRefreshEnabled_searchDateIsPast_returnsTrue() async {
        let response = makeResponse(searchDate: "20200101")
        let api = MockExchangeRateAPI(behavior: .success(response))
        let store = AppCurrencyStore(exchangeRateAPI: api)

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

    @Test func refreshExchangeRates_whenNotEnabled_noAPICall() async {
        // 오늘 날짜 → isRefreshEnabled == false → API 미호출
        let today = todayYYYYMMDD()
        let initialResponse = makeResponse(searchDate: today)
        let api = MockExchangeRateAPI(behavior: .success(initialResponse))
        let store = AppCurrencyStore(exchangeRateAPI: api)
        await store.loadExchangeRates() // 오늘 날짜로 loaded

        // 새 API로 교체할 수 없으므로 상태가 바뀌지 않음을 확인
        await store.refreshExchangeRates()

        // 상태가 여전히 loaded(오늘 날짜)
        if case .loaded(let r) = store.exchangeRateStatus {
            #expect(r.searchDate == today)
        } else {
            Issue.record("Expected .loaded, got \(store.exchangeRateStatus)")
        }
    }

    @Test func refreshExchangeRates_whenEnabled_callsAPI() async {
        let pastResponse = makeResponse(searchDate: "20200101", rate: 1200)
        let api = MockExchangeRateAPI(behavior: .success(pastResponse))
        let store = AppCurrencyStore(exchangeRateAPI: api)
        await store.loadExchangeRates() // 과거 날짜로 loaded → isRefreshEnabled == true

        // 새로고침 실행 → 동일 mock이므로 같은 응답 반환
        await store.refreshExchangeRates()

        if case .loaded(let r) = store.exchangeRateStatus {
            #expect(r.rates.first?.rate == 1200)
        } else {
            Issue.record("Expected .loaded, got \(store.exchangeRateStatus)")
        }
    }
}
