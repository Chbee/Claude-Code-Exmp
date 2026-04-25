import Foundation
import Observation

enum ExchangeRateStatus: Sendable {
    case loading
    case loaded(ExchangeRateResponse)
    case error(ExchangeRateError)
}

enum ConversionDirection: String, Codable, Sendable {
    case selectedToKRW
    case krwToSelected
}

@MainActor
@Observable
final class AppCurrencyStore {
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private static let selectedCurrencyKey = "selectedCurrency"
    @ObservationIgnored private static let conversionDirectionKey = "conversionDirection"
    @ObservationIgnored private let exchangeRateAPI: (any ExchangeRateAPIProtocol)?
    @ObservationIgnored private let networkMonitor: (any NetworkMonitorProtocol)?
    // single-flight 가드. exchangeRateStatus의 초기값이 .loading이라 status로는 구분 불가.
    @ObservationIgnored private var isInFlight = false

    var selectedCurrency: Currency {
        didSet {
            guard oldValue != selectedCurrency else { return }
            userDefaults.set(selectedCurrency.rawValue, forKey: Self.selectedCurrencyKey)
        }
    }

    var conversionDirection: ConversionDirection {
        didSet {
            guard oldValue != conversionDirection else { return }
            userDefaults.set(conversionDirection.rawValue, forKey: Self.conversionDirectionKey)
        }
    }

    var exchangeRateStatus: ExchangeRateStatus = .loading

    var fromCurrency: Currency {
        conversionDirection == .selectedToKRW ? selectedCurrency : .KRW
    }

    var toCurrency: Currency {
        conversionDirection == .selectedToKRW ? .KRW : selectedCurrency
    }

    // MARK: - Computed Properties

    var currentResponse: ExchangeRateResponse? {
        guard case .loaded(let r) = exchangeRateStatus else { return nil }
        return r
    }

    var currentRate: Decimal? {
        currentResponse?.rate(for: selectedCurrency)
    }

    var searchDate: String? {
        currentResponse?.searchDate
    }

    var isRefreshEnabled: Bool {
        guard let r = currentResponse else { return false }
        return Date.now >= r.validUntil && networkState == .online
    }

    var daysSinceSearchDate: Int? {
        guard let searchDate,
              let date = Date.fromYYYYMMDDKST(searchDate) else { return nil }
        return Calendar.kst.dateComponents([.day],
            from: Calendar.kst.startOfDay(for: date),
            to: Calendar.kst.startOfDay(for: Date.now)
        ).day
    }

    var currentError: ExchangeRateError? {
        guard case .error(let e) = exchangeRateStatus else { return nil }
        return e
    }

    var isLoading: Bool {
        if case .loading = exchangeRateStatus { return true }
        return false
    }

    var unavailableRateError: ExchangeRateError? {
        currentRate == nil ? currentError : nil
    }

    var cachedAt: Date? {
        currentResponse?.fetchedAt
    }

    var networkState: NetworkState {
        networkMonitor?.state ?? .unknown
    }

    var isOffline: Bool {
        networkState == .offline
    }

    // MARK: - Init

    init(
        userDefaults: UserDefaults = .standard,
        exchangeRateAPI: (any ExchangeRateAPIProtocol)? = nil,
        networkMonitor: (any NetworkMonitorProtocol)? = nil
    ) {
        self.userDefaults = userDefaults
        self.exchangeRateAPI = exchangeRateAPI
        self.networkMonitor = networkMonitor
        self.selectedCurrency = Self.loadSelectedCurrency(from: userDefaults)
        self.conversionDirection = Self.loadConversionDirection(from: userDefaults)
    }

    // MARK: - Exchange Rate Loading

    func loadExchangeRates(force: Bool = false) async {
        if !force, case .loaded = exchangeRateStatus { return }
        // single-flight 가드: onAppear + NWPathMonitor unknown→online 자동 트리거가
        // 첫 호출 진행 중에 겹치는 콜드 스타트 race 방어.
        if isInFlight { return }
        guard let api = exchangeRateAPI else {
            exchangeRateStatus = .error(.noCacheAvailable)
            return
        }
        isInFlight = true
        defer { isInFlight = false }
        exchangeRateStatus = .loading
        do {
            let response = try await api.fetchRates(for: Currency.allCases.filter { $0 != .KRW })
            exchangeRateStatus = .loaded(response)
        } catch let err as ExchangeRateError {
            exchangeRateStatus = .error(err)
        } catch {
            exchangeRateStatus = .error(.networkError)
        }
    }

    func refreshExchangeRates() async {
        // force=true는 store의 .loaded 가드만 우회. API 레이어는 validUntil 이전엔
        // 캐시 반환 (open.er-api.com 24h 주기와 정합) — fresh window 안에선 no-op.
        guard networkState == .online else { return }
        await loadExchangeRates(force: true)
    }

    // MARK: - Private Helpers

    private static func loadSelectedCurrency(from ud: UserDefaults) -> Currency {
        guard let raw = ud.string(forKey: selectedCurrencyKey),
              let currency = Currency(rawValue: raw) else { return .USD }
        return currency
    }

    private static func loadConversionDirection(from ud: UserDefaults) -> ConversionDirection {
        guard let raw = ud.string(forKey: conversionDirectionKey),
              let dir = ConversionDirection(rawValue: raw) else { return .selectedToKRW }
        return dir
    }

}
