# JoinNow

JoinNow is a free, native macOS menu bar app that makes upcoming meetings hard to miss.

It reads your Calendar events, finds online meeting links, and shows a fullscreen reminder before a meeting starts. The goal is simple: when it is time to join a call, JoinNow puts the meeting in your face and gives you a direct action to join.

## Features

- Runs as a macOS menu bar app.
- Reads upcoming events from Calendar via EventKit.
- Shows fullscreen meeting reminders.
- Supports configurable lead time: 1, 3, 5, 10, or 15 minutes.
- Extracts Google Meet, Zoom, and Microsoft Teams links from event fields.
- Can show alerts only for events that contain meeting links.
- Lets you join the meeting directly from the alert.
- Stores settings and dismissed alerts locally in UserDefaults.

## Requirements

- macOS
- Xcode 26.5 or newer
- Calendar access permission
- Optional: SwiftFormat and SwiftLint for local style checks

JoinNow has no third-party runtime dependencies.

## Build From Source

Clone the repository and open the project:

```sh
git clone <repository-url>
cd join-now
open JoinNow.xcodeproj
```

In Xcode:

1. Select the `JoinNow` scheme.
2. Select `My Mac` as the destination.
3. Build and run.
4. Approve Calendar access when macOS prompts.

You can also build from the terminal:

```sh
xcodebuild -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug build
```

In restricted environments, pass an explicit DerivedData path:

```sh
xcodebuild -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug -derivedDataPath /private/tmp/joinnow-derived-data build
```

## Calendar Permissions

JoinNow needs Calendar access to read upcoming events. If the permission prompt does not appear, open:

`System Settings` -> `Privacy & Security` -> `Calendars`

Sandboxed builds also require the Calendar entitlement. This project already includes it in:

```text
JoinNow/JoinNow.entitlements
```

## Developer Checks

The Xcode project includes SwiftFormat and SwiftLint build phases. They run in lint/check mode when the tools are installed.

Install them with Homebrew:

```sh
brew install swiftformat swiftlint
```

Run checks manually:

```sh
swiftformat --lint . --cache ignore
swiftlint --strict --no-cache --config .swiftlint.yml
```

## License

[MIT](https://opensource.org/license/mit)
