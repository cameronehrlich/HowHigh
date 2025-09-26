import Foundation
import WeatherKit
import CoreLocation

protocol AtmosphericProviding {
    func fetchObservation(for location: CLLocation) async throws -> AtmosphericObservation
}

final class AtmosphereService: AtmosphericProviding {
    private let weatherService: WeatherService

    init(weatherService: WeatherService = .shared) {
        self.weatherService = weatherService
    }

    func fetchObservation(for location: CLLocation) async throws -> AtmosphericObservation {
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        let seaLevelPressure = current.pressure.converted(to: .hectopascals).value
        let surfacePressure = weather.currentWeather.pressure.converted(to: .hectopascals).value
        let temperature = current.temperature.converted(to: .celsius).value
        let trend: AtmosphericObservation.Trend
        switch current.pressureTrend {
        case .rising:
            trend = .rising
        case .falling:
            trend = .falling
        default:
            trend = .steady
        }

        let description = current.condition.description

        return AtmosphericObservation(timestamp: Date(),
                                      seaLevelPressureHPa: seaLevelPressure,
                                      surfacePressureHPa: surfacePressure,
                                      temperatureCelsius: temperature,
                                      conditionDescription: description,
                                      trend: trend)
    }
}
