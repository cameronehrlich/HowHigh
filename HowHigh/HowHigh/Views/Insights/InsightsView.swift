import SwiftUI
import CoreLocation
import UIKit

struct InsightsView: View {
    @ObservedObject var viewModel: InsightsViewModel
    @ObservedObject var atmosphereStore: AtmosphereStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                if atmosphereStore.isFetching {
                    Section {
                        ProgressView(String(localized: "insights.progress.weather"))
                    }
                } else if let error = atmosphereStore.lastError {
                    Section {
                        Label(LocalizedStringKey(error.messageLocalizationKey), systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        if error.supportsOpenSettings {
                            Button("profile.action.openSettings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                        }
                    }
                }

                ForEach(viewModel.cards) { card in
                    InsightRow(card: card)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("insights.navigation.title")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await atmosphereStore.refresh() }
                    } label: {
                        if atmosphereStore.isFetching {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(atmosphereStore.isFetching)
                }
            }
            .task {
                if atmosphereStore.latestObservation == nil && !atmosphereStore.isFetching {
                    await atmosphereStore.refresh()
                }
            }
        }
    }
}

private struct InsightRow: View {
    let card: InsightCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.headline)
            Text(card.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var backgroundColor: Color {
        switch card.style {
        case .info:
            return Color.blue.opacity(0.15)
        case .warning:
            return Color.orange.opacity(0.2)
        case .success:
            return Color.green.opacity(0.2)
        }
    }
}

#Preview {
    let sessionStore = SessionStore(controller: PersistenceController(inMemory: true))
    let settings = SettingsStore()
    let atmosphere = AtmosphereStore.preview()
    let viewModel = InsightsViewModel(sessionStore: sessionStore, settingsStore: settings, atmosphereStore: atmosphere)
    return InsightsView(viewModel: viewModel, atmosphereStore: atmosphere)
}
