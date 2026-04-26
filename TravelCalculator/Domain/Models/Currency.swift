import Foundation

enum Currency: String, CaseIterable, Sendable {
    case KRW
    case USD
    case JPY
    case CNY
    case EUR
    case TWD
    case THB
    case VND
    case PHP

    nonisolated var symbol: String {
        switch self {
        case .KRW: "₩"
        case .USD: "$"
        case .JPY: "¥"
        case .CNY: "¥"
        case .EUR: "€"
        case .TWD: "NT$"
        case .THB: "฿"
        case .VND: "₫"
        case .PHP: "₱"
        }
    }

    nonisolated var flag: String {
        switch self {
        case .KRW: "🇰🇷"
        case .USD: "🇺🇸"
        case .JPY: "🇯🇵"
        case .CNY: "🇨🇳"
        case .EUR: "🇪🇺"
        case .TWD: "🇹🇼"
        case .THB: "🇹🇭"
        case .VND: "🇻🇳"
        case .PHP: "🇵🇭"
        }
    }

    nonisolated var countryName: String {
        switch self {
        case .KRW: "대한민국"
        case .USD: "미국"
        case .JPY: "일본"
        case .CNY: "중국"
        case .EUR: "유럽연합"
        case .TWD: "대만"
        case .THB: "태국"
        case .VND: "베트남"
        case .PHP: "필리핀"
        }
    }

    nonisolated var currencyName: String {
        switch self {
        case .KRW: "대한민국 원"
        case .USD: "미국 달러"
        case .JPY: "일본 엔"
        case .CNY: "중국 위안"
        case .EUR: "유로"
        case .TWD: "대만 달러"
        case .THB: "태국 바트"
        case .VND: "베트남 동"
        case .PHP: "필리핀 페소"
        }
    }

    nonisolated var currencyUnit: String { rawValue }

    nonisolated var fractionDigits: Int {
        switch self {
        case .KRW, .JPY, .VND: 0
        case .USD, .CNY, .EUR, .TWD, .THB, .PHP: 2
        }
    }
}

extension Currency {
    // EUR은 단일 국가가 아니라 eurozone 19개국을 포괄 — 단일 reverse-lookup이 깨지므로 배열 매핑 채택.
    nonisolated var countryCodes: [String] {
        switch self {
        case .KRW: ["KR"]
        case .USD: ["US"]
        case .JPY: ["JP"]
        case .CNY: ["CN"]
        case .EUR: ["EU", "DE", "FR", "IT", "ES", "NL", "BE", "AT", "PT", "IE",
                    "FI", "GR", "LU", "SK", "SI", "EE", "LV", "LT", "MT", "CY"]
        case .TWD: ["TW"]
        case .THB: ["TH"]
        case .VND: ["VN"]
        case .PHP: ["PH"]
        }
    }

    nonisolated static func from(countryCode: String) -> Currency? {
        let code = countryCode.uppercased()
        return allCases.first { $0.countryCodes.contains(code) }
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
