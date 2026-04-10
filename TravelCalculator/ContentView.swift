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
    }
}

#Preview {
    ContentView(appStore: AppStore(), toastManager: ToastManager())
}
