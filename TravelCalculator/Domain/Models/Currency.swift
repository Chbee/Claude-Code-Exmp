import Foundation

enum Currency: String, CaseIterable, Sendable {
    case KRW
    case USD
    case TWD

    nonisolated var symbol: String {
        switch self {
        case .KRW: "₩"
        case .USD: "$"
        case .TWD: "NT$"
        }
    }

    nonisolated var flag: String {
        switch self {
        case .KRW: "🇰🇷"
        case .USD: "🇺🇸"
        case .TWD: "🇹🇼"
        }
    }

    nonisolated var countryName: String {
        switch self {
        case .KRW: "대한민국"
        case .USD: "미국"
        case .TWD: "대만"
        }
    }

    nonisolated var currencyUnit: String { rawValue }

    nonisolated var fractionDigits: Int {
        switch self {
        case .KRW: 0
        case .USD, .TWD: 2
        }
    }
}

extension Currency: Codable {
    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Currency(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown currency: \(raw)")
        }
        self = value
    }
}
