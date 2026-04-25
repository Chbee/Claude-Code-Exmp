//
//  TravelCalculatorApp.swift
//  TravelCalculator
//

import SwiftUI

@main
struct TravelCalculatorApp: App {
    @State private var appStore = AppStore()
    @State private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ContentView(appStore: appStore, toastManager: toastManager)
                .toast(manager: toastManager)
        }
    }
}
