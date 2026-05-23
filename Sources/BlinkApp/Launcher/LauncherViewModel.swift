import BlinkCore
import Foundation

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [CommandResult] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var isShowingSecondaryActions = false
    @Published private(set) var selectedActionIndex = 0
    @Published private(set) var statusMessage: String?

    private let commandEngine: CommandEngine
    private var searchTask: Task<Void, Never>?

    init(commandEngine: CommandEngine) {
        self.commandEngine = commandEngine
    }

    func updateQuery(_ newValue: String) {
        guard query != newValue else {
            return
        }
        query = newValue
        queryDidChange()
    }

    var selectedResult: CommandResult? {
        guard results.indices.contains(selectedIndex) else {
            return nil
        }
        return results[selectedIndex]
    }

    var secondaryActions: [CommandAction] {
        selectedResult?.secondaryActions ?? []
    }

    var selectedSecondaryAction: CommandAction? {
        guard secondaryActions.indices.contains(selectedActionIndex) else {
            return nil
        }
        return secondaryActions[selectedActionIndex]
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
                self.isShowingSecondaryActions = false
                self.selectedActionIndex = 0
                self.statusMessage = matches.isEmpty && !currentQuery.isEmpty ? "No results" : nil
            }
        }
    }

    func moveSelection(delta: Int) {
        if isShowingSecondaryActions {
            moveActionSelection(delta: delta)
            return
        }

        guard !results.isEmpty else {
            selectedIndex = 0
            return
        }
        selectedIndex = min(max(selectedIndex + delta, 0), results.count - 1)
    }

    func showSecondaryActions() {
        guard !secondaryActions.isEmpty else {
            statusMessage = "No secondary actions"
            return
        }

        isShowingSecondaryActions = true
        selectedActionIndex = 0
        statusMessage = nil
    }

    func hideSecondaryActions() -> Bool {
        guard isShowingSecondaryActions else {
            return false
        }

        isShowingSecondaryActions = false
        selectedActionIndex = 0
        return true
    }

    func moveActionSelection(delta: Int) {
        guard !secondaryActions.isEmpty else {
            selectedActionIndex = 0
            return
        }
        selectedActionIndex = min(max(selectedActionIndex + delta, 0), secondaryActions.count - 1)
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

    func executeSelectedSecondaryAction() {
        guard let result = selectedResult, let action = selectedSecondaryAction else {
            return
        }

        Task { [commandEngine] in
            let execution = await commandEngine.execute(result, action: action)
            await MainActor.run {
                self.statusMessage = execution.message
                self.isShowingSecondaryActions = false
            }
        }
    }

    func clearTransientState() {
        query = ""
        results = []
        selectedIndex = 0
        isShowingSecondaryActions = false
        selectedActionIndex = 0
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
