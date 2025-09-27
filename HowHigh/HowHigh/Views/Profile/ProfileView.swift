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
