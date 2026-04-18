import Testing
@testable import TravelCalculator

struct ExchangeRateErrorTests {

    @Test func networkErrorDescription() {
        #expect(ExchangeRateError.networkError.errorDescription == "네트워크 연결에 실패했습니다")
    }

    @Test func serverErrorDescription() {
        #expect(ExchangeRateError.serverError(statusCode: 500).errorDescription == "서버에서 오류가 발생했습니다")
    }

    @Test func noDataAvailableDescription() {
        #expect(ExchangeRateError.noDataAvailable.errorDescription == "환율 데이터를 찾을 수 없습니다")
    }

    @Test func parsingErrorDescription() {
        #expect(ExchangeRateError.parsingError.errorDescription == "환율 데이터를 처리할 수 없습니다")
    }

    @Test func invalidRateDescription() {
        #expect(ExchangeRateError.invalidRate.errorDescription == "유효하지 않은 환율입니다")
    }

    @Test func noCacheAvailableDescription() {
        #expect(ExchangeRateError.noCacheAvailable.errorDescription == "저장된 환율 데이터가 없습니다")
    }
}
