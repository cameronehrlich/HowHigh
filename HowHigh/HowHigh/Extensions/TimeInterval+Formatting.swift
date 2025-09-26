import Foundation

extension TimeInterval {
    private static let shortFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.dropTrailing]
        return formatter
    }()

    private static let detailedFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.dropTrailing]
        return formatter
    }()

    func formattedHoursMinutes() -> String {
        Self.shortFormatter.string(from: self) ?? formattedHoursMinutesSeconds()
    }

    func formattedHoursMinutesSeconds() -> String {
        Self.detailedFormatter.string(from: self) ?? "—"
    }
}
