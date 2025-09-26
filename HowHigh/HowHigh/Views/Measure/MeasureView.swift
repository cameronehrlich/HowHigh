import SwiftUI
import Charts

struct MeasureView: View {
    @ObservedObject var viewModel: MeasureViewModel
    @ObservedObject var settingsStore: SettingsStore
    @State private var showStopConfirmation: Bool = false
    @State private var selectedSample: AltitudeSample?

    private var mode: AltitudeSession.Mode { viewModel.mode }

    private var activeSession: AltitudeSession? {
        viewModel.currentSession ?? viewModel.lastCompletedSession
    }

    private var samples: [AltitudeSample] {
        (viewModel.currentSession?.samples ?? viewModel.lastCompletedSession?.samples) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 24) {
                            readingCard
                            chartCard
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 24) {
                            readingCard
                            chartCard
                        }
                    }
                    sessionSummary
                    controls
                    if !viewModel.recentSessions.isEmpty {
                        sessionHistory
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(mode == .altimeter ? LocalizedStringKey("tab.altimeter.title") : LocalizedStringKey("tab.barometer.title"))
            .toolbar {
                if viewModel.canCalibrate {
                    Button(String(localized: "measure.action.calibrate")) {
                        viewModel.calibrateToCurrentReading()
                    }
                    .disabled(viewModel.currentReading == nil)
                }
            }
            .alert(LocalizedStringKey("measure.alert.barometerUnavailable.title"), isPresented: Binding(get: {
                viewModel.availabilityMessage != nil
            }, set: { _ in
                viewModel.availabilityMessage = nil
            })) {
                Button(String(localized: "common.ok"), role: .cancel) { }
            } message: {
                if let message = viewModel.availabilityMessage {
                    Text(LocalizedStringKey(message))
                }
            }
        }
    }

    private var readingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(primaryMetricTitleKey)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(primaryMetricValue)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(secondaryMetricValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: samples.recentTrend().systemImageName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(trendColor)
                    Text(LocalizedStringKey(samples.recentTrend().descriptionKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            if !viewModel.isRecording {
                Text(idleHintKey)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.regularMaterial))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(chartTitleKey)
                .font(.headline)
            if samples.isEmpty {
                ChartPlaceholder(messageKey: "measure.chart.placeholder")
            } else {
                measurementChart
                    .frame(height: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.regularMaterial))
    }

    private var sessionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("measure.sessionSummary.title")
                .font(.headline)
                .accessibilityIdentifier("measure.sessionSummary.title")
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(summaryMetrics) { metric in
                        summaryMetricTile(metric)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(summaryMetrics) { metric in
                        summaryMetricTile(metric)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.regularMaterial))
    }

    private func summaryMetricTile(_ metric: SummaryMetric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(metric.value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Button(action: primaryAction) {
                Text(primaryButtonTitleKey)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryButtonTint)
            .disabled(primaryButtonDisabled)

            HStack(spacing: 16) {
                Button(action: viewModel.isRecording ? viewModel.pauseRecording : viewModel.resumeRecording) {
                    Label(viewModel.isRecording ? LocalizedStringKey("measure.action.pause") : LocalizedStringKey("measure.action.resume"), systemImage: viewModel.isRecording ? "pause" : "play")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.currentSession == nil)

                Button(role: .destructive) {
                    showStopConfirmation = true
                } label: {
                    Label(LocalizedStringKey("measure.action.stop"), systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.currentSession == nil)
                .confirmationDialog(LocalizedStringKey("measure.dialog.stop.title"), isPresented: $showStopConfirmation, actions: {
                    Button(String(localized: "measure.dialog.stopAndSave"), role: .destructive) {
                        Task { await viewModel.stopRecording() }
                    }
                    Button(String(localized: "common.cancel"), role: .cancel) { }
                })
            }
        }
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("measure.pastSessions.title")
                .font(.headline)
                .accessibilityIdentifier("measure.pastSessions.title")
            VStack(spacing: 12) {
                ForEach(viewModel.recentSessions) { session in
                    NavigationLink {
                        SessionDetailView(mode: mode, session: session, settingsStore: settingsStore)
                    } label: {
                        SessionHistoryRow(session: session, mode: mode, settingsStore: settingsStore)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var measurementChart: some View {
        let chart = Chart {
            ForEach(samples) { sample in
                LineMark(
                    x: .value("measure.chart.axis.time", sample.timestamp),
                    y: .value(yAxisLabel, chartValue(for: sample))
                )
                .interpolationMethod(.catmullRom)
                if let selectedSample, selectedSample.id == sample.id {
                    RuleMark(x: .value("measure.chart.selected", selectedSample.timestamp))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3]))
                        .foregroundStyle(.secondary)
                    PointMark(
                        x: .value("measure.chart.axis.time", selectedSample.timestamp),
                        y: .value(yAxisLabel, chartValue(for: selectedSample))
                    )
                    .foregroundStyle(.primary)
                }
            }
        }
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
                    Text(selectedDetailTitle(for: selectedSample))
                        .font(.caption)
                        .padding(6)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.top, 8)
                        .padding(.leading, 8)
                    Spacer()
                }
            }
        }

        if let domain = chartDomain {
            chart.chartYScale(domain: domain)
        } else {
            chart
        }
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
        let sorted = samples.sorted(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
        selectedSample = sorted.first
    }

    private func primaryAction() {
        if viewModel.currentSession == nil {
            viewModel.startRecording()
        } else {
            viewModel.resumeRecording()
        }
    }

    private var primaryButtonTitleKey: LocalizedStringKey {
        if viewModel.currentSession == nil {
            return viewModel.isRecording ? LocalizedStringKey("measure.action.recording") : LocalizedStringKey("measure.action.start")
        }
        return viewModel.isRecording ? LocalizedStringKey("measure.action.recording") : LocalizedStringKey("measure.action.resume")
    }

    private var primaryButtonTint: Color {
        switch mode {
        case .altimeter:
            return viewModel.isRecording ? .green : .blue
        case .barometer:
            return viewModel.isRecording ? .green : .purple
        }
    }

    private var primaryButtonDisabled: Bool {
        viewModel.isRecording && viewModel.currentSession != nil
    }

    private var primaryMetricTitleKey: LocalizedStringKey {
        mode == .altimeter ? "measure.metric.currentAltitude" : "measure.metric.currentPressure"
    }

    private var primaryMetricValue: String {
        switch mode {
        case .altimeter:
            if let reading = viewModel.currentReading {
                return settingsStore.preferredUnit.formattedAltitude(meters: reading.absoluteAltitudeMeters)
            } else if let fallback = activeSession?.samples.last {
                return settingsStore.preferredUnit.formattedAltitude(meters: fallback.absoluteAltitudeMeters)
            }
        case .barometer:
            if let reading = viewModel.currentReading {
                return PressureFormatter.hectopascals(fromKilopascals: reading.pressureKPa)
            } else if let fallback = activeSession?.samples.last {
                return PressureFormatter.hectopascals(fromKilopascals: fallback.pressureKPa)
            }
        }
        return "—"
    }

    private var secondaryMetricValue: String {
        switch mode {
        case .altimeter:
            if let reading = viewModel.currentReading {
                return PressureFormatter.hectopascals(fromKilopascals: reading.pressureKPa)
            } else if let fallback = activeSession?.samples.last {
                return PressureFormatter.hectopascals(fromKilopascals: fallback.pressureKPa)
            }
        case .barometer:
            if let reading = viewModel.currentReading {
                return settingsStore.preferredUnit.formattedAltitude(meters: reading.absoluteAltitudeMeters)
            } else if let fallback = activeSession?.samples.last {
                return settingsStore.preferredUnit.formattedAltitude(meters: fallback.absoluteAltitudeMeters)
            }
        }
        return "—"
    }

    private var idleHintKey: LocalizedStringKey {
        mode == .altimeter ? "measure.hint.startAltimeter" : "measure.hint.startBarometer"
    }

    private var trendColor: Color {
        switch samples.recentTrend() {
        case .rising:
            return .green
        case .falling:
            return .orange
        case .steady:
            return .primary
        }
    }

    private var chartTitleKey: LocalizedStringKey {
        mode == .altimeter ? "measure.chart.title.elevation" : "measure.chart.title.pressure"
    }

    private var yAxisLabel: String {
        mode == .altimeter ? settingsStore.preferredUnit.shortAltitudeDescription : String(localized: "measure.chart.axis.pressure")
    }

    private var chartDomain: ClosedRange<Double>? {
        let values = samples.map { chartValue(for: $0) }
        guard let min = values.min(), let max = values.max(), min != max else { return nil }
        let padding = mode == .altimeter ? 5.0 : 0.5
        return (min - padding)...(max + padding)
    }

    private func chartValue(for sample: AltitudeSample) -> Double {
        switch mode {
        case .altimeter:
            return settingsStore.preferredUnit.convertedAltitude(from: sample.absoluteAltitudeMeters)
        case .barometer:
            return sample.pressureKPa * 10
        }
    }

    private func selectedDetailTitle(for sample: AltitudeSample) -> String {
        let time = sample.timestamp.formatted(date: .omitted, time: .standard)
        let value: String
        switch mode {
        case .altimeter:
            value = settingsStore.preferredUnit.formattedAltitude(meters: sample.absoluteAltitudeMeters)
        case .barometer:
            value = PressureFormatter.hectopascals(fromKilopascals: sample.pressureKPa)
        }
        let format = String(localized: "measure.chart.selected.detail.format", bundle: .main)
        return String(format: format, locale: .autoupdatingCurrent, time, value)
    }

    private var summaryMetrics: [SummaryMetric] {
        guard let session = activeSession else {
            return defaultSummaryMetrics
        }
        switch mode {
        case .altimeter:
            return [
                SummaryMetric(titleKey: "measure.metric.gain", value: settingsStore.preferredUnit.formattedGain(meters: session.totalAscentMeters)),
                SummaryMetric(titleKey: "measure.metric.loss", value: settingsStore.preferredUnit.formattedGain(meters: session.totalDescentMeters)),
                SummaryMetric(titleKey: "measure.metric.duration", value: session.duration.formattedHoursMinutesSeconds())
            ]
        case .barometer:
            let pressures = session.samples.map { $0.pressureKPa }
            let high = pressures.max().map { PressureFormatter.hectopascals(fromKilopascals: $0) } ?? "—"
            let low = pressures.min().map { PressureFormatter.hectopascals(fromKilopascals: $0) } ?? "—"
            return [
                SummaryMetric(titleKey: "measure.metric.high", value: high),
                SummaryMetric(titleKey: "measure.metric.low", value: low),
                SummaryMetric(titleKey: "measure.metric.duration", value: session.duration.formattedHoursMinutesSeconds())
            ]
        }
    }

    private var defaultSummaryMetrics: [SummaryMetric] {
        switch mode {
        case .altimeter:
            return [
                SummaryMetric(titleKey: "measure.metric.gain", value: "—"),
                SummaryMetric(titleKey: "measure.metric.loss", value: "—"),
                SummaryMetric(titleKey: "measure.metric.duration", value: "—")
            ]
        case .barometer:
            return [
                SummaryMetric(titleKey: "measure.metric.high", value: "—"),
                SummaryMetric(titleKey: "measure.metric.low", value: "—"),
                SummaryMetric(titleKey: "measure.metric.duration", value: "—")
            ]
        }
    }
}

private struct SummaryMetric: Identifiable {
    let id = UUID()
    let titleKey: LocalizedStringKey
    let value: String
}

private struct SessionHistoryRow: View {
    let session: AltitudeSession
    let mode: AltitudeSession.Mode
    let settingsStore: SettingsStore

    private var pressures: [Double] {
        session.samples.map { $0.pressureKPa }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.startDate, style: .date)
                    .font(.headline)
                Spacer()
                Text(session.startDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                switch mode {
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
    }
}

private struct ChartPlaceholder: View {
    let messageKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(messageKey)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    MeasureView(viewModel: .preview(mode: .altimeter), settingsStore: SettingsStore())
}
