import Testing
import Foundation
@testable import TravelCalculator

@MainActor
struct LocationServiceTests {

    @Test func taskCancellation_resumesContinuationQuickly() async throws {
        let service = LocationService()

        let start = ContinuousClock.now
        let task = Task { @MainActor in
            try await service.requestCurrentCountryCode()
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        let result = await task.result
        let elapsed = ContinuousClock.now - start

        switch result {
        case .success:
            Issue.record("Expected failure on cancelled task")
        case .failure:
            break
        }

        #expect(elapsed < .seconds(5), "continuation must resume on cancellation before the 10s timeout (got \(elapsed))")
    }
}
