import WidgetKit
import SwiftUI
import CozyCore

@main
struct CozyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayScheduleWidget()
        QuickLauncherWidget()
        VocabWidget()
        WeatherCozyWidget()
        CoupleWidget()
        StudioWidget()
        EventWidget()
        StandByWidget()
    }
}

/// Đọc family từ môi trường WidgetKit rồi chuyển cho view dùng chung.
struct CozyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var data: CozyWidgetData

    var body: some View {
        CozyWidgetView(data: data, family: family)
    }
}

// MARK: - Providers

/// Widget tùy biến: đọc cấu hình người dùng đã thiết kế trong Xưởng Widget.
struct StudioProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CozyEntry {
        CozyEntry(date: Date(), data: .placeholder)
    }

    func snapshot(for configuration: SelectStudioWidgetIntent, in context: Context) async -> CozyEntry {
        let cfg = CozyShared.repository.widgetConfig(id: configuration.design?.id)
        return CozyEntry(date: Date(), data: .make(config: cfg, date: Date(), repository: CozyShared.repository))
    }

    func timeline(for configuration: SelectStudioWidgetIntent, in context: Context) async -> Timeline<CozyEntry> {
        let cfg = CozyShared.repository.widgetConfig(id: configuration.design?.id)
        return CozyTimeline.entries(config: cfg, fallback: .combo)
    }
}

/// Provider cố định một loại nội dung (dùng cho các widget "đặt là chạy").
struct FixedProvider: TimelineProvider {
    var content: WidgetContentKind

    func placeholder(in context: Context) -> CozyEntry {
        var data = CozyWidgetData.placeholder
        data.config.content = content
        return CozyEntry(date: Date(), data: data)
    }

    func getSnapshot(in context: Context, completion: @escaping (CozyEntry) -> Void) {
        completion(CozyEntry(date: Date(), data: .make(config: config(), date: Date(), repository: CozyShared.repository)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CozyEntry>) -> Void) {
        completion(CozyTimeline.entries(config: config(), fallback: content))
    }

    /// Ưu tiên mẫu đầu tiên cùng loại nội dung trong Xưởng Widget để giữ font/màu người dùng chọn.
    private func config() -> WidgetConfig {
        let snap = CozyShared.repository.snapshot(reload: true)
        return snap.widgetConfigs.first { $0.content == content }
            ?? WidgetConfig(name: content.displayName, content: content, species: snap.settings.species)
    }
}

// MARK: - Widgets

struct TodayScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyTodayScheduleWidget", provider: FixedProvider(content: .schedule)) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Lịch & Việc hôm nay")
        .description("Hiển thị lịch Apple Calendar và danh sách việc cần làm hôm nay trên Lock Screen & Home Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeatherCozyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyWeatherWidget", provider: FixedProvider(content: .weather)) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Thời tiết thật")
        .description("Nhiệt độ thật, cảm giác, cao/thấp & độ ẩm hiển thị gọn đẹp trên Lock Screen và Home Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall, .systemMedium])
    }
}

struct StudioWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "CozyStudioWidget", intent: SelectStudioWidgetIntent.self, provider: StudioProvider()) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Xưởng Widget")
        .description("Hiển thị mẫu bạn tự thiết kế: nội dung, linh vật 3D, màu, font và khung viền.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct VocabWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyVocabWidget", provider: FixedProvider(content: .vocab)) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Từ vựng hôm nay")
        .description("Bấm “Đã thuộc” hoặc “Đổi từ” ngay trên màn hình chính. Lock Screen có chế độ ẩn nghĩa.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct CoupleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyCoupleWidget", provider: FixedProvider(content: .couple)) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Cảm xúc người kết nối")
        .description("Hiện cảm xúc, lời nhắn, thời tiết & pin của người đã kết nối ngay trên Lock Screen và Home Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall, .systemMedium])
    }
}

struct EventWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyEventWidget", provider: FixedProvider(content: .event)) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Đếm ngày")
        .description("Đếm ngược, đếm tiến, âm lịch, lịch tuần và deadline.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

/// Quick Launcher Widget: Mở nhanh 4 ứng dụng / QR / Thêm việc chỉ với 1 chạm ngay từ dải dưới đồng hồ Lock Screen!
struct QuickLauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyQuickLauncherWidget", provider: FixedProvider(content: .combo)) { entry in
            QuickLauncherWidgetView(data: entry.data)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Quick Launcher")
        .description("1-tap shortcuts to launch Tasks, Calendar, Spotify, ChatGPT or QR links right from your Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .systemMedium])
    }
}

struct QuickLauncherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var data: CozyWidgetData

    private func targetURL(for preset: QuickLaunchPreset, settings: UserSettings) -> URL {
        if preset == .customURL,
           !settings.customQuickLaunchURL.isEmpty,
           let u = URL(string: settings.customQuickLaunchURL) {
            return u
        }
        return URL(string: preset.defaultURLString) ?? URL(string: "cozydaily://open?tab=today")!
    }

    var body: some View {
        let settings = CozyShared.repository.snapshot(reload: true).settings
        let slots = settings.quickLaunchSlots.isEmpty ? [.addTask, .calendarApp, .spotify, .chatgpt] : settings.quickLaunchSlots

        switch family {
        case .accessoryCircular:
            let first = slots[0]
            Link(destination: targetURL(for: first, settings: settings)) {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: first.symbolName)
                        .font(.system(size: 18, weight: .bold))
                        .widgetAccentable()
                }
            }
        default:
            HStack(spacing: 8) {
                ForEach(Array(slots.prefix(4).enumerated()), id: \.offset) { _, item in
                    Link(destination: targetURL(for: item, settings: settings)) {
                        VStack(spacing: 4) {
                            Image(systemName: item.symbolName)
                                .font(.system(size: family == .systemMedium ? 18 : 14, weight: .bold))
                                .frame(width: family == .systemMedium ? 42 : 30, height: family == .systemMedium ? 42 : 30)
                                .background(Circle().fill(Color.primary.opacity(0.16)))
                                .widgetAccentable()
                            Text(item.title)
                                .font(.system(size: family == .systemMedium ? 11 : 9, weight: .semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

/// StandBy Mode: đồng hồ ngang ban đêm + linh vật ngủ + lịch trình ngày mai.
struct StandByWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CozyStandByWidget", provider: FixedProvider(content: .mascot)) { entry in
            StandByView(data: entry.data)
                .containerBackground(for: .widget) { Color(RGBA(hex: "#1F1B17")!) }
        }
        .configurationDisplayName("Đêm an yên (StandBy)")
        .description("Đồng hồ ban đêm cùng linh vật và lịch trình ngày mai.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StandByView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    var data: CozyWidgetData

    var body: some View {
        let ink = Color(RGBA(hex: "#F3EDE4")!)
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.date, style: .time)
                    .font(.system(size: family == .systemSmall ? 34 : 44, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .widgetAccentable()
                Text("\(data.lunar.shortText) ÂL · \(data.lunar.yearName)")
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.7)
                if family == .systemMedium {
                    Text("Ngày mai").font(.system(size: 11, weight: .bold)).opacity(0.7).padding(.top, 4)
                    if data.tomorrowEvents.isEmpty {
                        Text("Thảnh thơi, không có lịch 🌙").font(.system(size: 12))
                    } else {
                        ForEach(Array(data.tomorrowEvents.prefix(2))) { item in
                            Text("\(item.event.emoji) \(item.event.title)").font(.system(size: 12, weight: .semibold)).lineLimit(1)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if renderingMode == .fullColor {
                MascotView(state: data.mascot, size: family == .systemSmall ? 48 : 76, showsBackground: false, animated: false)
            } else {
                MascotGlyph(state: data.mascot)
            }
        }
        .foregroundStyle(ink)
    }
}
