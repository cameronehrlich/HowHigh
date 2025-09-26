import SwiftUI

struct ProfileView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var atmosphereStore: AtmosphereStore
    @State private var showSeaLevelInfo = false

    private var temperatureFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.locale = .autoupdatingCurrent
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }

    private var regionIdentifier: String {
        Locale.current.region?.identifier ?? String(localized: "profile.region.unknown")
    }

    private func observationSummary(for observation: AtmosphericObservation) -> String {
        let pressure = PressureFormatter.hectopascals(fromKilopascals: observation.seaLevelPressureHPa / 10.0)
        let temperatureMeasurement = Measurement(value: observation.temperatureCelsius, unit: UnitTemperature.celsius)
        let temperature = temperatureFormatter.string(from: temperatureMeasurement)
        let format = String(localized: "profile.weatherKit.summary.format", bundle: .main)
        return String(format: format, locale: .autoupdatingCurrent, pressure, observation.conditionDescription, temperature)
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
        }
    }

    private var calibrationSection: some View {
        Section(header: Text("profile.section.calibration"), footer: Text("profile.calibration.footer")) {
            HStack {
                Text("profile.label.seaLevelPressure")
                Spacer()
                Text(PressureFormatter.kilopascals(settingsStore.seaLevelPressureKPa))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $settingsStore.seaLevelPressureKPa, in: 95...105, step: 0.1)
                .accessibilityIdentifier("profile.seaLevel.slider")
            Button("profile.action.whatIsThis") {
                showSeaLevelInfo = true
            }
        }
    }

    private var weatherKitSection: some View {
        Section(header: Text("profile.section.weatherKit")) {
            if let observation = atmosphereStore.latestObservation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("profile.weatherKit.latest")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(observationSummary(for: observation))
                    Button {
                        let kPa = observation.seaLevelPressureHPa / 10.0
                        settingsStore.seaLevelPressureKPa = kPa
                    } label: {
                        let appliedValue = PressureFormatter.kilopascals(observation.seaLevelPressureHPa / 10.0)
                        let format = String(localized: "profile.action.applyPressure.format", bundle: .main)
                        let labelText = String(format: format, locale: .autoupdatingCurrent, appliedValue)
                        Label(labelText, systemImage: "checkmark.circle")
                    }
                    .accessibilityLabel(String(localized: "profile.action.applyPressure.accessibility", bundle: .main))
                }
            } else {
                Text("profile.weatherKit.empty")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await atmosphereStore.refresh() }
            } label: {
                if atmosphereStore.isFetching {
                    ProgressView()
                } else {
                    Label("profile.action.refreshWeather", systemImage: "arrow.clockwise")
                }
            }
            .disabled(atmosphereStore.isFetching)

            if let error = atmosphereStore.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var supportSection: some View {
        Section(header: Text("profile.section.support")) {
            Link(destination: URL(string: "https://support.apple.com/en-us/HT207106")!) {
                Label("profile.link.barometerTips", systemImage: "link")
            }
            Link(destination: URL(string: "mailto:hello@howhigh.app")!) {
                Label("profile.link.contactSupport", systemImage: "envelope")
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text("profile.section.about")) {
            VStack(alignment: .leading, spacing: 4) {
                Text("profile.about.appName")
                    .font(.headline)
                Text("profile.about.version")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
}

#Preview {
    ProfileView(settingsStore: SettingsStore(), atmosphereStore: AtmosphereStore.preview())
}
