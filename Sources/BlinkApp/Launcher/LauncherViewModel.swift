import BlinkCore
import Foundation

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [CommandResult] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var statusMessage: String?

    private let commandEngine: CommandEngine
    private var searchTask: Task<Void, Never>?

    init(commandEngine: CommandEngine) {
        self.commandEngine = commandEngine
    }

    var selectedResult: CommandResult? {
        guard results.indices.contains(selectedIndex) else {
            return nil
        }
        return results[selectedIndex]
    }

    func queryDidChange() {
        searchTask?.cancel()
        let currentQuery = CommandQuery(text: query)
        searchTask = Task { [commandEngine] in
            let matches = await commandEngine.search(currentQuery)
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                self.results = matches
                self.selectedIndex = 0
                self.statusMessage = matches.isEmpty && !currentQuery.isEmpty ? "No results" : nil
            }
        }
    }

    func moveSelection(delta: Int) {
        guard !results.isEmpty else {
            selectedIndex = 0
            return
        }
        selectedIndex = min(max(selectedIndex + delta, 0), results.count - 1)
    }

    func executeSelected() {
        guard let result = selectedResult else {
            return
        }

        Task { [commandEngine] in
            let execution = await commandEngine.execute(result, action: result.primaryAction)
            await MainActor.run {
                self.statusMessage = execution.message
            }
        }
    }

    func clearTransientState() {
        query = ""
        results = []
        selectedIndex = 0
        statusMessage = nil
    }
}

private extension CommandExecutionResult {
    var message: String {
        switch self {
        case let .success(message):
            return message
        case .userCancelled:
            return "Cancelled"
        case let .permissionDenied(message),
             let .missingResource(message),
             let .conflict(message),
             let .validationFailed(message),
             let .failed(message):
            return message
        }
    }
}
