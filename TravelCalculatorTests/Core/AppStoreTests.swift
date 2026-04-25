import Testing
import Foundation
@testable import TravelCalculator

@MainActor
struct AppStoreTests {

    private func makeAppStore() -> (AppStore, UserDefaults) {
        let ud = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let store = AppStore(
            userDefaults: ud,
            currencyStore: AppCurrencyStore(userDefaults: ud),
            networkMonitor: MockNetworkMonitor()
        )
        return (store, ud)
    }

    @Test func makeOnboardingCurrencySelectStore_returnsOnboardingStore() {
        let (appStore, _) = makeAppStore()
        let selectStore = appStore.makeOnboardingCurrencySelectStore(toastManager: ToastManager())
        #expect(selectStore.state.isOnboarding == true)
    }

    @Test func makeOnboardingCurrencySelectStore_completionCallback_flipsFlag() {
        let (appStore, _) = makeAppStore()
        #expect(appStore.hasCompletedOnboarding == false)

        let selectStore = appStore.makeOnboardingCurrencySelectStore(toastManager: ToastManager())
        selectStore.send(.selectCurrency(.USD))

        #expect(appStore.hasCompletedOnboarding == true)
    }

    @Test func hasCompletedOnboarding_persistsToUserDefaults() {
        let (appStore, ud) = makeAppStore()
        appStore.hasCompletedOnboarding = true
        #expect(ud.bool(forKey: "hasCompletedOnboarding") == true)
    }
}
