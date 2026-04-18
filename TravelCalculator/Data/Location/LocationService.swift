import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, CurrentCountryCodeProvider, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<String, Error>?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    deinit {
        timeoutTask?.cancel()
        continuation?.resume(throwing: LocationError.unavailable)
        continuation = nil
    }

    func requestCurrentCountryCode() async throws -> String {
        if continuation != nil { throw LocationError.unavailable }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                self.continuation = cont

                switch manager.authorizationStatus {
                case .denied, .restricted:
                    resume(with: .failure(LocationError.permissionDenied))
                case .notDetermined:
                    manager.requestWhenInUseAuthorization()
                    scheduleTimeout()
                case .authorizedWhenInUse, .authorizedAlways:
                    manager.requestLocation()
                    scheduleTimeout()
                @unknown default:
                    resume(with: .failure(LocationError.unavailable))
                }
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                self?.resume(with: .failure(CancellationError()))
            }
        }
    }

    // MARK: - Private

    private func scheduleTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.handleTimeout()
        }
    }

    private func handleTimeout() {
        guard continuation != nil else { return }
        resume(with: .failure(LocationError.unavailable))
    }

    private func resume(with result: Result<String, Error>) {
        guard let cont = continuation else { return }
        continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        geocoder.cancelGeocode()
        cont.resume(with: result)
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard continuation != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                resume(with: .failure(LocationError.permissionDenied))
            case .notDetermined:
                break
            @unknown default:
                resume(with: .failure(LocationError.unavailable))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor in resume(with: .failure(LocationError.unavailable)) }
            return
        }
        Task { @MainActor in
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let code = placemarks.first?.isoCountryCode {
                    resume(with: .success(code))
                } else {
                    resume(with: .failure(LocationError.unavailable))
                }
            } catch {
                resume(with: .failure(LocationError.unavailable))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            resume(with: .failure(LocationError.unavailable))
        }
    }
}
