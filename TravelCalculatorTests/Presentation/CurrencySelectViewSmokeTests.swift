import Testing
import SwiftUI
import UIKit
@testable import TravelCalculator

@MainActor
struct CurrencySelectViewSmokeTests {

    @Test func renders_inOnboardingMode_withoutCrash() {
        let store = CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: AppCurrencyStore(),
            isOnboarding: true
        )
        let hosting = UIHostingController(rootView: CurrencySelectView(store: store))
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        #expect(hosting.view.bounds.size.width > 0)
        #expect(hosting.view.bounds.size.height > 0)
    }

    @Test func renders_inRegularMode_withoutCrash() {
        let store = CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: AppCurrencyStore(),
            isOnboarding: false
        )
        let hosting = UIHostingController(rootView: CurrencySelectView(store: store))
        hosting.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hosting.view.layoutIfNeeded()

        #expect(hosting.view.bounds.size.width > 0)
        #expect(hosting.view.bounds.size.height > 0)
    }
}
