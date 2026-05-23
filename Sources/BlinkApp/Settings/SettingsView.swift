import BlinkCore
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @State private var settings = BlinkSettings.defaults
    @State private var maxCacheMegabytes = Int(BlinkSettings.defaults.maxCacheBytes / 1_000_000)
    @State private var excludedBundleIDsText = ""
    @State private var excludedContentTypesText = ""
    @State private var statusMessage = ""
    @State private var settingsURL: URL?

    var body: some View {
        Form {
            Section("Launcher") {
                KeyboardShortcuts.Recorder("Global Hotkey", name: .toggleLauncher) { shortcut in
                    settings.hotkeyName = shortcut?.description ?? "Unassigned"
                    save()
                }
            }

            Section("Clipboard") {
                Toggle("Record Clipboard History", isOn: $settings.clipboardRecordingEnabled)
                    .onChange(of: settings.clipboardRecordingEnabled) { _, _ in save() }

                Stepper(value: $settings.maxItemCount, in: 50...5000, step: 50) {
                    LabeledContent("Maximum Items", value: "\(settings.maxItemCount)")
                }
                .onChange(of: settings.maxItemCount) { _, _ in save() }

                Stepper(value: $settings.maxRetentionDays, in: 1...365, step: 1) {
                    LabeledContent("Retention Days", value: "\(settings.maxRetentionDays)")
                }
                .onChange(of: settings.maxRetentionDays) { _, _ in save() }

                Stepper(value: $maxCacheMegabytes, in: 10...2048, step: 10) {
                    LabeledContent("Cache Limit", value: "\(maxCacheMegabytes) MB")
                }
                .onChange(of: maxCacheMegabytes) { _, newValue in
                    settings.maxCacheBytes = Int64(newValue) * 1_000_000
                    save()
                }
            }

            Section("Exclusions") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bundle IDs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $excludedBundleIDsText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 64)
                        .onChange(of: excludedBundleIDsText) { _, newValue in
                            settings.excludedBundleIDs = lines(from: newValue)
                            save()
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Content Types")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $excludedContentTypesText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 64)
                        .onChange(of: excludedContentTypesText) { _, newValue in
                            settings.excludedContentTypes = lines(from: newValue)
                            save()
                        }
                }
            }

            Section {
                HStack {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let settingsURL {
                        Button("Reveal Config") {
                            NSWorkspace.shared.activateFileViewerSelecting([settingsURL])
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520)
        .onAppear(perform: load)
    }

    private func load() {
        do {
            let paths = try AppPaths.live()
            let store = SettingsStore(url: paths.settingsURL)
            settings = try store.load()
            settingsURL = paths.settingsURL
            maxCacheMegabytes = max(1, Int(settings.maxCacheBytes / 1_000_000))
            excludedBundleIDsText = settings.excludedBundleIDs.joined(separator: "\n")
            excludedContentTypesText = settings.excludedContentTypes.joined(separator: "\n")
            statusMessage = "Saved"
        } catch {
            statusMessage = "Failed to load settings: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            let paths = try AppPaths.live()
            let store = SettingsStore(url: paths.settingsURL)
            settingsURL = paths.settingsURL
            try store.save(settings)
            statusMessage = "Saved"
        } catch {
            statusMessage = "Failed to save settings: \(error.localizedDescription)"
        }
    }

    private func lines(from text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
