# JoinNow

JoinNow is a free native macOS app that makes upcoming meetings hard to miss.

![](screenshot.png)

It reads your Calendar events, finds online meeting links, and shows a full-screen reminder before a meeting starts. The goal is simple: when it is time to join a call, JoinNow brings the meeting front and center and gives you a direct action to join.

## Features

- 📅 Reads upcoming events from Calendar
- 🔔 Shows full-screen meeting reminders
- 🚀 Lets you join the meeting directly from the alert

## Requirements

- macOS 26.0 or newer
- Calendar access permission

JoinNow has no third-party runtime dependencies.

## Build From Source

Clone the repository and build the release package:

```sh
git clone https://github.com/dotzero/join-now.git
cd join-now
make package
```

## Calendar Permissions

JoinNow needs Calendar access to read upcoming events. If the permission prompt does not appear, open:

`System Settings` -> `Privacy & Security` -> `Calendars`.

## License

[MIT](https://opensource.org/license/mit)
