import Testing
import Foundation
import Observation
@testable import TravelCalculator

// MARK: - Mock

@MainActor
@Observable
private final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isOffline: Bool = false
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

    @Test func isOffline_reflectsNetworkMonitor() {
        let monitor = MockNetworkMonitor()
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud, networkMonitor: monitor)

        #expect(store.isOffline == false)

        monitor.isOffline = true
        #expect(store.isOffline == true)
    }

    @Test func isOffline_defaultsFalse_whenNoMonitor() {
        let ud = UserDefaults(suiteName: "test.offline.\(UUID().uuidString)")!
        let store = AppCurrencyStore(userDefaults: ud)

        #expect(store.isOffline == false)
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
