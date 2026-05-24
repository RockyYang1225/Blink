# Blink

Blink is a macOS-native Alfred-like launcher prototype.

## Current MVP

- Menu bar resident macOS app.
- Compact launcher window.
- Internal `CommandProvider` and `CommandEngine` architecture.
- Timestamp conversion command.
- Clipboard history storage with GRDB/SQLite and FTS search.
- Launcher home screen with feature options for clipboard history, timestamp conversion, file search, and applications.
- Text clipboard copy-back.
- Clipboard capture path for text, images, and file URLs.
- File action service for open, reveal, copy, move, and rename validation.
- Settings JSON and local diagnostics log.
- Settings window for hotkey recording, clipboard retention, cache limit, and exclusions.
- Debug `.app` packaging script.

## Build And Test

```bash
rtk swift test
rtk swift build
```

## Package A Debug App

```bash
rtk ./scripts/package-app.sh debug
```

The generated app is:

```text
.build/Blink.app
```

## Run For Manual Testing

```bash
rtk proxy open .build/Blink.app --args --show-launcher
```

Useful cleanup while iterating:

```bash
rtk proxy pkill -f '/Blink.app/Contents/MacOS/Blink'
```

## Foreground Checklist

Use this checklist from the actual macOS desktop session:

1. Launch `.build/Blink.app`.
2. Press `Option-Space`; the Blink launcher should appear.
3. Type `now`; timestamp results should show.
4. Press `Return`; the selected timestamp should be copied to the clipboard.
5. Press `Option-Space` again or `Esc`; the launcher should hide.
6. Copy a text snippet, reopen Blink, choose `Clipboard History`, and confirm recent clipboard history appears.
7. Type part of that snippet to filter history, then press `Return` to copy the selected entry back.
8. Use the menu bar item to pause/resume clipboard recording.
9. Use the menu bar item to clear history, then confirm clipboard search no longer returns old entries.
10. Search for a known file from Desktop, Documents, or Downloads; test open/reveal actions.
11. Open the Settings window and confirm hotkey/clipboard changes are saved.

## Local Data

Blink writes local development data to:

```text
~/Library/Application Support/Blink/
  Blink.sqlite
  ClipboardCache/
  Logs/blink.log
  settings.json
```

## Current Verification Limits

Automated tests cover the command engine, timestamp provider, clipboard repository/provider, retention policy, settings, diagnostics, file actions, and file search. Manual verification has confirmed launcher window creation and timestamp copy once, but global hotkey behavior and Finder/menu interactions still need foreground validation on the target Mac session.
