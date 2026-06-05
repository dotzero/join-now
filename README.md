# JoinNow

JoinNow is a minimal native macOS SwiftUI menu bar app that shows a fullscreen reminder before upcoming calendar meetings.

## Features

- Reads Calendar events with EventKit.
- Runs as a menu bar app.
- Checks upcoming events every 30 seconds.
- Shows a fullscreen alert before a meeting starts.
- Extracts Zoom, Google Meet, and Microsoft Teams links from event title, notes, location, and URL.
- Stores settings and dismissed alerts in UserDefaults.

## Requirements

- macOS with Calendar access available.
- Xcode 26.5 or newer.
- No third-party dependencies.

## Run

1. Open `JoinNow.xcodeproj` in Xcode.
2. Select the `JoinNow` scheme.
3. Build and run.
4. Approve Calendar access when macOS prompts.

If the Calendar prompt does not appear, open System Settings and check Privacy & Security > Calendars. Sandboxed builds require the Calendar entitlement in `JoinNow/JoinNow.entitlements`; this project includes it.

## Settings

Open the menu bar item named `JoinNow`.

- Enable or disable reminders.
- Choose when alerts appear: 1, 3, 5, 10, or 15 minutes before the event.
- Optionally show alerts only for events with a meeting link.

## Build From Terminal

```sh
xcodebuild -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug build
```

When building from a restricted environment, pass an explicit DerivedData path:

```sh
xcodebuild -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug -derivedDataPath /private/tmp/joinnow-derived-data build
```

## Developer Tools

The project includes SwiftLint and SwiftFormat build phases. They run in lint/check mode during Xcode builds when the tools are installed. If they are missing, Xcode prints a warning and continues the build.

Install them with Homebrew:

```sh
brew install swiftlint swiftformat
```

Run checks manually:

```sh
swiftformat --lint .
swiftlint --strict --no-cache --config .swiftlint.yml
```

Swift compiler warnings are treated as errors in Debug and Release builds, and strict concurrency checking is enabled.
