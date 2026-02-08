import Foundation
import CoreLocation
import OSLog

enum NWSStationStoreError: Equatable {
    case locationDenied
    case locationUnavailable
    case networkUnavailable
    case outsideUS
    case noSeaLevelPressure
    case unknown

    var messageLocalizationKey: String {
        switch self {
        case .locationDenied:
            return "nws.error.locationDenied"
        case .locationUnavailable:
            return "nws.error.locationUnavailable"
        case .networkUnavailable:
            return "nws.error.networkUnavailable"
        case .outsideUS:
            return "nws.error.outsideUS"
        case .noSeaLevelPressure:
            return "nws.error.noSeaLevelPressure"
        case .unknown:
            return "nws.error.generic"
        }
    }
}

@MainActor
final class NWSStationStore: ObservableObject {
    @Published private(set) var stations: [NWSStation] = []
    @Published private(set) var isFetchingStations: Bool = false
    @Published private(set) var isFetchingObservation: Bool = false
    @Published private(set) var lastError: NWSStationStoreError?

    private let service: NWSProviding
    private let locationProvider: LocationProviding
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "HowHigh", category: "NWSStationStore")

    init(service: NWSProviding = NWSService(), locationProvider: LocationProviding = LocationProvider()) {
        self.service = service
        self.locationProvider = locationProvider
    }

    func loadNearbyStations() async {
        isFetchingStations = true
        lastError = nil
        do {
            let location = try await locationProvider.requestLocation()
            stations = try await service.nearbyStations(for: location)
        } catch {
            // Simulator often lacks a configured location; use a fixed demo coordinate to keep UI testable.
            if isLocationUnknown(error: error), isSimulator {
                do {
                    let demo = CLLocation(latitude: 37.3349, longitude: -122.0090)
                    stations = try await service.nearbyStations(for: demo)
                    lastError = nil
                } catch {
                    log(error: error, context: "loadNearbyStations(simulatorFallback)")
                    lastError = map(error: error)
                }
            } else {
                log(error: error, context: "loadNearbyStations")
                lastError = map(error: error)
            }
        }
        isFetchingStations = false
    }

    func fetchSeaLevelPressure(stationId: String) async -> NWSSeaLevelPressureObservation? {
        isFetchingObservation = true
        lastError = nil
        defer { isFetchingObservation = false }
        do {
            return try await service.latestSeaLevelPressure(for: stationId)
        } catch {
            log(error: error, context: "fetchSeaLevelPressure")
            lastError = map(error: error)
            return nil
        }
    }

    private func map(error: Error) -> NWSStationStoreError {
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
        let nsError = error as NSError
        if nsError.domain == kCLErrorDomain, let clCode = CLError.Code(rawValue: nsError.code) {
            switch clCode {
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
        if let nwsError = error as? NWSServiceError {
            switch nwsError {
            case .outsideUS:
                return .outsideUS
            case .missingSeaLevelPressure:
                return .noSeaLevelPressure
            default:
                return .unknown
            }
        }
        return .unknown
    }

    private func log(error: Error, context: String) {
        let nsError = error as NSError
        logger.error("NWS failed (\(context, privacy: .public)). type=\(String(describing: type(of: error)), privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public) description=\(nsError.localizedDescription, privacy: .public)")
    }

    private func isLocationUnknown(error: Error) -> Bool {
        if let clError = error as? CLError { return clError.code == .locationUnknown }
        let nsError = error as NSError
        return nsError.domain == kCLErrorDomain && nsError.code == CLError.Code.locationUnknown.rawValue
    }

    private var isSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
}
