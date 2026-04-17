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

    init(userDefaults: UserDefaults = .standard, currencyStore: AppCurrencyStore? = nil) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Self.hasCompletedOnboardingKey)
        self.currencyStore = currencyStore ?? AppCurrencyStore(
            userDefaults: userDefaults,
            exchangeRateAPI: ExchangeRateAPI()
        )
    }

    func makeOnboardingCurrencySelectStore(toastManager: ToastManager) -> CurrencySelectStore {
        CurrencySelectStore(
            toastManager: toastManager,
            currencyStore: currencyStore,
            isOnboarding: true,
            onOnboardingComplete: { self.hasCompletedOnboarding = true },
            locationService: LocationService()
        )
    }
}
