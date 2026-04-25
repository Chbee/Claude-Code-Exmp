import Testing
import Foundation
import Observation
@testable import TravelCalculator

// MARK: - Mock

@MainActor
@Observable
private final class MockNetworkMonitor: NetworkMonitorProtocol {
    var state: NetworkState = .unknown
    func start() {}
}

private func makeResponse(fetchedAt: Date = .now) -> ExchangeRateResponse {
    ExchangeRateResponse(
        rates: [ExchangeRate(currency: .USD, currencyName: "미국 달러", rate: 1350)],
        fetchedAt: fetchedAt,
        searchDate: "20260425",
        validUntil: .distantFuture
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
}
