import Foundation
import CoreLocation

protocol LocationProviding {
    func requestLocation() async throws -> CLLocation
}

final class LocationProvider: NSObject, LocationProviding {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            throw CLError(.denied)
        default:
            break
        }

        if CLLocationManager.locationServicesEnabled() {
            if continuation != nil {
                continuation?.resume(throwing: CLError(.locationUnknown))
                continuation = nil
            }

            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                manager.requestLocation()
            }
        } else {
            throw CLError(.locationUnknown)
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied {
            continuation?.resume(throwing: CLError(.denied))
            continuation = nil
        }
    }
}
