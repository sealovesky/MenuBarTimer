# MenuBarTimer

A lightweight Pomodoro timer for the macOS menu bar. Built with SwiftUI.

macOS 菜单栏番茄钟，使用 SwiftUI 构建。

## Features

- **Pomodoro Timer** — Focus (25 min), Short Break (5 min), Long Break (15 min)
- **Menu Bar Integration** — Lives in the menu bar, shows countdown when running
- **Custom Durations** — Adjust focus and break lengths to your preference
- **Auto Mode Switch** — Automatically transitions between focus and break
- **Auto Start Next** — Optionally start the next session automatically
- **Configurable Long Break** — Set how many pomodoros before a long break
- **Statistics** — Track daily pomodoro count with a 7-day bar chart
- **Notifications** — System notifications when sessions complete
- **Launch at Login** — Start automatically when you log in
- **Localization** — English and Chinese (简体中文)

## Requirements

- macOS 13.0+
- Xcode 14.0+

## Build

```bash
git clone https://github.com/sealovesky/MenuBarTimer.git
cd MenuBarTimer
open MenuBarTimer.xcodeproj
```

Build and run with `Cmd + R` in Xcode.

Or build from command line:

```bash
xcodebuild -scheme MenuBarTimer -configuration Release build
```

## License

[MIT](LICENSE)
