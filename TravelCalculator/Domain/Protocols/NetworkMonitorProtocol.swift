import Foundation
import Observation

enum NetworkState: Sendable {
    case unknown
    case online
    case offline
}

@MainActor
protocol NetworkMonitorProtocol: AnyObject, Observable {
    var state: NetworkState { get }
    func start()
}
