import Testing
import Foundation
@testable import TravelCalculator

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
