import Foundation
import CoreLocation

enum NWSServiceError: Error {
    case httpStatus(Int)
    case outsideUS
    case missingStationsURL
    case missingSeaLevelPressure
}

struct NWSStation: Identifiable {
    let id: String
    let name: String?
    let coordinate: CLLocationCoordinate2D?
    let distanceMeters: Double?
}

struct NWSSeaLevelPressureObservation {
    let stationId: String
    let stationName: String?
    let timestamp: Date
    let seaLevelPressureHPa: Double
}

protocol NWSProviding {
    func nearbyStations(for location: CLLocation) async throws -> [NWSStation]
    func latestSeaLevelPressure(for stationId: String) async throws -> NWSSeaLevelPressureObservation
}

final class NWSService: NWSProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func nearbyStations(for location: CLLocation) async throws -> [NWSStation] {
        // Always format with '.' decimal separator regardless of user locale.
        let posix = Locale(identifier: "en_US_POSIX")
        let lat = String(format: "%.4f", locale: posix, location.coordinate.latitude)
        let lon = String(format: "%.4f", locale: posix, location.coordinate.longitude)
        let pointsURL = URL(string: "https://api.weather.gov/points/\(lat),\(lon)")!

        let points: NWSPointResponse = try await getJSON(pointsURL)
        guard let stationsURL = points.properties.observationStations else {
            throw NWSServiceError.missingStationsURL
        }

        let collection: NWSStationCollection = try await getJSON(stationsURL)

        let stations: [NWSStation] = collection.features.compactMap { feature in
            let id = feature.properties.stationIdentifier
            let name = feature.properties.name
            let coordinate: CLLocationCoordinate2D?
            if let coords = feature.geometry?.coordinates, coords.count >= 2 {
                coordinate = CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
            } else {
                coordinate = nil
            }
            let distanceMeters: Double?
            if let coordinate {
                distanceMeters = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: location)
            } else {
                distanceMeters = nil
            }
            return NWSStation(id: id, name: name, coordinate: coordinate, distanceMeters: distanceMeters)
        }

        return stations.sorted(by: { (a, b) -> Bool in
            switch (a.distanceMeters, b.distanceMeters) {
            case let (lhs?, rhs?):
                return lhs < rhs
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            default:
                return a.id < b.id
            }
        })
    }

    func latestSeaLevelPressure(for stationId: String) async throws -> NWSSeaLevelPressureObservation {
        let url = URL(string: "https://api.weather.gov/stations/\(stationId)/observations/latest")!
        let observation: NWSLatestObservationResponse = try await getJSON(url)

        let hPa: Double
        if let seaLevelPressurePa = observation.properties.seaLevelPressure?.value {
            hPa = seaLevelPressurePa / 100.0
        } else if let stationPressurePa = observation.properties.barometricPressure?.value,
                  let elevationMeters = observation.properties.elevation?.value,
                  let computed = Self.computeSeaLevelPressureHPa(stationPressurePa: stationPressurePa, elevationMeters: elevationMeters) {
            // Many NWS stations omit `seaLevelPressure` but provide station pressure + elevation.
            // Compute SLP using the same ISA model used by our altitude estimation for self-consistency.
            hPa = computed
        } else {
            throw NWSServiceError.missingSeaLevelPressure
        }

        let timestamp = parseISO8601(observation.properties.timestamp) ?? Date()
        return NWSSeaLevelPressureObservation(
            stationId: stationId,
            stationName: observation.properties.stationName,
            timestamp: timestamp,
            seaLevelPressureHPa: hPa
        )
    }

    private func getJSON<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        // NWS API requests a descriptive User-Agent with contact info.
        request.setValue("HowHigh iOS (howhigh@37.technology)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NWSServiceError.httpStatus(-1)
        }

        // NWS returns 404 for points outside coverage, as well as JSON error bodies for some cases.
        if http.statusCode == 404 {
            throw NWSServiceError.outsideUS
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NWSServiceError.httpStatus(http.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func parseISO8601(_ value: String?) -> Date? {
        guard let value else { return nil }
        // NWS timestamps sometimes include fractional seconds.
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: value) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: value)
    }

    static func computeSeaLevelPressureHPa(stationPressurePa: Double, elevationMeters: Double) -> Double? {
        // Invert: altitude = 44330 * (1 - (P/P0)^0.1903)  ->  P0 = P / (1 - h/44330)^(1/0.1903)
        // Note: stationPressurePa is expected to be the local (station) pressure at the station's elevation.
        let denom = 1.0 - (elevationMeters / 44330.0)
        guard denom > 0 else { return nil }
        let stationPressureHPa = stationPressurePa / 100.0
        return stationPressureHPa / pow(denom, 5.255)
    }
}

private struct NWSPointResponse: Decodable {
    struct Properties: Decodable {
        let observationStations: URL?
    }
    let properties: Properties
}

private struct NWSStationCollection: Decodable {
    struct Feature: Decodable {
        struct Geometry: Decodable {
            let coordinates: [Double]?
        }
        struct StationProperties: Decodable {
            let stationIdentifier: String
            let name: String?
        }

        let geometry: Geometry?
        let properties: StationProperties
    }

    let features: [Feature]
}

private struct NWSLatestObservationResponse: Decodable {
    struct QuantitativeValue: Decodable {
        let value: Double?
        let unitCode: String?
    }

    struct Properties: Decodable {
        let timestamp: String?
        let seaLevelPressure: QuantitativeValue?
        let barometricPressure: QuantitativeValue?
        let elevation: QuantitativeValue?
        let stationName: String?
    }

    let properties: Properties
}
