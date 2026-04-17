//
//  ContentView.swift
//  TravelCalculator
//

import SwiftUI

struct ContentView: View {
    let appStore: AppStore
    let toastManager: ToastManager

    var body: some View {
        Group {
            if !appStore.hasCompletedOnboarding {
                OnboardingCurrencySelectContainer(appStore: appStore, toastManager: toastManager)
            } else {
                CalculatorView(
                    toastManager: toastManager,
                    currencyStore: appStore.currencyStore
                )
                .overlay {
                    if let error = appStore.currencyStore.unavailableRateError {
                        ExchangeRateErrorView(error: error) {
                            Task { await appStore.currencyStore.loadExchangeRates() }
                        }
                    }
                }
            }
        }
        .task {
            await appStore.currencyStore.loadExchangeRates()
        }
    }
}

private struct OnboardingCurrencySelectContainer: View {
    @State private var store: CurrencySelectStore

    init(appStore: AppStore, toastManager: ToastManager) {
        _store = State(initialValue: appStore.makeOnboardingCurrencySelectStore(toastManager: toastManager))
    }

    var body: some View {
        CurrencySelectView(store: store)
    }
}

#Preview {
    ContentView(appStore: AppStore(), toastManager: ToastManager())
}
