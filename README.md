# Blink

Blink is a macOS-native Alfred-like launcher prototype.

## Current MVP

- Menu bar resident macOS app.
- Compact launcher window.
- Internal `CommandProvider` and `CommandEngine` architecture.
- Timestamp conversion command.
- Clipboard history storage with GRDB/SQLite and FTS search.
- Text clipboard copy-back.
- Clipboard capture path for text, images, and file URLs.
- File action service for open, reveal, copy, move, and rename validation.
- Settings JSON and local diagnostics log.
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
