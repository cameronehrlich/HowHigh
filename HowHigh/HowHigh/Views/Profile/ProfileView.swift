import SwiftUI
import UIKit

struct ProfileView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var atmosphereStore: AtmosphereStore
    @State private var showSeaLevelInfo = false
    @State private var showContactFallback = false
    @State private var showStationPicker = false
    @StateObject private var nwsStationStore = NWSStationStore()
    @Environment(\.openURL) private var openURL

    private var regionIdentifier: String {
        Locale.current.region?.identifier ?? String(localized: "profile.region.unknown")
    }

    private let supportEmailAddress = "howhigh@37.technology"

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                displaySection
                calibrationSection
                weatherKitSection
                supportSection
                aboutSection
            }
            .navigationTitle("tab.settings.title")
            .sheet(isPresented: $showSeaLevelInfo) {
                seaLevelInfoSheet
            }
            .alert("profile.contact.fallback.title", isPresented: $showContactFallback) {
                Button("common.copy") {
                    UIPasteboard.general.string = supportEmailAddress
                }
                Button("common.ok", role: .cancel) {}
            } message: {
                let format = String(localized: "profile.contact.fallback.message.format", bundle: .main)
                Text(String(format: format, locale: .autoupdatingCurrent, supportEmailAddress))
            }
        }
    }

    private var displaySection: some View {
        Section(header: Text("profile.section.display")) {
            Toggle("profile.display.showChart", isOn: $settingsStore.showChart)
            Toggle("profile.display.keepScreenOn", isOn: $settingsStore.keepScreenOn)
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

            stationCalibrationSection
        }
    }

    @ViewBuilder
    private var stationCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.vertical, 4)

            HStack {
                Text("profile.stationCalibration.title")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("profile.stationCalibration.usOnly")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let stationId = settingsStore.nwsStationIdentifier {
                HStack {
                    Text("profile.stationCalibration.selected")
                    Spacer()
                    Text(settingsStore.nwsStationName?.isEmpty == false ? settingsStore.nwsStationName! : stationId)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.footnote)

                if let last = settingsStore.nwsLastCalibrationDate {
                    HStack {
                        Text("profile.stationCalibration.lastUpdated")
                        Spacer()
                        Text(relativeDate(last))
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                }

                Button {
                    Task {
                        if let obs = await nwsStationStore.fetchSeaLevelPressure(stationId: stationId) {
                            settingsStore.applyNWSSeaLevelPressure(
                                hPa: obs.seaLevelPressureHPa,
                                stationIdentifier: obs.stationId,
                                stationName: obs.stationName,
                                timestamp: obs.timestamp
                            )
                        }
                    }
                } label: {
                    if nwsStationStore.isFetchingObservation {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("profile.stationCalibration.refreshing")
                        }
                    } else {
                        Label("profile.stationCalibration.refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(nwsStationStore.isFetchingObservation)
            }

            Button {
                showStationPicker = true
            } label: {
                Label("profile.stationCalibration.select", systemImage: "location")
            }
            .disabled(nwsStationStore.isFetchingStations)
            .sheet(isPresented: $showStationPicker) {
                stationPickerSheet
            }

            if nwsStationStore.isFetchingStations {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("profile.stationCalibration.loadingStations")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
            } else if let error = nwsStationStore.lastError {
                Label(LocalizedStringKey(error.messageLocalizationKey), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.footnote)
                if error == .locationDenied {
                    Button("profile.action.openSettings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(.footnote)
                }
            }
        }
    }

    private var stationPickerSheet: some View {
        NavigationStack {
            Group {
                if nwsStationStore.isFetchingStations {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("profile.stationCalibration.loadingStations")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if let error = nwsStationStore.lastError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.orange)
                        Text(LocalizedStringKey(error.messageLocalizationKey))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if error == .locationDenied {
                            Button("profile.action.openSettings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                } else if nwsStationStore.stations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("profile.stationCalibration.emptyStations")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(nwsStationStore.stations.prefix(12)) { station in
                            Button {
                                Task {
                                    if let obs = await nwsStationStore.fetchSeaLevelPressure(stationId: station.id) {
                                        settingsStore.applyNWSSeaLevelPressure(
                                            hPa: obs.seaLevelPressureHPa,
                                            stationIdentifier: obs.stationId,
                                            stationName: obs.stationName ?? station.name,
                                            timestamp: obs.timestamp
                                        )
                                        showStationPicker = false
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(station.name ?? station.id)
                                        .font(.body)
                                    HStack(spacing: 8) {
                                        Text(station.id)
                                        if let meters = station.distanceMeters {
                                            Text(String(format: String(localized: "profile.stationCalibration.distance.format"), locale: .autoupdatingCurrent, meters / 1000.0))
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .disabled(nwsStationStore.isFetchingObservation)
                        }
                    }
                }
            }
            .navigationTitle("profile.stationCalibration.selectTitle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") { showStationPicker = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("profile.stationCalibration.reload") {
                        Task { await nwsStationStore.loadNearbyStations() }
                    }
                    .disabled(nwsStationStore.isFetchingStations)
                }
            }
            .task {
                if nwsStationStore.stations.isEmpty, !nwsStationStore.isFetchingStations {
                    await nwsStationStore.loadNearbyStations()
                }
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
                Label(LocalizedStringKey(error.messageLocalizationKey), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                if let debug = atmosphereStore.lastErrorDebugDescription {
                    Text(debug)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                if error.supportsOpenSettings {
                    Button("profile.action.openSettings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
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
            Button {
                ReviewManager.openWriteReview()
            } label: {
                Label("profile.action.writeReview", systemImage: "star")
            }

            Button {
                let subject = "HowHigh Support"
                let mailto = "mailto:\(supportEmailAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)"
                if let url = URL(string: mailto) {
                    if UIApplication.shared.canOpenURL(url) {
                        openURL(url)
                    } else {
                        showContactFallback = true
                    }
                } else {
                    showContactFallback = true
                }
            } label: {
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
