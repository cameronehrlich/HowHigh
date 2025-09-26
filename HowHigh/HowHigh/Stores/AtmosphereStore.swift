import Foundation
import CoreLocation

@MainActor
final class AtmosphereStore: ObservableObject {
    @Published private(set) var latestObservation: AtmosphericObservation?
    @Published private(set) var isFetching: Bool = false
    @Published private(set) var lastError: String?

    private let service: AtmosphericProviding
    private let locationProvider: LocationProviding

    init(service: AtmosphericProviding = AtmosphereService(), locationProvider: LocationProviding = LocationProvider()) {
        self.service = service
        self.locationProvider = locationProvider
    }

    func refresh() async {
        isFetching = true
        lastError = nil
        do {
            let location = try await locationProvider.requestLocation()
            let observation = try await service.fetchObservation(for: location)
            latestObservation = observation
        } catch {
            lastError = describe(error: error)
        }
        isFetching = false
    }

    private func describe(error: Error) -> String {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return "Location permission is required to fetch WeatherKit data."
            case .network:
                return "Network unavailable. Try again later."
            default:
                return clError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}

#if DEBUG
private struct PreviewAtmosphereService: AtmosphericProviding {
    func fetchObservation(for location: CLLocation) async throws -> AtmosphericObservation {
        AtmosphericObservation(timestamp: Date(),
                               seaLevelPressureHPa: 1015,
                               surfacePressureHPa: 1014,
                               temperatureCelsius: 19,
                               conditionDescription: "Fair",
                               trend: .steady)
    }
}

private struct PreviewLocationProvider: LocationProviding {
    func requestLocation() async throws -> CLLocation {
        CLLocation(latitude: 37.3349, longitude: -122.0090)
    }
}

extension AtmosphereStore {
    static func preview() -> AtmosphereStore {
        AtmosphereStore(service: PreviewAtmosphereService(), locationProvider: PreviewLocationProvider())
    }
}
#endif
