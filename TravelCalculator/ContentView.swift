//
//  ContentView.swift
//  TravelCalculator
//

import SwiftUI

struct ContentView: View {
    let appStore: AppStore
    let toastManager: ToastManager

    var body: some View {
        CalculatorView(
            toastManager: toastManager,
            currencyStore: appStore.currencyStore
        )
        .task {
            await appStore.currencyStore.loadExchangeRates()
        }
        .overlay {
            if let error = appStore.currencyStore.unavailableRateError {
                ExchangeRateErrorView(error: error) {
                    Task { await appStore.currencyStore.loadExchangeRates() }
                }
            }
        }
    }
}

#Preview {
    ContentView(appStore: AppStore(), toastManager: ToastManager())
}
