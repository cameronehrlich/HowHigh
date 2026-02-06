import SwiftUI
import Charts

struct SessionDetailView: View {
    let mode: AltitudeSession.Mode
    let session: AltitudeSession
    @ObservedObject var settingsStore: SettingsStore
    let onDelete: (() async -> Void)?
    @State private var selectedAltitudeSample: AltitudeSample?
    @State private var selectedPressureSample: AltitudeSample?
    @State private var showDeleteConfirmation: Bool = false
    @Environment(\.dismiss) private var dismiss

    private var samples: [AltitudeSample] {
        session.samples.sorted(by: { $0.timestamp < $1.timestamp })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if mode == .barometer {
                    pressureChart
                    altitudeChart
                } else {
                    altitudeChart
                    pressureChart
                }
                notesSection
            }
            .padding()
            .frame(maxWidth: 900)
        }
        .navigationTitle(session.startDate.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient)
        .toolbar {
            if onDelete != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog(LocalizedStringKey("session.dialog.delete.title"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button(String(localized: "session.action.delete"), role: .destructive) {
                Task {
                    await onDelete?()
                    dismiss()
                }
            }
            Button(String(localized: "common.cancel"), role: .cancel) { }
        } message: {
            Text("session.dialog.delete.message")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("session.overview.title")
                .font(.headline)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(summaryMetrics) { metric in
                        metricView(metric)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(summaryMetrics) { metric in
                        metricView(metric)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.regularMaterial))
    }

    private func metricView(_ metric: DetailMetric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(metric.titleKey, systemImage: metric.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(metric.value)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var altitudeChart: some View {
        SessionInteractiveChart(
            titleKey: "session.chart.title.elevation",
            samples: samples,
            axisLabel: settingsStore.preferredUnit.shortAltitudeDescription,
            selectedSample: $selectedAltitudeSample,
            value: { settingsStore.preferredUnit.convertedAltitude(from: $0.absoluteAltitudeMeters) },
            formattedValue: { settingsStore.preferredUnit.formattedAltitude(meters: $0.absoluteAltitudeMeters) },
            placeholderKey: "session.chart.placeholder"
        )
    }

    private var pressureChart: some View {
        SessionInteractiveChart(
            titleKey: "session.chart.title.pressure",
            samples: samples,
            axisLabel: String(localized: "session.chart.axis.pressure"),
            selectedSample: $selectedPressureSample,
            value: { settingsStore.pressureUnit.value(fromKPa: $0.pressureKPa) },
            formattedValue: { PressureFormatter.formatted(kPa: $0.pressureKPa, unit: settingsStore.pressureUnit) },
            placeholderKey: "session.chart.placeholder"
        )
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("session.notes.title")
                .font(.headline)
            Text(session.note?.isEmpty == false ? session.note! : String(localized: "session.notes.placeholder"))
                .font(.body)
                .foregroundStyle(session.note?.isEmpty == false ? .primary : .secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.regularMaterial))
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [.blue.opacity(0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    private var summaryMetrics: [DetailMetric] {
        let duration = DetailMetric(titleKey: "measure.metric.duration", value: session.duration.formattedHoursMinutesSeconds(), icon: "clock")
        switch mode {
        case .altimeter:
            return [
                DetailMetric(titleKey: "measure.metric.gain", value: settingsStore.preferredUnit.formattedGain(meters: session.totalAscentMeters), icon: "arrow.up"),
                DetailMetric(titleKey: "measure.metric.net", value: settingsStore.preferredUnit.formattedAltitude(meters: session.netAltitudeChangeMeters), icon: "arrow.up.and.down"),
                DetailMetric(titleKey: "measure.metric.loss", value: settingsStore.preferredUnit.formattedGain(meters: session.totalDescentMeters), icon: "arrow.down"),
                duration
            ]
        case .barometer:
            let pressures = samples.map { $0.pressureKPa }
            let high = pressures.max().map { PressureFormatter.formatted(kPa: $0, unit: settingsStore.pressureUnit) } ?? "—"
            let low = pressures.min().map { PressureFormatter.formatted(kPa: $0, unit: settingsStore.pressureUnit) } ?? "—"
            return [
                DetailMetric(titleKey: "measure.metric.high", value: high, icon: "arrow.up"),
                DetailMetric(titleKey: "measure.metric.low", value: low, icon: "arrow.down"),
                duration
            ]
        }
    }
}

private struct DetailMetric: Identifiable {
    let id = UUID()
    let titleKey: LocalizedStringKey
    let value: String
    let icon: String
}

private struct SessionInteractiveChart: View {
    let titleKey: LocalizedStringKey
    let samples: [AltitudeSample]
    let axisLabel: String
    @Binding var selectedSample: AltitudeSample?
    let value: (AltitudeSample) -> Double
    let formattedValue: (AltitudeSample) -> String
    let placeholderKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey)
                .font(.headline)
            if samples.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text(placeholderKey)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(samples) { sample in
                        LineMark(
                            x: .value("session.chart.axis.time", sample.timestamp),
                            y: .value(axisLabel, value(sample))
                        )
                        .interpolationMethod(.catmullRom)
                        if let selectedSample, selectedSample.id == sample.id {
                            RuleMark(x: .value("session.chart.selected", selectedSample.timestamp))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3]))
                                .foregroundStyle(.secondary)
                            PointMark(
                                x: .value("session.chart.axis.time", selectedSample.timestamp),
                                y: .value(axisLabel, value(selectedSample))
                            )
                            .foregroundStyle(.primary)
                        }
                    }
                }
                .frame(height: 220)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSelection(value: value, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    selectedSample = nil
                                }
                            )
                    }
                }
                .chartBackground { _ in
                    if let selectedSample {
                        VStack(alignment: .leading) {
                            Text(selectionLabel(for: selectedSample))
                                .font(.caption)
                                .padding(6)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .padding(.top, 8)
                                .padding(.leading, 8)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.regularMaterial))
    }

    private func selectionLabel(for sample: AltitudeSample) -> String {
        let time = sample.timestamp.formatted(date: .omitted, time: .standard)
        let format = String(localized: "session.chart.selected.detail.format", bundle: .main)
        return String(format: format, locale: .autoupdatingCurrent, time, formattedValue(sample))
    }

    private func updateSelection(value: DragGesture.Value, proxy: ChartProxy, geometry: GeometryProxy) {
        let plotFrame = geometry[proxy.plotAreaFrame]
        let location = CGPoint(
            x: value.location.x - plotFrame.origin.x,
            y: value.location.y - plotFrame.origin.y
        )
        guard location.x >= 0, location.x <= plotFrame.size.width else {
            selectedSample = nil
            return
        }
        guard let date: Date = proxy.value(atX: location.x) else {
            selectedSample = nil
            return
        }
        let nearest = samples.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
        selectedSample = nearest
    }
}

#Preview {
    SessionDetailView(mode: .altimeter,
                      session: AltitudeSession.preview,
                      settingsStore: SettingsStore(),
                      onDelete: nil)
}
