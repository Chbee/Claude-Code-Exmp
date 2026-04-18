import Foundation

enum CurrencySelectIntent {
    case selectCurrency(Currency)
    case dismiss
    case requestLocation
    case locationRequestFinished
}
