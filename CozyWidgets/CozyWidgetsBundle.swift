import WidgetKit
import SwiftUI
import CozyCore

@main
struct CozyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StudioWidget()
        VocabWidget()
        CoupleWidget()
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

struct StudioWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "CozyStudioWidget", intent: SelectStudioWidgetIntent.self, provider: StudioProvider()) { entry in
            CozyWidgetEntryView(data: entry.data)
        }
        .configurationDisplayName("Xưởng Widget")
        .description("Hiển thị mẫu bạn tự thiết kế: nội dung, linh vật, màu, font và khung viền.")
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
        .configurationDisplayName("Người yêu")
        .description("Thẻ trạng thái đôi, đếm ngày yêu và Quick Ping.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
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
