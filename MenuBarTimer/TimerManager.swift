import SwiftUI
import UserNotifications
import ServiceManagement

enum TimerMode: CaseIterable {
    case focus
    case shortBreak
    case longBreak

    var name: String {
        switch self {
        case .focus: return NSLocalizedString("mode.focus", comment: "")
        case .shortBreak: return NSLocalizedString("mode.shortBreak", comment: "")
        case .longBreak: return NSLocalizedString("mode.longBreak", comment: "")
        }
    }

    var color: Color {
        switch self {
        case .focus: return .orange
        case .shortBreak: return .teal
        case .longBreak: return .indigo
        }
    }
}

class TimerManager: ObservableObject {
    @Published var secondsRemaining: Int
    @Published var isRunning: Bool = false
    @Published var currentMode: TimerMode = .focus
    @Published var completedPomodoros: Int = 0
    @Published var autoStartNext: Bool

    // 自定义时长（分钟）
    @Published var focusMinutes: Int {
        didSet { UserDefaults.standard.set(focusMinutes, forKey: "focusMinutes") }
    }
    @Published var shortBreakMinutes: Int {
        didSet { UserDefaults.standard.set(shortBreakMinutes, forKey: "shortBreakMinutes") }
    }
    @Published var longBreakMinutes: Int {
        didSet { UserDefaults.standard.set(longBreakMinutes, forKey: "longBreakMinutes") }
    }

    // 长休息间隔（每N个番茄后触发长休息）
    @Published var longBreakInterval: Int {
        didSet { UserDefaults.standard.set(longBreakInterval, forKey: "longBreakInterval") }
    }

    private var timer: Timer?
    private var targetDate: Date?

    var timeString: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        1.0 - Double(secondsRemaining) / Double(durationFor(currentMode))
    }

    func durationFor(_ mode: TimerMode) -> Int {
        switch mode {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    init() {
        let focus = UserDefaults.standard.object(forKey: "focusMinutes") as? Int ?? 25
        let shortBreak = UserDefaults.standard.object(forKey: "shortBreakMinutes") as? Int ?? 5
        let longBreak = UserDefaults.standard.object(forKey: "longBreakMinutes") as? Int ?? 15
        let auto = UserDefaults.standard.object(forKey: "autoStartNext") as? Bool ?? false
        let interval = UserDefaults.standard.object(forKey: "longBreakInterval") as? Int ?? 4

        self.focusMinutes = focus
        self.shortBreakMinutes = shortBreak
        self.longBreakMinutes = longBreak
        self.longBreakInterval = interval
        self.autoStartNext = auto
        self.secondsRemaining = focus * 60

        self.completedPomodoros = Self.loadTodayPomodoros()

        requestNotificationPermission()
        cleanOldHistory()
    }

    func start() {
        isRunning = true
        targetDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let target = self.targetDate else { return }
            let remaining = Int(ceil(target.timeIntervalSinceNow))
            if remaining > 0 {
                self.secondsRemaining = remaining
            } else {
                self.secondsRemaining = 0
                self.onComplete()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetDate = nil
    }

    func reset() {
        pause()
        secondsRemaining = durationFor(currentMode)
    }

    func switchMode(_ mode: TimerMode) {
        pause()
        currentMode = mode
        secondsRemaining = durationFor(mode)
    }

    func skipToNext() {
        pause()
        if currentMode == .focus {
            currentMode = completedPomodoros % longBreakInterval == 0 && completedPomodoros > 0 ? .longBreak : .shortBreak
        } else {
            currentMode = .focus
        }
        secondsRemaining = durationFor(currentMode)
    }

    func setAutoStartNext(_ value: Bool) {
        autoStartNext = value
        UserDefaults.standard.set(value, forKey: "autoStartNext")
    }

    func applyDuration(for mode: TimerMode) {
        if currentMode == mode && !isRunning {
            secondsRemaining = durationFor(mode)
        }
    }

    // MARK: - 完成处理

    private func onComplete() {
        pause()
        if currentMode == .focus {
            completedPomodoros += 1
            saveTodayPomodoros()
            sendNotification(title: NSLocalizedString("notification.focusDone.title", comment: ""), body: NSLocalizedString("notification.focusDone.body", comment: ""))
            currentMode = completedPomodoros % longBreakInterval == 0 ? .longBreak : .shortBreak
        } else {
            sendNotification(title: NSLocalizedString("notification.breakDone.title", comment: ""), body: NSLocalizedString("notification.breakDone.body", comment: ""))
            currentMode = .focus
        }
        secondsRemaining = durationFor(currentMode)

        if autoStartNext {
            start()
        }
    }

    // MARK: - 通知

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 持久化

    private static let pomodoroKey = "pomodoroHistory"

    private static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func loadTodayPomodoros() -> Int {
        let history = UserDefaults.standard.dictionary(forKey: pomodoroKey) as? [String: Int] ?? [:]
        return history[todayKey()] ?? 0
    }

    private func saveTodayPomodoros() {
        var history = UserDefaults.standard.dictionary(forKey: Self.pomodoroKey) as? [String: Int] ?? [:]
        history[Self.todayKey()] = completedPomodoros
        UserDefaults.standard.set(history, forKey: Self.pomodoroKey)
    }

    private func cleanOldHistory() {
        var history = UserDefaults.standard.dictionary(forKey: Self.pomodoroKey) as? [String: Int] ?? [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        history = history.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= cutoff
        }
        UserDefaults.standard.set(history, forKey: Self.pomodoroKey)
    }

    /// 获取近 N 天的番茄记录（日期字符串 -> 数量）
    func recentHistory(days: Int) -> [(date: String, count: Int)] {
        let history = UserDefaults.standard.dictionary(forKey: Self.pomodoroKey) as? [String: Int] ?? [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current

        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let key = formatter.string(from: date)
            return (date: key, count: history[key] ?? 0)
        }
    }

    /// 近 N 天总番茄数
    func totalPomodoros(days: Int) -> Int {
        recentHistory(days: days).reduce(0) { $0 + $1.count }
    }

    // MARK: - 开机自启动

    var launchAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            objectWillChange.send()
        } catch {
            print("LaunchAtLogin error: \(error)")
        }
    }
}
