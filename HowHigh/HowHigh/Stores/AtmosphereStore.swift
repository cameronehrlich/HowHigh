import Foundation
import CoreLocation
import OSLog

enum AtmosphereStoreError: Equatable {
    case locationDenied
    case locationUnavailable
    case networkUnavailable
    case serviceUnavailable
    case unknown

    var messageLocalizationKey: String {
        switch self {
        case .locationDenied:
            return "weatherkit.error.locationDenied"
        case .locationUnavailable:
            return "weatherkit.error.locationUnavailable"
        case .networkUnavailable:
            return "weatherkit.error.networkUnavailable"
        case .serviceUnavailable:
            return "weatherkit.error.serviceUnavailable"
        case .unknown:
            return "weatherkit.error.generic"
        }
    }

    var supportsOpenSettings: Bool {
        switch self {
        case .locationDenied:
            return true
        case .locationUnavailable, .networkUnavailable, .serviceUnavailable, .unknown:
            return false
        }
    }
}

@MainActor
final class AtmosphereStore: ObservableObject {
    @Published private(set) var latestObservation: AtmosphericObservation?
    @Published private(set) var isFetching: Bool = false
    @Published private(set) var lastError: AtmosphereStoreError?

    private let service: AtmosphericProviding
    private let locationProvider: LocationProviding
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HowHigh", category: "AtmosphereStore")

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
            log(error: error)
            lastError = map(error: error)
        }
        isFetching = false
    }

    private func map(error: Error) -> AtmosphereStoreError {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .locationDenied
            case .locationUnknown:
                return .locationUnavailable
            case .network:
                return .networkUnavailable
            default:
                return .unknown
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .dnsLookupFailed:
                return .networkUnavailable
            default:
                break
            }
        }
        let nsError = error as NSError
        // WeatherKit failures are frequently surfaced as NSError with opaque domains/codes.
        // We use a separate bucket for better user messaging while keeping logs detailed.
        if nsError.domain.lowercased().contains("weather") {
            return .serviceUnavailable
        }
        return .unknown
    }

    private func log(error: Error) {
        let nsError = error as NSError
        logger.error("WeatherKit refresh failed. type=\(String(describing: type(of: error)), privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public) description=\(nsError.localizedDescription, privacy: .public)")
    }
}

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
