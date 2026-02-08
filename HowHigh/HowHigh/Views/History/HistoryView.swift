import SwiftUI
import UIKit

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @ObservedObject var settingsStore: SettingsStore
    @State private var shareURL: URL?
    @State private var shareErrorMessage: String?

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
                                SessionDetailView(mode: session.mode,
                                                  session: session,
                                                  settingsStore: settingsStore,
                                                  onDelete: {
                                                      await viewModel.delete(session)
                                                  })
                            } label: {
                                HistoryRow(session: session, settingsStore: settingsStore)
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(session) }
                                } label: {
                                    Label(String(localized: "common.delete"), systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    share(session: session)
                                } label: {
                                    Label(String(localized: "common.share"), systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("history.navigation.title")
        }
        .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
            if let shareURL {
                ActivityView(activityItems: [shareURL])
            }
        }
        .alert("common.error", isPresented: Binding(get: { shareErrorMessage != nil }, set: { if !$0 { shareErrorMessage = nil } })) {
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: {
            Text(shareErrorMessage ?? "")
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

    private func share(session: AltitudeSession) {
        do {
            shareURL = try SessionExportService.exportCSV(
                session: session,
                preferredUnit: settingsStore.preferredUnit,
                pressureUnit: settingsStore.pressureUnit
            )
        } catch {
            shareErrorMessage = error.localizedDescription
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
                            Text(PressureFormatter.formatted(kPa: high, unit: settingsStore.pressureUnit))
                        } icon: {
                            Image(systemName: "arrow.up")
                        }
                    }
                    if let low = pressures.min() {
                        Label {
                            Text(PressureFormatter.formatted(kPa: low, unit: settingsStore.pressureUnit))
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

// Simple SwiftUI wrapper for UIActivityViewController (share sheet).
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
