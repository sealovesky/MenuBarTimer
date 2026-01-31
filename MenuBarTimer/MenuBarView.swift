import SwiftUI

enum ViewPage: Equatable {
    case timer, settings, history
}

struct MenuBarView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var currentPage: ViewPage = .timer

    var body: some View {
        VStack(spacing: 16) {
            switch currentPage {
            case .timer:
                timerView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .settings:
                settingsView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .history:
                historyView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentPage)
        .padding(20)
        .frame(width: 280)
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Button(action: { timerManager.switchMode(mode) }) {
                        Text(mode.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                timerManager.currentMode == mode
                                    ? mode.color
                                    : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.currentMode.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerManager.progress)

                VStack(spacing: 2) {
                    Text(timerManager.timeString)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(timerManager.currentMode.color)

                    Text(timerManager.currentMode.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 20) {
                Button(action: { timerManager.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                Button(action: {
                    timerManager.isRunning ? timerManager.pause() : timerManager.start()
                }) {
                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(timerManager.currentMode.color)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: { timerManager.skipToNext() }) {
                    Image(systemName: "forward")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text(String(format: NSLocalizedString("stats.todayCount", comment: ""), timerManager.completedPomodoros))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Button(action: { currentPage = .history }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chart.bar")
                        Text("button.stats")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { currentPage = .settings }) {
                    HStack(spacing: 3) {
                        Image(systemName: "gearshape")
                        Text("button.settings")
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle")
                        Text("button.quit")
                    }
                    .font(.caption)
                }
                .keyboardShortcut("q")
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Settings View

    private var settingsView: some View {
        VStack(spacing: 12) {
            ZStack {
                Text("settings.title")
                    .font(.headline)
                HStack {
                    Button(action: { currentPage = .timer }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Text("button.back")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("settings.duration")
                    .font(.caption)
                    .foregroundColor(.secondary)

                durationRow(label: String(localized: "settings.focus"), value: $timerManager.focusMinutes, color: .orange, mode: .focus)
                durationRow(label: String(localized: "settings.shortBreak"), value: $timerManager.shortBreakMinutes, color: .teal, mode: .shortBreak)
                durationRow(label: String(localized: "settings.longBreak"), value: $timerManager.longBreakMinutes, color: .indigo, mode: .longBreak)
            }

            Divider()

            HStack {
                Text("settings.longBreakInterval")
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    if timerManager.longBreakInterval > 2 {
                        timerManager.longBreakInterval -= 1
                    }
                }) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)

                Text("\(timerManager.longBreakInterval)")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 20, alignment: .center)

                Button(action: {
                    if timerManager.longBreakInterval < 10 {
                        timerManager.longBreakInterval += 1
                    }
                }) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)

                Text("settings.longBreakUnit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 8) {
                toggleRow(label: String(localized: "settings.autoStartNext"), isOn: Binding(
                    get: { timerManager.autoStartNext },
                    set: { timerManager.setAutoStartNext($0) }
                ))
                toggleRow(label: String(localized: "settings.launchAtLogin"), isOn: Binding(
                    get: { timerManager.launchAtLogin },
                    set: { timerManager.setLaunchAtLogin($0) }
                ))
            }
        }
    }

    // MARK: - History View

    private var historyView: some View {
        let history = timerManager.recentHistory(days: 7)
        let maxCount = max(history.map(\.count).max() ?? 1, 1)

        return VStack(spacing: 12) {
            ZStack {
                Text("stats.title")
                    .font(.headline)
                HStack {
                    Button(action: { currentPage = .timer }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Text("button.back")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }

            Divider()

            HStack(spacing: 20) {
                statCard(title: String(localized: "stats.today"), value: timerManager.completedPomodoros)
                statCard(title: String(localized: "stats.thisWeek"), value: timerManager.totalPomodoros(days: 7))
            }

            Divider()

            Text("stats.last7Days")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(history, id: \.date) { item in
                    VStack(spacing: 4) {
                        Text("\(item.count)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.date == Self.todayString() ? Color.orange : Color.orange.opacity(0.5))
                            .frame(height: max(CGFloat(item.count) / CGFloat(maxCount) * 60, 4))

                        Text(Self.shortDate(item.date))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
    }

    // MARK: - Components

    private func statCard(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func shortDate(_ dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return dateString }
        return "\(month)/\(day)"
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private func durationRow(label: String, value: Binding<Int>, color: Color, mode: TimerMode) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            Button(action: {
                if value.wrappedValue > 1 {
                    value.wrappedValue -= 1
                    timerManager.applyDuration(for: mode)
                }
            }) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)

            Text("\(value.wrappedValue)")
                .font(.system(.body, design: .monospaced))
                .frame(width: 30, alignment: .center)

            Button(action: {
                if value.wrappedValue < 120 {
                    value.wrappedValue += 1
                    timerManager.applyDuration(for: mode)
                }
            }) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MenuBarView(timerManager: TimerManager())
}
