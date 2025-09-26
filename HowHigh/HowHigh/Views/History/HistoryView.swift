import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("history.empty.title")
                            .font(.headline)
                        Text("history.empty.subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            NavigationLink {
                                SessionDetailView(mode: session.mode, session: session, settingsStore: settingsStore)
                            } label: {
                                HistoryRow(session: session, settingsStore: settingsStore)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("history.navigation.title")
        }
    }

    private func delete(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let session = viewModel.sessions[index]
                await viewModel.delete(session)
            }
        }
    }
}

private struct HistoryRow: View {
    let session: AltitudeSession
    let settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startDate, style: .date)
                    .font(.headline)
                Spacer()
                Text(session.startDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                switch session.mode {
                case .altimeter:
                    Label {
                        Text(settingsStore.preferredUnit.formattedGain(meters: session.totalAscentMeters))
                    } icon: {
                        Image(systemName: "arrow.up")
                    }
                    Label {
                        Text(settingsStore.preferredUnit.formattedGain(meters: session.totalDescentMeters))
                    } icon: {
                        Image(systemName: "arrow.down")
                    }
                case .barometer:
                    let pressures = session.samples.map { $0.pressureKPa }
                    if let high = pressures.max() {
                        Label {
                            Text(PressureFormatter.hectopascals(fromKilopascals: high))
                        } icon: {
                            Image(systemName: "arrow.up")
                        }
                    }
                    if let low = pressures.min() {
                        Label {
                            Text(PressureFormatter.hectopascals(fromKilopascals: low))
                        } icon: {
                            Image(systemName: "arrow.down")
                        }
                    }
                }
                Label {
                    Text(session.duration.formattedHoursMinutes())
                } icon: {
                    Image(systemName: "clock")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
