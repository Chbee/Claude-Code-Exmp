import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CurrencySelectStore {
    private(set) var state: CurrencySelectState

    private let toastManager: ToastManager
    private let currencyStore: AppCurrencyStore
    private let onOnboardingComplete: (@MainActor @Sendable () -> Void)?
    private let locationService: (any CurrentCountryCodeProvider)?

    private enum SelectionSource { case userTap, location }

    init(
        toastManager: ToastManager,
        currencyStore: AppCurrencyStore,
        isOnboarding: Bool = false,
        onOnboardingComplete: (@MainActor @Sendable () -> Void)? = nil,
        locationService: (any CurrentCountryCodeProvider)? = nil
    ) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
        self.onOnboardingComplete = onOnboardingComplete
        self.locationService = locationService
        var initial = CurrencySelectState(selectedCurrency: currencyStore.selectedCurrency)
        initial.isOnboarding = isOnboarding
        self.state = initial
    }

    func send(_ intent: CurrencySelectIntent) {
        // .requestLocation 재진입 방지: 이미 로딩 중이면 reducer/side effect 모두 스킵
        if case .requestLocation = intent, state.isRequestingLocation { return }

        state = CurrencySelectReducer.reduce(state, intent: intent)

        switch intent {
        case .selectCurrency(let currency):
            applySelectedCurrency(currency, source: .userTap)
        case .dismiss:
            break
        case .requestLocation:
            Task { await handleLocationRequest() }
        case .locationRequestFinished:
            break
        }
    }

    // MARK: - Private

    private func applySelectedCurrency(_ currency: Currency, source: SelectionSource) {
        let previous = currencyStore.selectedCurrency
        let changed = previous != currency

        if changed {
            currencyStore.selectedCurrency = currency
            Haptic.notification(.success)
        }

        if !state.isOnboarding, changed {
            toastManager.show(ToastPayload(
                style: .success,
                title: source == .location ? "위치로 통화 설정 완료" : "통화 변경 완료",
                message: "\(currency.flag) \(currency.currencyUnit)"
            ))
        }

        if state.isOnboarding {
            currencyStore.conversionDirection = .selectedToKRW
            onOnboardingComplete?()
        }
    }

    private func handleLocationRequest() async {
        defer { send(.locationRequestFinished) }
        guard let service = locationService else { return }

        do {
            let code = try await service.requestCurrentCountryCode()
            guard let currency = Currency.from(countryCode: code) else {
                toastManager.show(ToastPayload(
                    style: .warning,
                    title: "지원하지 않는 지역입니다",
                    message: "여행지 통화를 직접 선택해주세요"
                ))
                return
            }
            if currency == .KRW {
                toastManager.show(ToastPayload(
                    style: .info,
                    title: "현재 위치는 한국입니다",
                    message: "여행지 통화를 직접 선택해주세요"
                ))
                return
            }
            applySelectedCurrency(currency, source: .location)
        } catch LocationError.permissionDenied {
            toastManager.show(ToastPayload(
                style: .info,
                title: "위치 권한이 필요합니다",
                message: "설정 > 개인정보 보호 > 위치 서비스에서 허용해 주세요"
            ))
        } catch {
            toastManager.show(ToastPayload(
                style: .error,
                title: "현재 위치를 확인할 수 없습니다",
                message: "잠시 후 다시 시도해 주세요"
            ))
        }
    }
}
