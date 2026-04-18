import Foundation

@MainActor
protocol CurrentCountryCodeProvider {
    func requestCurrentCountryCode() async throws -> String
}

enum LocationError: Error, Sendable {
    case permissionDenied
    case unavailable
}
