import Foundation
import CoreMotion
import Combine

struct AltitudeReading {
    let timestamp: Date
    let relativeAltitudeMeters: Double
    let pressureKPa: Double
    let absoluteAltitudeMeters: Double
}

final class AltitudeService: ObservableObject {
    static let preview = AltitudeService(altimeter: nil, queue: .main, isPreview: true)

    @Published private(set) var authorizationStatus: CMAuthorizationStatus = .notDetermined
    @Published private(set) var availabilityStatus: Bool = CMAltimeter.isRelativeAltitudeAvailable()

    private let altimeter: CMAltimeter?
    private let queue: OperationQueue
    private var isPreview: Bool

    private let readingsSubject = PassthroughSubject<AltitudeReading, Never>()
    private var previewTimer: AnyCancellable?
    private var basePressureKPa: Double = 101.325 // default sea-level pressure

    var readings: AnyPublisher<AltitudeReading, Never> {
        readingsSubject.eraseToAnyPublisher()
    }

    init(altimeter: CMAltimeter? = CMAltimeter(), queue: OperationQueue = OperationQueue()) {
        self.altimeter = altimeter
        self.queue = queue
        self.isPreview = false
        self.queue.name = "com.howhigh.altimeter"
        self.queue.maxConcurrentOperationCount = 1
        self.authorizationStatus = CMAltimeter.authorizationStatus()
    }

    private init(altimeter: CMAltimeter?, queue: OperationQueue, isPreview: Bool) {
        self.altimeter = altimeter
        self.queue = queue
        self.isPreview = isPreview
        if isPreview {
            startPreview()
        }
    }

    func startUpdates() {
        guard !isPreview else {
            startPreview()
            return
        }

        guard CMAltimeter.isRelativeAltitudeAvailable(), let altimeter else {
            DispatchQueue.main.async {
                self.availabilityStatus = false
            }
            return
        }

        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async {
                    self.availabilityStatus = false
                    print("Altimeter error: \(error.localizedDescription)")
                }
                return
            }
            guard let data else { return }
            let pressureKPa = data.pressure.doubleValue
            let reading = AltitudeReading(timestamp: Date(),
                                           relativeAltitudeMeters: data.relativeAltitude.doubleValue,
                                           pressureKPa: pressureKPa,
                                           absoluteAltitudeMeters: self.estimateAltitude(from: pressureKPa))
            DispatchQueue.main.async {
                self.readingsSubject.send(reading)
            }
        }
    }

    func stopUpdates() {
        guard !isPreview else {
            previewTimer?.cancel()
            return
        }
        altimeter?.stopRelativeAltitudeUpdates()
    }

    func setSeaLevelPressure(kPa: Double) {
        basePressureKPa = kPa
    }

    private func estimateAltitude(from pressureKPa: Double) -> Double {
        let seaLevelPressureHPa = basePressureKPa * 10.0
        let pressureHPa = pressureKPa * 10.0
        let ratio = pressureHPa / seaLevelPressureHPa
        return max(0, 44330.0 * (1.0 - pow(ratio, 0.1903)))
    }

    private func startPreview() {
        previewTimer?.cancel()
        var time: Double = 0
        let baseAltitude: Double = 150
        previewTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                time += 1
                let drift = sin(time / 15.0) * 5
                let climb = max(0, sin(time / 30.0) * 50)
                let absolute = baseAltitude + drift + climb
                let pressureHPa = 1013.25 - absolute * 0.12
                let reading = AltitudeReading(timestamp: Date(),
                                               relativeAltitudeMeters: drift + climb,
                                               pressureKPa: pressureHPa / 10.0,
                                               absoluteAltitudeMeters: absolute)
                self.readingsSubject.send(reading)
            }
    }
}
