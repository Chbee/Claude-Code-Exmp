import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor: NetworkMonitorProtocol {
    private(set) var state: NetworkState = .unknown

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "NetworkMonitor")
    @ObservationIgnored private var hasStarted = false

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        monitor.pathUpdateHandler = { path in
            let next: NetworkState = path.status == .satisfied ? .online : .offline
            Task { @MainActor [weak self] in
                guard let self, self.state != next else { return }
                self.state = next
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
