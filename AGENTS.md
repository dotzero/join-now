# Repository Guidelines

## Project Structure & Module Organization

This repository contains a native macOS SwiftUI app named `JoinNow`.

- `JoinNow.xcodeproj/` contains the Xcode project.
- `JoinNow/JoinNowApp.swift` and `JoinNow/AppDelegate.swift` define app startup and lifecycle.
- `JoinNow/Models/` stores app state and UserDefaults-backed settings.
- `JoinNow/Services/` contains EventKit access, meeting link extraction, and reminder scheduling.
- `JoinNow/UI/` contains SwiftUI views and AppKit window/status bar controllers.
- `JoinNow/Info.plist` and `JoinNow/JoinNow.entitlements` define Calendar privacy and sandbox configuration.

Unit tests live under `JoinNowTests/`. Add assets under `JoinNow/Assets.xcassets/` when needed.

## Build, Test, and Development Commands

Build from the command line:

```sh
xcodebuild -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug build
```

In restricted environments, use an explicit DerivedData path:

```sh
xcodebuild -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug -derivedDataPath /private/tmp/joinnow-derived-data build
```

The preferred wrappers are:

```sh
make build
make test
make lint
make check
make package
```

Use `make package` to create a GitHub-release-ready macOS artifact in `dist/`: a draggable `JoinNow.app` and a versioned zip archive built from the Release configuration.

Run style checks manually after installing tools:

```sh
swiftformat --lint . --cache ignore
swiftlint --strict --no-cache --config .swiftlint.yml
```

Run tests after Swift code changes, in addition to linting:

```sh
xcodebuild test -project JoinNow.xcodeproj -scheme JoinNow -configuration Debug -derivedDataPath /private/tmp/joinnow-derived-data
```

Open `JoinNow.xcodeproj` in Xcode to run the app locally. macOS will request Calendar access on first launch.

## Coding Style & Naming Conventions

Use Swift 6, SwiftUI for views, and AppKit only where macOS integration requires it. Keep files small and aligned with the existing roles: `*Service` for platform/data logic, `*Controller` for AppKit coordination, and `*View` for SwiftUI.

Indent with 4 spaces. Prefer clear type names, explicit access control where useful, and `@MainActor` for UI/EventKit-facing objects. Avoid third-party runtime dependencies.

SwiftFormat and SwiftLint are wired into Xcode build phases. If the tools are installed, violations should fail the build. Run both lint commands after every Swift code change before handing work back.

## Testing Guidelines

For new logic-heavy code, add XCTest coverage in `JoinNowTests/` and name tests after behavior, for example `testExtractsGoogleMeetLinkFromNotes`.

Prioritize tests for `MeetingLinkExtractor`, `ReminderScheduler` filtering, and UserDefaults-backed settings. Manual validation should cover Calendar permission prompts, all-day/declined/ended event filtering, Dismiss behavior, and Join Meeting link opening.

## Commit & Pull Request Guidelines

This workspace currently has no Git history, so no repository-specific commit convention is established. Use short imperative commit messages, for example `Add SwiftLint build phase`.

Pull requests should include a concise summary, manual test notes, and screenshots for visible UI changes. Mention privacy, entitlement, or Calendar permission changes explicitly.

## Security & Configuration Tips

Calendar access requires both `NSCalendarsUsageDescription` in `Info.plist` and the Calendar entitlement in `JoinNow.entitlements`. Do not add network, automation, or broader sandbox entitlements unless the feature requires them.
