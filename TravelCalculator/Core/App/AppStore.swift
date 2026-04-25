import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var hasCompletedOnboarding: Bool {
        didSet {
            guard oldValue != hasCompletedOnboarding else { return }
            userDefaults.set(hasCompletedOnboarding, forKey: Self.hasCompletedOnboardingKey)
        }
    }

    let currencyStore: AppCurrencyStore
    let networkMonitor: any NetworkMonitorProtocol

    init(
        userDefaults: UserDefaults = .standard,
        currencyStore: AppCurrencyStore? = nil,
        networkMonitor: any NetworkMonitorProtocol = NetworkMonitor()
    ) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Self.hasCompletedOnboardingKey)
        self.networkMonitor = networkMonitor
        self.currencyStore = currencyStore ?? AppCurrencyStore(
            userDefaults: userDefaults,
            exchangeRateAPI: ExchangeRateAPI(),
            networkMonitor: networkMonitor
        )
    }

    func makeOnboardingCurrencySelectStore(toastManager: ToastManager) -> CurrencySelectStore {
        CurrencySelectStore(
            toastManager: toastManager,
            currencyStore: currencyStore,
            isOnboarding: true,
            onOnboardingComplete: { [weak self] in self?.hasCompletedOnboarding = true },
            locationService: LocationService()
        )
    }
}
