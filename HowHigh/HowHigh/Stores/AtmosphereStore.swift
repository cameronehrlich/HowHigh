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
    // Surface diagnostics in TestFlight builds to help debug WeatherKit provisioning/outages.
    @Published private(set) var lastErrorDebugDescription: String?

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
        lastErrorDebugDescription = nil
        do {
            let location = try await locationProvider.requestLocation()
            let observation = try await service.fetchObservation(for: location)
            latestObservation = observation
        } catch {
            log(error: error)
            lastError = map(error: error)
            lastErrorDebugDescription = debugDescription(for: error)
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

        // WeatherKit and networking stacks frequently wrap the real cause in NSUnderlyingErrorKey.
        if let underlying = underlyingError(from: nsError) {
            let mapped = map(error: underlying)
            if mapped != .unknown {
                return mapped
            }
        }

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

    private func underlyingError(from error: NSError, maxDepth: Int = 4) -> Error? {
        var current: NSError? = error
        for _ in 0..<maxDepth {
            guard let next = current?.userInfo[NSUnderlyingErrorKey] as? NSError else { return nil }
            if next.domain != current?.domain || next.code != current?.code {
                return next
            }
            current = next
        }
        return nil
    }

    private func debugDescription(for error: Error) -> String {
        let nsError = error as NSError
        var parts: [String] = [
            "domain=\(nsError.domain)",
            "code=\(nsError.code)"
        ]

        var current: NSError? = nsError
        var depth = 0
        while let next = current?.userInfo[NSUnderlyingErrorKey] as? NSError, depth < 4 {
            parts.append("underlying=\(next.domain)(\(next.code))")
            current = next
            depth += 1
        }
        return parts.joined(separator: " • ")
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
