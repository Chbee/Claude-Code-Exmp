import Foundation

enum Currency: String, CaseIterable, Codable, Sendable {
    case KRW
    case USD
    case TWD

    var symbol: String {
        switch self {
        case .KRW: "₩"
        case .USD: "$"
        case .TWD: "NT$"
        }
    }

    var flag: String {
        switch self {
        case .KRW: "🇰🇷"
        case .USD: "🇺🇸"
        case .TWD: "🇹🇼"
        }
    }

    var countryName: String {
        switch self {
        case .KRW: "대한민국"
        case .USD: "미국"
        case .TWD: "대만"
        }
    }

    var currencyUnit: String {
        rawValue
    }

    var fractionDigits: Int {
        switch self {
        case .KRW: 0
        case .USD, .TWD: 2
        }
    }
}
