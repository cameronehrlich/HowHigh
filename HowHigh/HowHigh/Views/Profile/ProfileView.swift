import SwiftUI

struct ProfileView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var showSeaLevelInfo = false

    private var regionIdentifier: String {
        Locale.current.region?.identifier ?? String(localized: "profile.region.unknown")
    }

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                calibrationSection
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
}

#Preview {
    ProfileView(settingsStore: SettingsStore())
}
