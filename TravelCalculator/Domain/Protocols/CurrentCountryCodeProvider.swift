import Foundation

@MainActor
protocol CurrentCountryCodeProvider: Sendable {
    func requestCurrentCountryCode() async throws -> String
}

enum LocationError: Error, Sendable {
    case permissionDenied
    case unavailable
}
