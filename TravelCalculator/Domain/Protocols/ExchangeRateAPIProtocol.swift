import Foundation

protocol ExchangeRateAPIProtocol: Sendable {
    func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse
}
