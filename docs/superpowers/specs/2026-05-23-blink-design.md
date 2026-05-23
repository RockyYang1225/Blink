# Blink Design Spec

Date: 2026-05-23

## Summary

Blink is a macOS-native Alfred-like launcher for personal high-frequency use. The first version prioritizes fast global-hotkey invocation, keyboard-first command search, clipboard history, timestamp conversion, and safe file operations. It should feel native and quick before it becomes broadly extensible.

The first implementation uses Swift, SwiftUI, and AppKit. SwiftUI owns the compact launcher UI. AppKit owns menu bar lifecycle, floating window behavior, global hotkey integration, pasteboard access, and file-system interactions where needed.

## Goals

- Launch from a global hotkey into a compact input-and-results window.
- Search and execute built-in commands through one internal command protocol.
- Persist clipboard history locally for text, images, and file references.
- Provide timestamp conversion as an internal command provider.
- Provide safe file actions: open, reveal in Finder, single-file copy, move, and rename.
- Keep all data local by default.
- Leave a clear path to future external plugins without implementing that system in v1.

## Non-Goals

- External script/plugin loading.
- Plugin marketplace, manifest permissions, installation, or version management.
- Cloud sync.
- Rich preview panel.
- Destructive file deletion.
- Public release hardening such as signing, notarization, crash reporting, and auto-update.

## Product Scope

The v1 product is for the primary developer's personal use. This keeps configuration and diagnostics pragmatic: a menu bar app, a local config file or plist-backed settings, local logs, and direct local storage are acceptable. The design should not block later evolution toward a settings UI, signed releases, or external plugin workflows.

The launcher layout is compact Alfred-style: one input field and a ranked result list. The default path is:

1. Press global hotkey.
2. Type a query.
3. Navigate with arrow keys.
4. Press Enter to execute the selected result.
5. Use a secondary action shortcut for non-default actions.

## Architecture

Blink is a menu bar resident macOS app with the following core modules:

- `AppShell`: app lifecycle, menu bar item, global hotkey registration, permission status, diagnostics entry points, quit behavior.
- `LauncherWindow`: AppKit window controller for a fast floating panel, focus behavior, screen positioning, show/hide animation, and keyboard routing.
- `LauncherUI`: SwiftUI input field, result list, loading/empty/error states, keyboard selection state, action feedback.
- `CommandEngine`: query fan-out, provider orchestration, cancellation, result merging, ranking, and execution dispatch.
- `CommandProvider`: internal protocol implemented by built-in features.
- `ClipboardService`: pasteboard polling, content normalization, privacy filters, local persistence, cache cleanup.
- `FileActionService`: safe file actions and structured error reporting.
- `LocalStore`: GRDB-backed SQLite database plus file-system cache for larger clipboard objects.
- `SettingsStore`: retention limits, hotkey setting, clipboard recording state, exclusion rules, and cache quotas.
- `Diagnostics`: local log writing and menu bar access to log/config paths.

## Internal Command Protocol

All built-in capabilities implement the same internal provider protocol. This is the v1 extensibility boundary.

Conceptual shape:

```swift
protocol CommandProvider {
    var id: String { get }
    var displayName: String { get }

    func search(_ query: CommandQuery) async -> [CommandResult]
    func execute(_ result: CommandResult, action: CommandAction) async -> CommandExecutionResult
}
```

`CommandResult` should carry typed metadata rather than forcing each provider into plain strings:

- stable id
- provider id
- title
- subtitle
- icon hint
- score
- primary action
- secondary actions
- payload reference
- disabled or error state when applicable

`CommandExecutionResult` should report success, user-cancelled, permission denied, missing resource, conflict, validation failure, and unexpected failure.

## Built-In Providers

### App Provider

Search installed apps and launch the selected app. This provider can start simple and evolve later with indexing and aliases.

### Clipboard Provider

Search local clipboard history. Enter copies the selected entry back to the system clipboard. Secondary actions can include pin, delete from history, reveal cached file when applicable, and copy plain text when applicable.

### Timestamp Provider

Parse common timestamp/date inputs and return conversions. Examples:

- Unix seconds and milliseconds to local date/time.
- ISO-like date strings to Unix timestamp.
- "now" to current timestamp.

Enter copies the primary converted value.

### File Provider

Search recent or indexed files and provide safe actions. The v1 default actions are open and reveal in Finder. Copy, move, and rename are secondary explicit actions. Deletion is not in v1.

## Clipboard Capture

Clipboard history uses `NSPasteboard.general.changeCount` polling. When the change count changes, `ClipboardService` reads supported types, normalizes content, applies exclusion and retention rules, then stores metadata and optional cache files.

Supported v1 content types:

- Text.
- Images.
- File URLs.

Text is persisted as searchable content. Images are cached with strict size limits and metadata in SQLite. File URL entries store references and metadata; v1 should avoid copying large source files into Blink's cache unless a later feature explicitly requires that.

## Local Storage

Use GRDB.swift over direct SQLite access. GRDB gives v1 a small but durable foundation for migrations, transactions, typed records, FTS, and controlled concurrency.

Directory shape:

```text
Application Support/Blink/
  Blink.sqlite
  ClipboardCache/
    images/
    thumbnails/
  Logs/
```

Core table:

```sql
clipboard_items
- id
- content_type
- preview_text
- searchable_text
- content_hash
- source_app_bundle_id
- source_app_name
- created_at
- last_used_at
- pinned
- size_bytes
- cache_path
- original_file_url
- expires_at
- deleted_at
```

Add a clipboard FTS table for text search:

```sql
clipboard_items_fts
- preview_text
- searchable_text
```

SQLite stores metadata, indexes, and searchable text. The file system stores larger objects such as cached images and thumbnails. Cleanup must remove both database rows and cache files.

## Privacy and Retention

Clipboard history is persisted locally by default. The app must provide:

- Pause recording.
- Clear history.
- Source exclusion rules.
- Content type exclusion rules.
- Maximum item count.
- Maximum retention days.
- Maximum cache size.
- Local-only operation.

Sensitive source exclusion should be based on best available source hints, such as frontmost app bundle id at capture time. This is imperfect, so the UI and docs should be honest that exclusions are best effort.

## File Operation Safety

Low-risk actions may be default actions:

- Open file.
- Reveal in Finder.

Higher-risk actions must be explicit secondary actions:

- Copy file.
- Move file.
- Rename file.

Deletion is deferred. If it is added later, it should only move to Trash and require confirmation.

File operations return structured failures:

- permission denied
- file missing
- target exists
- invalid filename
- user cancelled
- operation failed

## Launcher Interaction

Keyboard-first behavior:

- Global hotkey toggles the launcher.
- Typing queries all enabled providers.
- Up and Down move the selected result.
- Enter executes the selected result's primary action.
- Tab or Command-Enter opens secondary actions.
- Escape hides the launcher.
- Empty query can show recent/pinned commands and clipboard entries.

UI states:

- loading
- empty results
- provider error
- execution in progress
- execution failed
- clipboard recording paused
- permission needed

The UI should avoid modal alerts during normal command execution. Inline status and concise result-row feedback are preferred. Detailed diagnostics go to local logs.

## Error Handling and Diagnostics

Errors should be visible without being noisy. The result list can show short failure text. The menu bar should expose:

- Pause or resume clipboard recording.
- Clear clipboard history.
- Open config.
- Open logs.
- Quit.

Local logs should capture provider failures, database migration failures, cache cleanup failures, hotkey registration failures, and file operation failures.

## Testing and Verification

Unit tests:

- command result ranking and merge behavior
- provider cancellation behavior
- timestamp parsing and formatting
- clipboard duplicate detection
- retention policy calculation
- file action validation

Database tests:

- GRDB migrations
- clipboard insert/query/update/delete
- FTS search behavior
- cache cleanup consistency

Integration or manual verification:

- global hotkey opens and hides launcher
- launcher receives focus reliably
- text clipboard entries persist and search
- image clipboard entries persist within cache limits
- file URL clipboard entries can be copied back or revealed when valid
- file actions report permission and conflict failures
- clear history removes database rows and cache files

## Implementation Sequence

1. Scaffold macOS Swift app and menu bar lifecycle.
2. Add floating launcher window with compact SwiftUI UI.
3. Define command protocol, result model, action model, and execution result model.
4. Implement `CommandEngine` with provider fan-out, cancellation, merge, ranking, and execution.
5. Add a simple app provider or stub provider to validate launcher flow.
6. Add GRDB local store and migrations.
7. Implement clipboard capture for text, then images and file URLs.
8. Implement clipboard provider search and copy-back execution.
9. Implement timestamp provider.
10. Implement safe file actions.
11. Add settings for hotkey, retention, pause, clear, and exclusions.
12. Add diagnostics and local logs.
13. Verify the full user journey on macOS.

## V1 Default Decisions

- Default global hotkey: Option-Space. This avoids Spotlight's usual Command-Space default while staying easy to press.
- File search: start with Spotlight metadata for common user locations, with a fallback to recent files and explicit file URL clipboard entries. Full custom indexing is deferred.
- Image clipboard cache: store thumbnails by default and store originals only under the configured cache size limit.
- Secondary action shortcut: Command-Enter. Tab remains available for focus movement if the launcher UI later needs it.
