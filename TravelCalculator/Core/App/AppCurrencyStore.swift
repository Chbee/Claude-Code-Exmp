import Foundation
import Observation

// Phase C에서 associated value 추가 예정
enum ExchangeRateStatus: Sendable {
    case loading
    case loaded   // Phase C: case loaded(ExchangeRateResponse)
    case error    // Phase C: case error(ExchangeRateError)
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

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.selectedCurrency = Self.loadSelectedCurrency(from: userDefaults)
        self.conversionDirection = Self.loadConversionDirection(from: userDefaults)
    }

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
