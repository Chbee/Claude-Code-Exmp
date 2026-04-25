import SwiftUI

struct CalculatorView: View {
    // 오프→온 복귀 pulse 발화 간 최소 간격(초). flapping 시 애니 스팸 방지.
    private static let pulseThrottle: TimeInterval = 10
    // 새로고침 탭 throttle(초). 동일 안내 Toast 연타 중복 발화 방지.
    private static let refreshTapThrottle: TimeInterval = 0.8

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

            Spacer()

            CalculatorDisplay(
                displayModel: calculatorStore.displayModel,
                onToggleDirection: { calculatorStore.toggleDirection() },
                onRefresh: handleRefreshTap,
                daysSinceSearchDate: currencyStore.daysSinceSearchDate,
                isRefreshEnabled: currencyStore.isRefreshEnabled,
                isLoading: currencyStore.isLoading,
                isOffline: currencyStore.isOffline,
                cachedAt: currencyStore.cachedAt
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
            guard new == .online else { return }
            // 캐시가 없으면(앱이 오프라인으로 시작했거나 fetch가 실패해서 .error 상태) 자동 재시도.
            // 캐시가 있으면 사용자가 명시적으로 새로고침을 누를 때까지 기존 데이터 유지.
            if currencyStore.currentResponse == nil {
                Task { await currencyStore.loadExchangeRates() }
            }
            // pulse는 offline → online 복귀 신호. flapping 스팸 방지 throttle.
            guard old == .offline else { return }
            let now = Date.now
            guard now.timeIntervalSince(lastPulseAt) >= Self.pulseThrottle else { return }
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
        let now = Date.now
        guard now.timeIntervalSince(lastRefreshTapAt) >= Self.refreshTapThrottle else { return }
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
