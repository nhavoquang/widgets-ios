import SwiftUI
import AppIntents
import WidgetKit
import CozyCore

@main
struct CozyDailyApp: App {
    @UIApplicationDelegateAdaptor(CozyAppDelegate.self) private var appDelegate
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .tint(Color.accentPeach)
                .preferredColorScheme(model.settings.appearance.colorScheme)
                .task { await model.onForeground() }
                .onOpenURL { url in model.handleIncomingURL(url) }
                .onReceive(NotificationCenter.default.publisher(for: .cozyRemoteDidChange).receive(on: DispatchQueue.main)) { _ in
                    withAnimation(CozyMotion.spring) { model.refresh() }
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await model.onForeground() } }
                }
        }
    }
}

struct RootTabView: View {
    @State private var tab: AppTab = .today

    enum AppTab: Hashable { case today, connect, calendar, studio }

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Hôm nay", systemImage: "sun.horizon.fill") }
                .tag(AppTab.today)
            ConnectView()
                .tabItem { Label("Kết nối", systemImage: "heart.circle.fill") }
                .tag(AppTab.connect)
            CalendarGridView()
                .tabItem { Label("Lịch & Lưới", systemImage: "calendar") }
                .tag(AppTab.calendar)
            StudioView()
                .tabItem { Label("Xưởng Widget", systemImage: "paintbrush.pointed.fill") }
                .tag(AppTab.studio)
        }
    }
}

// MARK: - Shortcuts & Focus

struct CozyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickCheckInIntent(),
            phrases: ["Cập nhật mood \(.applicationName)", "Log mood in \(.applicationName)"],
            shortTitle: "Cập nhật mood",
            systemImageName: "face.smiling"
        )
        AppShortcut(
            intent: SendPingIntent(),
            phrases: ["Gửi ping \(.applicationName)", "Ping my love in \(.applicationName)"],
            shortTitle: "Quick Ping",
            systemImageName: "heart.fill"
        )
    }
}

/// Bộ lọc Tập trung: khi bật Làm việc/Ngủ…, tự đặt mood tương ứng.
struct CozyFocusFilter: SetFocusFilterIntent {
    static let title: LocalizedStringResource = "Mood theo chế độ Tập trung"
    static let description: IntentDescription? = IntentDescription("Tự cập nhật mood CozyDaily khi chế độ Tập trung này bật.")

    @Parameter(title: "Mood khi bật", default: .busy)
    var mood: MoodOption

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Mood: \(mood.mood.emoji) \(mood.mood.displayName)")
    }

    func perform() async throws -> some IntentResult {
        CozyShared.repository.quickMood(mood.mood, source: .focus)
        await CozyShared.finishIntent()
        return .result()
    }
}
