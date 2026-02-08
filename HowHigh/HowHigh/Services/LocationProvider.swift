import Foundation
import CoreLocation

protocol LocationProviding {
    func requestLocation() async throws -> CLLocation
}

final class LocationProvider: NSObject, LocationProviding {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Error>?
    private var locationTimeoutTask: Task<Void, Never>?
    private var authorizationTimeoutTask: Task<Void, Never>?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async throws -> CLLocation {
        _ = try await ensureAuthorized()

        if CLLocationManager.locationServicesEnabled() {
            // Prefer last-known location if it's fresh; this avoids transient `kCLErrorDomain` failures
            // (common in Simulator when no explicit location is set).
            if let cached = manager.location, cached.horizontalAccuracy >= 0,
               abs(cached.timestamp.timeIntervalSinceNow) < 10 * 60 {
                return cached
            }

            if continuation != nil {
                continuation?.resume(throwing: CLError(.locationUnknown))
                continuation = nil
            }

            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                scheduleLocationTimeout()
                manager.requestLocation()
            }
        } else {
            throw CLError(.locationUnknown)
        }
    }

    private func ensureAuthorized() async throws -> CLAuthorizationStatus {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return manager.authorizationStatus
        case .restricted, .denied:
            throw CLError(.denied)
        case .notDetermined:
            if authorizationContinuation != nil {
                authorizationContinuation?.resume(throwing: CLError(.locationUnknown))
                authorizationContinuation = nil
            }
            return try await withCheckedThrowingContinuation { continuation in
                self.authorizationContinuation = continuation
                scheduleAuthorizationTimeout()
                manager.requestWhenInUseAuthorization()
            }
        @unknown default:
            throw CLError(.locationUnknown)
        }
    }

    private func scheduleLocationTimeout(seconds: Double = 8) {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = Task { @MainActor in
            let ns = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard let continuation else { return }
            continuation.resume(throwing: CLError(.locationUnknown))
            self.continuation = nil
        }
    }

    private func scheduleAuthorizationTimeout(seconds: Double = 15) {
        authorizationTimeoutTask?.cancel()
        authorizationTimeoutTask = Task { @MainActor in
            let ns = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard let authorizationContinuation else { return }
            authorizationContinuation.resume(throwing: CLError(.locationUnknown))
            self.authorizationContinuation = nil
        }
    }

    private func cancelLocationTimeout() {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil
    }

    private func cancelAuthorizationTimeout() {
        authorizationTimeoutTask?.cancel()
        authorizationTimeoutTask = nil
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        cancelLocationTimeout()
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        cancelLocationTimeout()
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if let authorizationContinuation {
            let status = manager.authorizationStatus
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                cancelAuthorizationTimeout()
                authorizationContinuation.resume(returning: status)
            case .restricted, .denied:
                cancelAuthorizationTimeout()
                authorizationContinuation.resume(throwing: CLError(.denied))
            case .notDetermined:
                return
            @unknown default:
                cancelAuthorizationTimeout()
                authorizationContinuation.resume(throwing: CLError(.locationUnknown))
            }
            self.authorizationContinuation = nil
        }

        if manager.authorizationStatus == .denied {
            cancelLocationTimeout()
            continuation?.resume(throwing: CLError(.denied))
            continuation = nil
        }
    }
}
