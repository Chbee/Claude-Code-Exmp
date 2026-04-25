import Testing
import Foundation
@testable import TravelCalculator

@MainActor
struct CalculatorDisplayRelativeLabelTests {
    private let now = Date(timeIntervalSince1970: 1_745_600_000)

    @Test func underOneMinute_returnsBangeum() {
        let date = now.addingTimeInterval(-30)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "방금")
    }

    @Test func minutes_returnsMinutesAgo() {
        let date = now.addingTimeInterval(-5 * 60)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "5분 전")
    }

    @Test func hours_returnsHoursAgo() {
        let date = now.addingTimeInterval(-3 * 3600)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "3시간 전")
    }

    @Test func days_returnsDaysAgo() {
        let date = now.addingTimeInterval(-2 * 86400)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "2일 전")
    }

    @Test func futureDate_clampsToBangeum() {
        let date = now.addingTimeInterval(10)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "방금")
    }

    @Test func boundary_exactly60Seconds_isOneMinute() {
        let date = now.addingTimeInterval(-60)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "1분 전")
    }

    @Test func boundary_exactly24Hours_isOneDay() {
        let date = now.addingTimeInterval(-86400)
        #expect(CalculatorDisplay.relativeLabel(from: date, now: now) == "1일 전")
    }
}
