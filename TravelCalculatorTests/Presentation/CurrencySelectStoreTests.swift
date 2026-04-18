import Testing
import Foundation
@testable import TravelCalculator

@MainActor
final class MockCountryCodeProvider: CurrentCountryCodeProvider {
    enum Outcome {
        case success(String)
        case failure(LocationError)
    }
    var outcome: Outcome = .success("KR")
    var callCount = 0

    func requestCurrentCountryCode() async throws -> String {
        callCount += 1
        switch outcome {
        case .success(let code): return code
        case .failure(let err): throw err
        }
    }
}

@MainActor
struct CurrencySelectStoreOnboardingTests {

    @Test func onboarding_selectCurrency_callsCompleteCallback_andSetsDirection() {
        let currencyStore = AppCurrencyStore()
        currencyStore.conversionDirection = .krwToSelected

        var completeCount = 0
        let store = CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: currencyStore,
            isOnboarding: true,
            onOnboardingComplete: { completeCount += 1 }
        )

        store.send(.selectCurrency(.USD))

        #expect(completeCount == 1)
        #expect(currencyStore.conversionDirection == .selectedToKRW)
        #expect(currencyStore.selectedCurrency == .USD)
        #expect(store.state.isOnboarding == true)
    }

    @Test func onboarding_reselectSameCurrency_stillCompletes() {
        let currencyStore = AppCurrencyStore()
        currencyStore.selectedCurrency = .USD

        var completeCount = 0
        let store = CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: currencyStore,
            isOnboarding: true,
            onOnboardingComplete: { completeCount += 1 }
        )

        store.send(.selectCurrency(.USD))

        #expect(completeCount == 1)
        #expect(currencyStore.conversionDirection == .selectedToKRW)
    }

    @Test func normalMode_selectCurrency_doesNotCallCompleteCallback() {
        let currencyStore = AppCurrencyStore()

        var completeCount = 0
        let store = CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: currencyStore,
            isOnboarding: false,
            onOnboardingComplete: { completeCount += 1 }
        )

        store.send(.selectCurrency(.USD))

        #expect(completeCount == 0)
        #expect(store.state.isOnboarding == false)
    }

    @Test func defaultInit_isNormalMode() {
        let store = CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: AppCurrencyStore()
        )
        #expect(store.state.isOnboarding == false)
    }
}

@MainActor
struct CurrencySelectStoreLocationTests {

    private func makeStore(
        outcome: MockCountryCodeProvider.Outcome,
        isOnboarding: Bool = false,
        onComplete: (@MainActor @Sendable () -> Void)? = nil
    ) -> (CurrencySelectStore, AppCurrencyStore, ToastManager, MockCountryCodeProvider) {
        let provider = MockCountryCodeProvider()
        provider.outcome = outcome
        let toastManager = ToastManager()
        let ud = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let currencyStore = AppCurrencyStore(userDefaults: ud)
        let store = CurrencySelectStore(
            toastManager: toastManager,
            currencyStore: currencyStore,
            isOnboarding: isOnboarding,
            onOnboardingComplete: onComplete,
            locationService: provider
        )
        return (store, currencyStore, toastManager, provider)
    }

    @Test func requestLocation_korea_showsInfoToast_keepsCurrency() async {
        let (store, currencyStore, toastManager, _) = makeStore(outcome: .success("KR"))
        currencyStore.selectedCurrency = .USD

        store.send(.requestLocation)
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(currencyStore.selectedCurrency == .USD)
        #expect(toastManager.currentToast?.style == .info)
    }

    @Test func requestLocation_supportedForeign_selectsCurrency() async {
        let (store, currencyStore, toastManager, _) = makeStore(outcome: .success("US"))
        currencyStore.selectedCurrency = .TWD

        store.send(.requestLocation)
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(currencyStore.selectedCurrency == .USD)
        #expect(toastManager.currentToast?.style == .success)
    }

    @Test func requestLocation_unsupported_showsWarningToast() async {
        let (store, currencyStore, toastManager, _) = makeStore(outcome: .success("JP"))
        currencyStore.selectedCurrency = .USD

        store.send(.requestLocation)
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(currencyStore.selectedCurrency == .USD)
        #expect(toastManager.currentToast?.style == .warning)
    }

    @Test func requestLocation_permissionDenied_showsInfoToast() async {
        let (store, _, toastManager, _) = makeStore(outcome: .failure(.permissionDenied))

        store.send(.requestLocation)
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(toastManager.currentToast?.style == .info)
    }

    @Test func requestLocation_unavailable_showsErrorToast() async {
        let (store, _, toastManager, _) = makeStore(outcome: .failure(.unavailable))

        store.send(.requestLocation)
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(toastManager.currentToast?.style == .error)
    }

    @Test func requestLocation_onboardingMode_supportedForeign_completes() async {
        var completeCount = 0
        let (store, currencyStore, _, _) = makeStore(
            outcome: .success("TW"),
            isOnboarding: true,
            onComplete: { completeCount += 1 }
        )
        currencyStore.conversionDirection = .krwToSelected

        store.send(.requestLocation)
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(currencyStore.selectedCurrency == .TWD)
        #expect(currencyStore.conversionDirection == .selectedToKRW)
        #expect(completeCount == 1)
    }

    @Test func requestLocation_loadingFlag_transitions() async {
        let (store, _, _, _) = makeStore(outcome: .success("US"))

        #expect(store.state.isRequestingLocation == false)
        store.send(.requestLocation)
        // 시작 직후 플래그는 true 여야 함
        #expect(store.state.isRequestingLocation == true)
        while store.state.isRequestingLocation { await Task.yield() }
        #expect(store.state.isRequestingLocation == false)
    }

    @Test func requestLocation_whileLoading_isIgnored() async {
        let (store, _, _, provider) = makeStore(outcome: .success("US"))

        store.send(.requestLocation)
        store.send(.requestLocation)  // 두 번째 즉시 호출
        while store.state.isRequestingLocation { await Task.yield() }

        #expect(provider.callCount == 1)
    }
}

@Suite struct CurrencyFromCountryCodeTests {
    @Test func kr_mapsToKRW() { #expect(Currency.from(countryCode: "KR") == .KRW) }
    @Test func us_mapsToUSD() { #expect(Currency.from(countryCode: "US") == .USD) }
    @Test func tw_mapsToTWD() { #expect(Currency.from(countryCode: "TW") == .TWD) }
    @Test func lowercase_handled() { #expect(Currency.from(countryCode: "us") == .USD) }
    @Test func unsupported_returnsNil() { #expect(Currency.from(countryCode: "JP") == nil) }
}
