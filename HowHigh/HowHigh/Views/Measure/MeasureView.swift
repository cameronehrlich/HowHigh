import SwiftUI
import Charts
import UIKit

struct MeasureView: View {
    @ObservedObject var viewModel: MeasureViewModel
    @ObservedObject var settingsStore: SettingsStore
    @State private var showStopConfirmation: Bool = false
    @State private var selectedSample: AltitudeSample?
    @State private var showConfidenceHelp: Bool = false
    @State private var shareURL: URL?
    @State private var shareErrorMessage: String?

    private var mode: AltitudeSession.Mode { viewModel.mode }
    private var displayMode: AltitudeDisplayMode { settingsStore.altitudeDisplayMode }

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
                    if settingsStore.showChart {
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
                    } else {
                        readingCard
                    }
                    if mode == .altimeter {
                        modeControls
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
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
            .sheet(isPresented: $showConfidenceHelp) {
                SensorConfidenceHelpView(mode: mode)
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
                    if mode == .altimeter {
                        zeroButtonInline
                    }
                    if mode == .altimeter {
                        altimeterSecondaryMetrics
                    } else {
                        Text(secondaryMetricValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: trend.systemImageName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(trendColor)
                    Text(LocalizedStringKey(trendDescriptionKey))
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
            confidenceRow
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.regularMaterial))
    }

    private var confidenceRow: some View {
        Button {
            showConfidenceHelp = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.confidence.systemImageName)
                    .foregroundStyle(confidenceColor)
                Text(LocalizedStringKey(viewModel.confidence.labelLocalizationKey))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("measure.confidence.row")
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

    private var modeControls: some View {
        modePicker
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.regularMaterial))
    }

    private var modePicker: some View {
        Picker("measure.mode.label", selection: $settingsStore.altitudeDisplayMode) {
            ForEach(AltitudeDisplayMode.allCases) { option in
                Text(option.displayNameKey).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("measure.mode.picker")
    }

    private var zeroButtonInline: some View {
        Button(action: viewModel.calibrateToCurrentReading) {
            if viewModel.isCalibrating {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("measure.action.calibrating")
                }
            } else {
                Label("measure.action.zero", systemImage: "scope")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.teal)
        .controlSize(.small)
        .disabled(!viewModel.canCalibrate || viewModel.isCalibrating)
    }

    private var sessionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("measure.sessionSummary.title")
                .font(.headline)
                .accessibilityIdentifier("measure.sessionSummary.title")
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(summaryMetrics) { metric in
                    summaryMetricTile(metric)
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

    private var altimeterSecondaryMetrics: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    InlineMetric(titleKey: "measure.amsl.title", value: amslValue)
                    InlineMetric(titleKey: "measure.metric.currentPressure", value: pressureValue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    InlineMetric(titleKey: "measure.amsl.title", value: amslValue)
                    InlineMetric(titleKey: "measure.metric.currentPressure", value: pressureValue)
                }
            }
            Label("measure.amsl.helper", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("measure.pastSessions.title")
                .font(.headline)
                .accessibilityIdentifier("measure.pastSessions.title")
            List {
                ForEach(viewModel.recentSessions) { session in
                    NavigationLink {
                        SessionDetailView(
                            mode: mode,
                            session: session,
                            settingsStore: settingsStore,
                            onDelete: { await viewModel.delete(session: session) }
                        )
                    } label: {
                        SessionHistoryRow(session: session, mode: mode, settingsStore: settingsStore)
                            .padding(.vertical, 6)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(session: session) }
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
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .frame(height: recentSessionsListHeight)
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

    @ViewBuilder
    private var measurementChart: some View {
        let chart = Chart {
            ForEach(samples) { sample in
                AreaMark(
                    x: .value("measure.chart.axis.time", sample.timestamp),
                    y: .value(yAxisLabel, chartValue(for: sample))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(chartFillGradient)

                LineMark(
                    x: .value("measure.chart.axis.time", sample.timestamp),
                    y: .value(yAxisLabel, chartValue(for: sample))
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(chartLineColor)
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
                let plotFrame = geometry[proxy.plotAreaFrame]
                // Restrict hit-testing to the plot area only so the surrounding card and scroll view behave normally.
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .frame(width: plotFrame.size.width, height: plotFrame.size.height)
                    .position(x: plotFrame.midX, y: plotFrame.midY)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.25)
                            .sequenced(before: DragGesture(minimumDistance: 0))
                            .onChanged { value in
                                switch value {
                                case .second(true, let drag?):
                                    updateSelection(locationX: drag.location.x, proxy: proxy, plotWidth: plotFrame.size.width)
                                default:
                                    break
                                }
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
            chart.chartYScale(domain: domain).clipped()
        } else {
            chart.clipped()
        }
    }

    private func updateSelection(locationX: CGFloat, proxy: ChartProxy, plotWidth: CGFloat) {
        guard locationX >= 0, locationX <= plotWidth else {
            selectedSample = nil
            return
        }
        guard let date: Date = proxy.value(atX: locationX) else {
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
        mode == .altimeter ? displayMode.metricTitleKey : "measure.metric.currentPressure"
    }

    private var primaryMetricValue: String {
        switch mode {
        case .altimeter:
            switch displayMode {
            case .gain:
                if let gain = viewModel.gainAltitudeMeters {
                    return settingsStore.preferredUnit.formattedGain(meters: gain)
                }
            case .net:
                if let net = viewModel.netAltitudeDeltaMeters {
                    return settingsStore.preferredUnit.formattedAltitude(meters: net)
                }
            }
        case .barometer:
            if let reading = viewModel.currentReading {
                return PressureFormatter.formatted(kPa: reading.pressureKPa, unit: settingsStore.pressureUnit)
            } else if let fallback = activeSession?.samples.last {
                return PressureFormatter.formatted(kPa: fallback.pressureKPa, unit: settingsStore.pressureUnit)
            }
        }
        return "—"
    }

    private var secondaryMetricValue: String {
        switch mode {
        case .altimeter:
            return "—"
        case .barometer:
            if let meters = viewModel.amslAltitudeMeters {
                return settingsStore.preferredUnit.formattedAltitude(meters: meters)
            }
        }
        return "—"
    }

    private var pressureValue: String {
        if let reading = viewModel.currentReading {
            return PressureFormatter.formatted(kPa: reading.pressureKPa, unit: settingsStore.pressureUnit)
        } else if let fallback = activeSession?.samples.last {
            return PressureFormatter.formatted(kPa: fallback.pressureKPa, unit: settingsStore.pressureUnit)
        }
        return "—"
    }

    private var amslValue: String {
        if let meters = viewModel.amslAltitudeMeters {
            return settingsStore.preferredUnit.formattedAltitude(meters: meters)
        }
        return "—"
    }

    private var idleHintKey: LocalizedStringKey {
        mode == .altimeter ? "measure.hint.startAltimeter" : "measure.hint.startBarometer"
    }

    private var trendColor: Color {
        switch trend {
        case .rising:
            return .green
        case .falling:
            return .orange
        case .steady:
            return .primary
        }
    }

    private var trend: AltitudeTrend {
        switch mode {
        case .barometer:
            return samples.recentTrend()
        case .altimeter:
            return samples.recentAltitudeTrend()
        }
    }

    private var trendDescriptionKey: String {
        switch mode {
        case .barometer:
            return trend.pressureDescriptionKey
        case .altimeter:
            return trend.altitudeDescriptionKey
        }
    }

    private var chartTitleKey: LocalizedStringKey {
        mode == .altimeter ? "measure.chart.title.elevation" : "measure.chart.title.pressure"
    }

    private var chartLineColor: Color {
        switch mode {
        case .altimeter:
            return .blue
        case .barometer:
            return .purple
        }
    }

    private var chartFillGradient: LinearGradient {
        let base = chartLineColor
        return LinearGradient(
            colors: [base.opacity(0.22), base.opacity(0.02)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var confidenceColor: Color {
        switch viewModel.confidence {
        case .unavailable:
            return .red
        case .calibrating, .warmingUp:
            return .orange
        case .good:
            return .green
        case .poor:
            return .orange
        }
    }

    private var yAxisLabel: String {
        mode == .altimeter ? settingsStore.preferredUnit.shortAltitudeDescription : String(localized: "measure.chart.axis.pressure")
    }

    private var chartDomain: ClosedRange<Double>? {
        let values = samples.map { chartValue(for: $0) }
        guard let minValue = values.min(), let maxValue = values.max(), minValue != maxValue else { return nil }
        let padding: Double
        switch mode {
        case .altimeter:
            let range = maxValue - minValue
            // Small movements early in a session should be visible; avoid a big fixed padding.
            padding = Swift.min(Swift.max(range * 0.25, 0.25), 5.0)
        case .barometer:
            padding = settingsStore.pressureUnit == .hectopascals ? 0.5 : 0.05
        }
        return (minValue - padding)...(maxValue + padding)
    }

    private func chartValue(for sample: AltitudeSample) -> Double {
        switch mode {
        case .altimeter:
            // Relative makes small movements visible while recording.
            return settingsStore.preferredUnit.convertedAltitude(from: sample.relativeAltitudeMeters)
        case .barometer:
            return settingsStore.pressureUnit.value(fromKPa: sample.pressureKPa)
        }
    }

    private var recentSessionsListHeight: CGFloat {
        // A non-scrolling List embedded in ScrollView needs an explicit height.
        // Keep this generous to avoid clipping under Dynamic Type and iOS list row chrome.
        let rowHeight: CGFloat = 86
        let maxRows = min(viewModel.recentSessions.count, 6)
        let chrome: CGFloat = 24
        return CGFloat(maxRows) * rowHeight + chrome
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

    private func selectedDetailTitle(for sample: AltitudeSample) -> String {
        let time = sample.timestamp.formatted(date: .omitted, time: .standard)
        let value: String
        switch mode {
        case .altimeter:
            value = settingsStore.preferredUnit.formattedAltitude(meters: sample.relativeAltitudeMeters)
        case .barometer:
            value = PressureFormatter.formatted(kPa: sample.pressureKPa, unit: settingsStore.pressureUnit)
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
                SummaryMetric(titleKey: "measure.metric.net", value: settingsStore.preferredUnit.formattedAltitude(meters: session.netAltitudeChangeMeters)),
                SummaryMetric(titleKey: "measure.metric.loss", value: settingsStore.preferredUnit.formattedGain(meters: session.totalDescentMeters)),
                SummaryMetric(titleKey: "measure.metric.duration", value: session.duration.formattedHoursMinutesSeconds())
            ]
        case .barometer:
            let pressures = session.samples.map { $0.pressureKPa }
            let high = pressures.max().map { PressureFormatter.formatted(kPa: $0, unit: settingsStore.pressureUnit) } ?? "—"
            let low = pressures.min().map { PressureFormatter.formatted(kPa: $0, unit: settingsStore.pressureUnit) } ?? "—"
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
                SummaryMetric(titleKey: "measure.metric.net", value: "—"),
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

private struct InlineMetric: View {
    let titleKey: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleKey)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
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

private struct SensorConfidenceHelpView: View {
    let mode: AltitudeSession.Mode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("measure.confidence.help.title")
                        .font(.title2.weight(.bold))

                    Text(LocalizedStringKey(mode == .altimeter ? "measure.confidence.help.body.altimeter" : "measure.confidence.help.body.barometer"))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("measure.confidence.help.tip.1", systemImage: "scope")
                        Label("measure.confidence.help.tip.2", systemImage: "hand.raised")
                        Label("measure.confidence.help.tip.3", systemImage: "location")
                    }
                    .font(.body)

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle("measure.confidence.help.navTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    MeasureView(viewModel: .preview(mode: .altimeter), settingsStore: SettingsStore())
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
