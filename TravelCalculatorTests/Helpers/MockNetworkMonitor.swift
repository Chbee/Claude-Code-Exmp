import Foundation
import Observation
@testable import TravelCalculator

@MainActor
@Observable
final class MockNetworkMonitor: NetworkMonitorProtocol {
    var state: NetworkState
    init(state: NetworkState = .unknown) { self.state = state }
    func start() {}
}
