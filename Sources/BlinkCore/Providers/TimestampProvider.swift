import Foundation

public struct TimestampProvider: CommandProvider {
    public let id = "timestamp"
    public let displayName = "Timestamp"

    private let calendar: Calendar
    private let writer: any ClipboardWriting

    public init(calendar: Calendar = .current, writer: any ClipboardWriting = NoopClipboardWriter()) {
        self.calendar = calendar
        self.writer = writer
    }

    public func search(_ query: CommandQuery) async -> [CommandResult] {
        guard !query.isEmpty else {
            return []
        }

        if query.text.lowercased() == "now" {
            return [result(for: Date(), source: "Current time", score: 0.95)]
        }

        guard let number = Double(query.text) else {
            return []
        }

        return [
            result(for: Date(timeIntervalSince1970: number), source: "Unix seconds", score: 0.9),
            result(for: Date(timeIntervalSince1970: number / 1000.0), source: "Unix milliseconds", score: 0.75)
        ]
    }

    public func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        guard action.id == CommandAction.copy.id else {
            return .validationFailed("Unsupported timestamp action \(action.id)")
        }

        guard case let .text(value) = result.payload else {
            return .validationFailed("Timestamp result has no text payload")
        }

        let didWrite = await writer.writeText(value)
        return didWrite
            ? .success(message: "Copied \(value)")
            : .failed("System clipboard rejected timestamp")
    }

    private func result(for date: Date, source: String, score: Double) -> CommandResult {
        let value = formatted(date)
        return CommandResult(
            id: "timestamp-\(source)-\(date.timeIntervalSince1970)",
            providerID: id,
            title: value,
            subtitle: source,
            score: score,
            primaryAction: .copy,
            payload: .text(value)
        )
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let timeZoneLabel = calendar.timeZone.secondsFromGMT(for: date) == 0
            ? "UTC"
            : (calendar.timeZone.abbreviation(for: date) ?? calendar.timeZone.identifier)

        return "\(formatter.string(from: date)) \(timeZoneLabel)"
    }
}
