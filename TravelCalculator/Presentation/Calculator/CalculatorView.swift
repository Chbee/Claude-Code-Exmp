import SwiftUI

struct CalculatorView: View {
    @State private var calculatorStore: CalculatorStore
    @State private var showCurrencySelect = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var lastPulseAt: Date = .distantPast
    @State private var lastRefreshTapAt: Date = .distantPast

    private let toastManager: ToastManager
    private let currencyStore: AppCurrencyStore

    init(toastManager: ToastManager, currencyStore: AppCurrencyStore) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
        _calculatorStore = State(initialValue: CalculatorStore(
            toastManager: toastManager,
            currencyStore: currencyStore
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            CalculatorToolbar(
                currency: currencyStore.selectedCurrency,
                networkState: currencyStore.networkState,
                onCurrencyTap: { showCurrencySelect = true }
            )
            .padding(.top, 8)

            OfflineBanner(
                isOffline: currencyStore.isOffline,
                cachedAt: currencyStore.cachedAt
            )
            .padding(.top, 8)

            Spacer()

            CalculatorDisplay(
                displayModel: calculatorStore.displayModel,
                onToggleDirection: { calculatorStore.toggleDirection() },
                onRefresh: handleRefreshTap,
                daysSinceSearchDate: currencyStore.daysSinceSearchDate,
                isRefreshEnabled: currencyStore.isRefreshEnabled,
                isLoading: currencyStore.isLoading
            )
            .opacity(!currencyStore.isLoading && currencyStore.currentRate == nil ? 0.4 : 1.0)
            .scaleEffect(pulseScale)

            CalculatorKeypad(
                onIntent: { calculatorStore.send($0) }
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onChange(of: currencyStore.selectedCurrency) {
            calculatorStore.send(.resetForCurrencyChange)
        }
        .onChange(of: currencyStore.networkState) { old, new in
            // flapping 시 pulse 스팸 방지: 마지막 pulse로부터 10초 이내면 skip.
            guard old == .offline, new == .online else { return }
            let now = Date.now
            guard now.timeIntervalSince(lastPulseAt) >= 10 else { return }
            lastPulseAt = now
            withAnimation(.easeOut(duration: 0.3)) { pulseScale = 1.02 }
            withAnimation(.easeIn(duration: 0.3).delay(0.3)) { pulseScale = 1.0 }
        }
        .fullScreenCover(isPresented: $showCurrencySelect) {
            CurrencySelectView(
                store: CurrencySelectStore(
                    toastManager: toastManager,
                    currencyStore: currencyStore,
                    locationService: LocationService()
                )
            )
            .toast(manager: toastManager)
        }
    }

    private func handleRefreshTap() {
        // 0.8s throttle — 같은 안내 Toast가 연타로 중복 발화되는 것을 막는다.
        let now = Date.now
        guard now.timeIntervalSince(lastRefreshTapAt) >= 0.8 else { return }
        lastRefreshTapAt = now

        switch currencyStore.networkState {
        case .offline:
            toastManager.show(ToastPayload(
                style: .info,
                title: "오프라인",
                message: "네트워크 연결 후 갱신할 수 있어요"
            ))
        case .unknown:
            toastManager.show(ToastPayload(
                style: .info,
                title: "네트워크 확인 중",
                message: "잠시 후 다시 시도해 주세요"
            ))
        case .online:
            Task { await calculatorStore.refreshRates() }
        }
    }
}

#Preview {
    let toastManager = ToastManager()
    let currencyStore = AppCurrencyStore()
    CalculatorView(toastManager: toastManager, currencyStore: currencyStore)
        .previewWithColorSchemes()
}
