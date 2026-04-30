import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CalculatorStore {
    // 새로고침 탭 throttle(초). 동일 안내 Toast 연타 중복 발화 방지.
    private static let refreshTapThrottle: TimeInterval = 0.8

    private(set) var state: CalculatorState = .init()

    private let toastManager: ToastManager
    let currencyStore: AppCurrencyStore

    @ObservationIgnored private var wasNegative: Bool = false
    @ObservationIgnored private var lastRefreshTapAt: Date = .distantPast

    init(toastManager: ToastManager, currencyStore: AppCurrencyStore) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
    }

    var displayModel: CalculatorDisplayModel {
        let currency = currencyStore.selectedCurrency
        let rate = currencyStore.currentRate ?? 0
        let isInputKRW = currencyStore.conversionDirection == .krwToSelected
        return CalculatorDisplayModel.make(
            state: state,
            inputCurrency: currencyStore.fromCurrency,
            outputCurrency: currencyStore.toCurrency,
            selectedCurrency: currency,
            exchangeRate: rate,
            isInputKRW: isInputKRW
        )
    }

    func send(_ intent: CalculatorIntent) {
        state = CalculatorReducer.reduce(state, intent: intent)
        if let toast = state.pendingToast {
            toastManager.show(toast)
            state.pendingToast = nil
        }

        if case .equalsPressed = intent {
            Haptic.impact(.light)
        }

        let isNegativeNow = state.display.hasPrefix("-")
        if isNegativeNow && !wasNegative {
            toastManager.show(ToastPayload(
                style: .warning,
                title: "음수 결과",
                message: "환율 변환 결과는 0으로 표시돼요"
            ))
        }
        wasNegative = isNegativeNow
    }

    func toggleDirection() {
        let model = displayModel
        send(.directionTogglePressed(model.resultDisplay.rawAmount))
        currencyStore.conversionDirection = currencyStore.conversionDirection == .selectedToKRW
            ? .krwToSelected
            : .selectedToKRW
        Haptic.impact(.medium)
    }

    func requestRefresh() {
        Haptic.impact(.light)

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
            guard currencyStore.isRefreshEnabled else {
                toastManager.show(ToastPayload(
                    style: .info,
                    title: "최신 환율",
                    message: "이미 최신 환율이에요"
                ))
                return
            }
            Task { await currencyStore.refreshExchangeRates() }
        }
    }
}
