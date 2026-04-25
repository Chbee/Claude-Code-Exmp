//
//  TravelCalculatorApp.swift
//  TravelCalculator
//

import SwiftUI

@main
struct TravelCalculatorApp: App {
    @State private var appStore: AppStore
    @State private var toastManager = ToastManager()

    init() {
        let store = AppStore()
        store.networkMonitor.start()
        _appStore = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appStore: appStore, toastManager: toastManager)
                .toast(manager: toastManager)
        }
    }
}
