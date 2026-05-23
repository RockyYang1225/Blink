import Foundation

public actor CommandEngine {
    private let providersByID: [String: any CommandProvider]

    public init(providers: [any CommandProvider]) {
        self.providersByID = Dictionary(uniqueKeysWithValues: providers.map { ($0.id, $0) })
    }

    public func search(_ query: CommandQuery) async -> [CommandResult] {
        await withTaskGroup(of: [CommandResult].self) { group in
            for provider in providersByID.values {
                group.addTask {
                    await provider.search(query)
                }
            }

            var merged: [CommandResult] = []
            for await results in group {
                merged.append(contentsOf: results)
            }

            return merged.sorted {
                if $0.score == $1.score {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.score > $1.score
            }
        }
    }

    public func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult {
        guard let provider = providersByID[result.providerID] else {
            return .missingResource("Provider \(result.providerID) is not registered")
        }

        return await provider.execute(result, action: action)
    }
}
