import Foundation

public struct CommandQuery: Equatable, Sendable {
    public let text: String
    public let createdAt: Date

    public init(text: String, createdAt: Date = Date()) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }

    public var isEmpty: Bool { text.isEmpty }
}

public struct CommandAction: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let role: Role

    public enum Role: String, Sendable {
        case primary
        case secondary
        case destructive
    }

    public init(id: String, title: String, role: Role) {
        self.id = id
        self.title = title
        self.role = role
    }

    public static let open = CommandAction(id: "open", title: "Open", role: .primary)
    public static let copy = CommandAction(id: "copy", title: "Copy", role: .primary)
    public static let reveal = CommandAction(id: "reveal", title: "Reveal in Finder", role: .secondary)
}

public struct CommandResult: Identifiable, Equatable, Sendable {
    public let id: String
    public let providerID: String
    public let title: String
    public let subtitle: String
    public let score: Double
    public let primaryAction: CommandAction
    public let secondaryActions: [CommandAction]
    public let payload: Payload

    public enum Payload: Equatable, Sendable {
        case text(String)
        case fileURL(URL)
        case clipboardItem(String)
        case appURL(URL)
        case none
    }

    public init(
        id: String,
        providerID: String,
        title: String,
        subtitle: String,
        score: Double,
        primaryAction: CommandAction,
        secondaryActions: [CommandAction] = [],
        payload: Payload = .none
    ) {
        self.id = id
        self.providerID = providerID
        self.title = title
        self.subtitle = subtitle
        self.score = score
        self.primaryAction = primaryAction
        self.secondaryActions = secondaryActions
        self.payload = payload
    }
}

public enum CommandExecutionResult: Equatable, Sendable {
    case success(message: String)
    case userCancelled
    case permissionDenied(String)
    case missingResource(String)
    case conflict(String)
    case validationFailed(String)
    case failed(String)

    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}
