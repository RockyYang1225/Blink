import Foundation

struct LauncherFeature: Equatable, Identifiable, Sendable {
    enum Kind: String, Sendable {
        case clipboardHistory
        case timestampConverter
        case fileSearch
        case applications
    }

    let kind: Kind
    let title: String
    let subtitle: String
    let providerID: String
    let placeholder: String
    let defaultQuery: String
    let symbolName: String

    var id: String { kind.rawValue }

    static let defaults: [LauncherFeature] = [
        LauncherFeature(
            kind: .clipboardHistory,
            title: "Clipboard History",
            subtitle: "Browse recent copied text",
            providerID: "clipboard",
            placeholder: "Search clipboard history...",
            defaultQuery: "",
            symbolName: "doc.on.clipboard"
        ),
        LauncherFeature(
            kind: .timestampConverter,
            title: "Timestamp Converter",
            subtitle: "Convert now, Unix seconds, or milliseconds",
            providerID: "timestamp",
            placeholder: "Type now or a Unix timestamp...",
            defaultQuery: "now",
            symbolName: "clock"
        ),
        LauncherFeature(
            kind: .fileSearch,
            title: "File Search",
            subtitle: "Find files from Desktop, Documents, Downloads",
            providerID: "file",
            placeholder: "Search files...",
            defaultQuery: "",
            symbolName: "folder"
        ),
        LauncherFeature(
            kind: .applications,
            title: "Applications",
            subtitle: "Launch installed apps",
            providerID: "app",
            placeholder: "Search applications...",
            defaultQuery: "",
            symbolName: "app.dashed"
        )
    ]
}
