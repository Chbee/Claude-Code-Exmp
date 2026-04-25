import Foundation
import Observation

@MainActor
protocol NetworkMonitorProtocol: AnyObject, Observable {
    var isOffline: Bool { get }
    func start()
}
