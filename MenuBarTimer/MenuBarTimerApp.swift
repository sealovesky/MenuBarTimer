import SwiftUI

@main
struct MenuBarTimerApp: App {
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        // 菜单栏应用 - macOS 13+
        MenuBarExtra {
            MenuBarView(timerManager: timerManager)
        } label: {
            Label {
                Text("Timer")
            } icon: {
                if timerManager.isRunning {
                    Text(timerManager.timeString)
                        .font(.system(.body, design: .monospaced))
                } else {
                    Image(systemName: "timer")
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
