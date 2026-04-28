import Testing
import Foundation
@testable import TravelCalculator

// MARK: - State.filteredCurrencies

@MainActor
struct CurrencySelectFilterTests {

    private func makeState(query: String = "") -> CurrencySelectState {
        var s = CurrencySelectState(selectedCurrency: .USD)
        s.searchQuery = query
        return s
    }

    @Test func emptyQuery_returnsAllCurrencies() {
        let s = makeState(query: "")
        #expect(s.filteredCurrencies == s.currencies)
    }

    @Test func koreanCountryName_matchesByPartial() {
        let s = makeState(query: "일본")
        #expect(s.filteredCurrencies == [.JPY])
    }

    @Test func currencyUnit_matchesUppercase() {
        let s = makeState(query: "JPY")
        #expect(s.filteredCurrencies == [.JPY])
    }

    @Test func currencyUnit_matchesLowercase() {
        let s = makeState(query: "jpy")
        #expect(s.filteredCurrencies == [.JPY])
    }

    @Test func leadingTrailingWhitespace_trimmed() {
        let s = makeState(query: "  일본  ")
        #expect(s.filteredCurrencies == [.JPY])
    }

    @Test func whitespaceOnlyQuery_returnsAllCurrencies() {
        let s = makeState(query: "   ")
        #expect(s.filteredCurrencies == s.currencies)
    }

    @Test func currencyName_doesNotMatch_scopeGuard() {
        // "엔" 은 currencyName("일본 엔") 부분 일치이지만 매칭 범위 밖.
        let s = makeState(query: "엔")
        #expect(s.filteredCurrencies.isEmpty)
    }

    @Test func symbol_doesNotMatch_scopeGuard() {
        // "¥" 는 symbol(JPY/CNY) 부분 일치이지만 매칭 범위 밖.
        let s = makeState(query: "¥")
        #expect(s.filteredCurrencies.isEmpty)
    }

    @Test func noMatch_returnsEmpty() {
        let s = makeState(query: "ZZZ")
        #expect(s.filteredCurrencies.isEmpty)
    }
}

// MARK: - Reducer.setSearchQuery

@MainActor
struct CurrencySelectReducerSearchTests {

    @Test func setSearchQueryIntent_updatesSearchQueryOnly() {
        let initial = CurrencySelectState(selectedCurrency: .USD)
        let next = CurrencySelectReducer.reduce(initial, intent: .setSearchQuery("일본"))

        #expect(next.searchQuery == "일본")
        #expect(next.selectedCurrency == initial.selectedCurrency)
        #expect(next.shouldDismiss == initial.shouldDismiss)
        #expect(next.isOnboarding == initial.isOnboarding)
        #expect(next.isRequestingLocation == initial.isRequestingLocation)
    }
}
