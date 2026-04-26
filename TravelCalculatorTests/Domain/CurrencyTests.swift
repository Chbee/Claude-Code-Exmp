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

    @Test(arguments: ["EU", "DE", "FR", "IT", "ES", "NL", "BE", "AT", "PT", "IE",
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
}
