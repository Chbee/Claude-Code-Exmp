import Testing
import Foundation
@testable import TravelCalculator

private func makeResponse(fetchedAt: Date = .now, validUntil: Date = .distantFuture) -> ExchangeRateResponse {
    ExchangeRateResponse(
        rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1350)],
        fetchedAt: fetchedAt,
        searchDate: "20260425",
        validUntil: validUntil
    )
}

// MARK: - Tests

@MainActor
struct AppCurrencyStoreOfflineTests {

    @Test func networkState_reflectsMonitor() {
        let monitor = MockNetworkMonitor()
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)

        #expect(store.networkState == .unknown)

        monitor.state = .online
        #expect(store.networkState == .online)

        monitor.state = .offline
        #expect(store.networkState == .offline)
    }

    @Test func networkState_defaultsUnknown_whenNoMonitor() {
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud)

        #expect(store.networkState == .unknown)
    }

    @Test func isOffline_isTrueOnlyWhenStateIsOffline() {
        let monitor = MockNetworkMonitor()
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)

        monitor.state = .unknown
        #expect(store.isOffline == false)

        monitor.state = .online
        #expect(store.isOffline == false)

        monitor.state = .offline
        #expect(store.isOffline == true)
    }

    @Test func cachedAt_isNilWhenNoResponse() {
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud)

        #expect(store.cachedAt == nil)
    }

    @Test func cachedAt_returnsResponseFetchedAt() {
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        store.exchangeRateStatus = .loaded(makeResponse(fetchedAt: now))

        #expect(store.cachedAt == now)
    }

    @Test func isRefreshEnabled_trueWhenOnlineAndExpired() {
        let monitor = MockNetworkMonitor()
        monitor.state = .online
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)
        store.exchangeRateStatus = .loaded(makeResponse(validUntil: .distantPast))

        #expect(store.isRefreshEnabled == true)
    }

    @Test func isRefreshEnabled_falseWhenOfflineEvenIfExpired() {
        let monitor = MockNetworkMonitor()
        monitor.state = .offline
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)
        store.exchangeRateStatus = .loaded(makeResponse(validUntil: .distantPast))

        #expect(store.isRefreshEnabled == false)
    }

    @Test func isRefreshEnabled_falseWhenUnknown() {
        let monitor = MockNetworkMonitor()
        monitor.state = .unknown
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)
        store.exchangeRateStatus = .loaded(makeResponse(validUntil: .distantPast))

        #expect(store.isRefreshEnabled == false)
    }

    @Test func isRefreshEnabled_falseWhenOnlineButNotExpired() {
        let monitor = MockNetworkMonitor()
        monitor.state = .online
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)
        store.exchangeRateStatus = .loaded(makeResponse(validUntil: .distantFuture))

        #expect(store.isRefreshEnabled == false)
    }
}
