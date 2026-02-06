import SwiftUI

struct ProfileView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var atmosphereStore: AtmosphereStore
    @State private var showSeaLevelInfo = false

    private var regionIdentifier: String {
        Locale.current.region?.identifier ?? String(localized: "profile.region.unknown")
    }

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                calibrationSection
                weatherKitSection
                supportSection
                aboutSection
            }
            .navigationTitle("profile.navigation.title")
            .sheet(isPresented: $showSeaLevelInfo) {
                seaLevelInfoSheet
            }
        }
    }

    private var unitsSection: some View {
        Section(header: Text("profile.section.units")) {
            Picker("profile.picker.units", selection: $settingsStore.preferredUnit) {
                ForEach(MeasurementUnit.allCases) { unit in
                    Text(unit.displayNameKey).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("profile.units.picker")

            Picker("profile.picker.pressureUnits", selection: $settingsStore.pressureUnit) {
                ForEach(PressureUnit.allCases) { unit in
                    Text(unit.displayNameKey).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("profile.pressure.picker")
        }
    }

    private var calibrationSection: some View {
        Section(header: Text("profile.section.calibration"), footer: Text(calibrationFooterText)) {
            HStack {
                Text("profile.label.seaLevelPressure")
                Spacer()
                Text(PressureFormatter.formatted(kPa: settingsStore.seaLevelPressureKPa, unit: settingsStore.pressureUnit))
                    .foregroundStyle(.secondary)
            }
            Slider(value: seaLevelPressureBinding, in: seaLevelPressureRange, step: seaLevelPressureStep)
                .accessibilityIdentifier("profile.seaLevel.slider")
            Button("profile.action.whatIsThis") {
                showSeaLevelInfo = true
            }
        }
    }

    private var weatherKitSection: some View {
        Section(header: Text("profile.section.weatherKit")) {
            Toggle("profile.weatherKit.toggle.auto", isOn: $settingsStore.weatherKitAutoCalibrationEnabled)
                .accessibilityIdentifier("profile.weatherKit.toggle.auto")

            if atmosphereStore.isFetching {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("insights.progress.weather")
                        .foregroundStyle(.secondary)
                }
            } else if let error = atmosphereStore.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            } else if let observation = atmosphereStore.latestObservation {
                VStack(alignment: .leading, spacing: 6) {
                    Text("profile.weatherKit.latest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(weatherKitSummary(observation))
                        .font(.subheadline)
                }
            } else {
                Text("profile.weatherKit.empty")
                    .foregroundStyle(.secondary)
            }

            if let last = settingsStore.weatherKitLastCalibrationDate {
                HStack {
                    Text("profile.weatherKit.lastUpdated")
                    Spacer()
                    Text(relativeDate(last))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    await atmosphereStore.refresh()
                    if let observation = atmosphereStore.latestObservation {
                        settingsStore.applyWeatherKitSeaLevelPressure(hPa: observation.seaLevelPressureHPa, timestamp: observation.timestamp)
                    }
                }
            } label: {
                Label("profile.action.refreshWeather", systemImage: "arrow.clockwise")
            }
            .disabled(atmosphereStore.isFetching)
        }
    }

    private var supportSection: some View {
        Section(header: Text("profile.section.support")) {
            Link(destination: URL(string: "mailto:howhigh@37.technology")!) {
                Label("profile.link.contactSupport", systemImage: "envelope")
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text("profile.section.about")) {
            VStack(alignment: .leading, spacing: 4) {
                Text("profile.about.appName")
                    .font(.headline)
                Text(appVersionDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersionDescription: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        let format = String(localized: "profile.about.version.format", bundle: .main)
        return String(format: format, locale: .autoupdatingCurrent, version, build)
    }

    private var seaLevelPressureBinding: Binding<Double> {
        Binding(get: {
            settingsStore.pressureUnit.value(fromKPa: settingsStore.seaLevelPressureKPa)
        }, set: { newValue in
            settingsStore.seaLevelPressureKPa = settingsStore.pressureUnit == .hectopascals ? newValue / 10.0 : newValue
        })
    }

    private var seaLevelPressureRange: ClosedRange<Double> {
        settingsStore.pressureUnit == .hectopascals ? 950...1050 : 95...105
    }

    private var seaLevelPressureStep: Double {
        settingsStore.pressureUnit == .hectopascals ? 1.0 : 0.1
    }

    private var calibrationFooterText: String {
        let format = String(localized: "profile.calibration.footer", bundle: .main)
        let typicalValue = PressureFormatter.formatted(kPa: 101.325, unit: settingsStore.pressureUnit)
        return String(format: format, locale: .autoupdatingCurrent, typicalValue)
    }

    private var seaLevelInfoSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("profile.info.title")
                    .font(.title2).bold()
                Text("profile.info.description")
                let format = String(localized: "profile.info.tip.format", bundle: .main)
                Text(String(format: format, locale: .autoupdatingCurrent, regionIdentifier))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("profile.section.calibration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") {
                        showSeaLevelInfo = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func weatherKitSummary(_ observation: AtmosphericObservation) -> String {
        let pressure = PressureFormatter.formatted(hPa: observation.seaLevelPressureHPa, unit: settingsStore.pressureUnit)
        let trendText = NSLocalizedString(observation.trend.descriptionKey, comment: "")

        let temperatureMeasurement = Measurement(value: observation.temperatureCelsius, unit: UnitTemperature.celsius)
        let temperature = temperatureFormatter.string(from: temperatureMeasurement)

        let format = String(localized: "profile.weatherKit.summary.format", bundle: .main)
        return String(format: format, locale: .autoupdatingCurrent, pressure, trendText, temperature)
    }

    private var temperatureFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.locale = .autoupdatingCurrent
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ProfileView(settingsStore: SettingsStore(), atmosphereStore: AtmosphereStore.preview())
}
