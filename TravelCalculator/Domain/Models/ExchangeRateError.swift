import Foundation

enum ExchangeRateError: Error, LocalizedError, Sendable, Equatable {
    case networkError
    case serverError(statusCode: Int)
    case noDataAvailable
    case parsingError
    case invalidRate
    case noCacheAvailable
    case missingAPIKey

    nonisolated var errorDescription: String? {
        switch self {
        case .networkError: "네트워크 연결에 실패했습니다"
        case .serverError: "서버에서 오류가 발생했습니다"
        case .noDataAvailable: "환율 데이터를 찾을 수 없습니다"
        case .parsingError: "환율 데이터를 처리할 수 없습니다"
        case .invalidRate: "유효하지 않은 환율입니다"
        case .noCacheAvailable: "저장된 환율 데이터가 없습니다"
        case .missingAPIKey: "환율 API 키가 설정되지 않았습니다"
        }
    }
}
