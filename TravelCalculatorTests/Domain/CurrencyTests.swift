import Testing
@testable import TravelCalculator

struct CurrencyTests {

    // MARK: - Display Properties

    @Test func allCurrencies_haveNonEmptyDisplayProperties() {
        for c in Currency.allCases {
            #expect(!c.symbol.isEmpty, "symbol empty for \(c)")
            #expect(!c.flag.isEmpty, "flag empty for \(c)")
            #expect(!c.countryName.isEmpty, "countryName empty for \(c)")
            #expect(!c.currencyName.isEmpty, "currencyName empty for \(c)")
        }
    }

    @Test func cny_symbol_isYuanIdeograph() {
        // JPY와 ¥ 충돌 회피 — 의사결정 docs/phase-f.md 2026-04-29 참조
        #expect(Currency.CNY.symbol == "元")
    }

    @Test(arguments: [
        (Currency.KRW, 0, "대한민국 원"),
        (.USD, 2, "미국 달러"),
        (.JPY, 0, "일본 엔"),
        (.CNY, 2, "중국 위안"),
        (.EUR, 2, "유로"),
        (.TWD, 2, "대만 달러"),
        (.THB, 2, "태국 바트"),
        (.VND, 0, "베트남 동"),
        (.PHP, 2, "필리핀 페소"),
    ])
    func currencySpec(c: Currency, digits: Int, name: String) {
        #expect(c.fractionDigits == digits)
        #expect(c.currencyName == name)
    }

    // MARK: - countryCode → Currency mapping

    @Test(arguments: [
        ("KR", Currency.KRW), ("US", .USD), ("JP", .JPY), ("CN", .CNY),
        ("TW", .TWD), ("TH", .THB), ("VN", .VND), ("PH", .PHP),
    ])
    func from_primaryCountryCode_mapsToCurrency(code: String, expected: Currency) {
        #expect(Currency.from(countryCode: code) == expected)
    }

    @Test(arguments: ["DE", "FR", "IT", "ES", "NL", "BE", "AT", "PT", "IE",
                       "FI", "GR", "LU", "SK", "SI", "EE", "LV", "LT", "MT", "CY"])
    func from_eurozoneCountryCode_mapsToEUR(code: String) {
        #expect(Currency.from(countryCode: code) == .EUR)
    }

    @Test func from_lowercase_handled() {
        #expect(Currency.from(countryCode: "us") == .USD)
        #expect(Currency.from(countryCode: "de") == .EUR)
    }

    @Test func from_unsupportedCode_returnsNil() {
        #expect(Currency.from(countryCode: "XX") == nil)
        #expect(Currency.from(countryCode: "GB") == nil)  // 영국은 GBP 미지원
        #expect(Currency.from(countryCode: "CH") == nil)  // 스위스는 CHF 미지원 (eurozone 아님)
    }

    @Test func from_euReservedCode_returnsNil() {
        // "EU"는 ISO 3166-1 reserved code — CLPlacemark.isoCountryCode가 반환하지 않음
        #expect(Currency.from(countryCode: "EU") == nil)
    }

    @Test func countryCodes_haveNoDuplicates() {
        // Dictionary(uniqueKeysWithValues:) trap 가드 — 통화 추가 시 회귀 방지
        let all = Currency.allCases.flatMap { $0.countryCodes }
        let duplicates = Dictionary(grouping: all, by: { $0 }).filter { $1.count > 1 }.keys
        #expect(duplicates.isEmpty, "중복 country code: \(Array(duplicates))")
    }
}
