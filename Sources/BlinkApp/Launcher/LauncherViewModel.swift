import BlinkCore
import Foundation

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [CommandResult] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var featureOptions = LauncherFeature.defaults
    @Published private(set) var selectedFeatureIndex = 0
    @Published private(set) var activeFeature: LauncherFeature?
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

    var isShowingFeatureOptions: Bool {
        activeFeature == nil && query.isEmpty
    }

    var searchPlaceholder: String {
        activeFeature?.placeholder ?? "Search commands, clipboard, files..."
    }

    var selectedFeature: LauncherFeature? {
        guard featureOptions.indices.contains(selectedFeatureIndex) else {
            return nil
        }
        return featureOptions[selectedFeatureIndex]
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
        if activeFeature == nil && currentQuery.isEmpty {
            results = []
            selectedIndex = 0
            selectedFeatureIndex = 0
            isShowingSecondaryActions = false
            selectedActionIndex = 0
            statusMessage = nil
            return
        }

        let providerID = activeFeature?.providerID
        searchTask = Task { [commandEngine] in
            let matches = await commandEngine.search(currentQuery)
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                self.apply(matches: self.filtered(matches, providerID: providerID), for: currentQuery)
            }
        }
    }

    func refreshForPresentation() async {
        searchTask?.cancel()
        activeFeature = nil
        query = ""
        results = []
        selectedIndex = 0
        selectedFeatureIndex = 0
        isShowingSecondaryActions = false
        selectedActionIndex = 0
        statusMessage = nil
    }

    func moveSelection(delta: Int) {
        if isShowingSecondaryActions {
            moveActionSelection(delta: delta)
            return
        }

        if isShowingFeatureOptions {
            selectedFeatureIndex = min(max(selectedFeatureIndex + delta, 0), featureOptions.count - 1)
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
        if isShowingFeatureOptions {
            Task {
                await activateSelectedFeature()
            }
            return
        }

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
        selectedFeatureIndex = 0
        activeFeature = nil
        isShowingSecondaryActions = false
        selectedActionIndex = 0
        statusMessage = nil
    }

    func activateSelectedFeature() async {
        guard let feature = selectedFeature else {
            return
        }
        await activate(feature)
    }

    func activateFeature(at index: Int) {
        guard featureOptions.indices.contains(index) else {
            return
        }
        selectedFeatureIndex = index
        Task {
            await activateSelectedFeature()
        }
    }

    func exitFeature() -> Bool {
        guard activeFeature != nil else {
            return false
        }
        activeFeature = nil
        query = ""
        results = []
        selectedIndex = 0
        selectedActionIndex = 0
        isShowingSecondaryActions = false
        statusMessage = nil
        return true
    }

    private func activate(_ feature: LauncherFeature) async {
        searchTask?.cancel()
        activeFeature = feature
        query = feature.defaultQuery
        selectedIndex = 0
        selectedActionIndex = 0
        isShowingSecondaryActions = false
        let currentQuery = CommandQuery(text: query)
        let matches = await commandEngine.search(currentQuery)
        apply(matches: filtered(matches, providerID: feature.providerID), for: currentQuery)
    }

    private func apply(matches: [CommandResult], for query: CommandQuery) {
        results = matches
        selectedIndex = 0
        isShowingSecondaryActions = false
        selectedActionIndex = 0
        statusMessage = matches.isEmpty && !query.isEmpty ? "No results" : nil
    }

    private func filtered(_ matches: [CommandResult], providerID: String?) -> [CommandResult] {
        guard let providerID else {
            return matches
        }
        return matches.filter { $0.providerID == providerID }
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
