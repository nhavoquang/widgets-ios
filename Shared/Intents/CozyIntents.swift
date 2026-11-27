import AppIntents
import CozyCore
import WidgetKit

/// Kho dùng chung cho App, Widget và Intents (cùng trỏ vào App Group).
enum CozyShared {
    static let repository = CozyRepository.shared()

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Từ vựng (nút bấm trực tiếp trên Home Screen Widget)

struct MarkWordLearnedIntent: AppIntent {
    static var title: LocalizedStringResource = "Đã thuộc từ này"
    static var description = IntentDescription("Đánh dấu từ hôm nay là đã thuộc và chuyển sang từ kế tiếp.")
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        CozyShared.repository.markCurrentWordLearned()
        CozyShared.reloadWidgets()
        return .result()
    }
}

struct SkipWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Đổi từ khác"
    static var description = IntentDescription("Bỏ qua từ hiện tại, hiện một từ khác.")
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        CozyShared.repository.skipCurrentWord()
        CozyShared.reloadWidgets()
        return .result()
    }
}

// MARK: - Mood (Shortcuts, Focus, Apple Watch automation)

enum MoodOption: String, AppEnum {
    case happy, chill, sleepy, excited, tired, missing, busy

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Cảm xúc"
    static var caseDisplayRepresentations: [MoodOption: DisplayRepresentation] = [
        .happy: "😊 Vui vẻ",
        .chill: "😌 Chill",
        .sleepy: "😴 Buồn ngủ",
        .excited: "🤩 Háo hức",
        .tired: "😮‍💨 Mệt mỏi",
        .missing: "🥺 Nhớ nhung",
        .busy: "🏃 Bận rộn",
    ]

    var mood: Mood { Mood(rawValue: rawValue)! }
}

struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Cập nhật mood CozyDaily"
    static var description = IntentDescription("Ghi nhanh cảm xúc hiện tại. Dùng trong Phím tắt, Tập trung hoặc sau khi tập luyện trên Apple Watch.")

    @Parameter(title: "Cảm xúc", default: .chill)
    var mood: MoodOption

    @Parameter(title: "Nguồn", default: .shortcut)
    var source: SourceOption

    enum SourceOption: String, AppEnum {
        case shortcut, focus, workout, widget
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Nguồn"
        static var caseDisplayRepresentations: [SourceOption: DisplayRepresentation] = [
            .shortcut: "Phím tắt",
            .focus: "Chế độ Tập trung",
            .workout: "Hoàn thành bài tập",
            .widget: "Widget",
        ]
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Đặt mood thành \(\.$mood)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        CozyShared.repository.quickMood(mood.mood, source: CheckIn.Source(rawValue: source.rawValue) ?? .shortcut)
        CozyShared.reloadWidgets()
        return .result(dialog: "Đã cập nhật mood: \(mood.mood.emoji) \(mood.mood.displayName)")
    }
}

// MARK: - Quick Ping (Couple Space)

enum PingOption: String, AppEnum {
    case ateYet, missYou, craveMilkTea, goodNight, goodMorning, hugs, callMe

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Quick Ping"
    static var caseDisplayRepresentations: [PingOption: DisplayRepresentation] = [
        .ateYet: "🍚 Ăn cơm chưa?",
        .missYou: "🥺 Đang nhớ nè",
        .craveMilkTea: "🧋 Thèm trà sữa",
        .goodNight: "🌙 Ngủ ngon nha",
        .goodMorning: "☀️ Dậy chưa đó?",
        .hugs: "🤗 Ôm cái nè",
        .callMe: "📞 Gọi chút nha",
    ]

    var ping: QuickPing { QuickPing(rawValue: rawValue)! }
}

struct SendPingIntent: AppIntent {
    static var title: LocalizedStringResource = "Gửi Quick Ping"
    static var description = IntentDescription("Gửi lời nhắn nhanh cho người yêu.")

    @Parameter(title: "Lời nhắn", default: .missYou)
    var ping: PingOption

    init() {}
    init(ping: PingOption) { self.ping = ping }

    func perform() async throws -> some IntentResult {
        let repo = CozyShared.repository
        if let space = repo.space(kind: .couple) {
            repo.send(.ping(ping.ping), in: space.id, to: space.partner(of: DemoData.meID)?.id)
        }
        CozyShared.reloadWidgets()
        return .result()
    }
}

// MARK: - Chọn cấu hình từ Xưởng Widget

struct StudioWidgetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Mẫu widget"
    static var defaultQuery = StudioWidgetQuery()

    var id: UUID
    var name: String
    var symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: symbol))
    }

    init(config: WidgetConfig) {
        id = config.id
        name = config.name
        symbol = config.content.symbolName
    }
}

struct StudioWidgetQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [StudioWidgetEntity] {
        CozyShared.repository.snapshot(reload: true).widgetConfigs
            .filter { identifiers.contains($0.id) }
            .map(StudioWidgetEntity.init(config:))
    }

    func suggestedEntities() async throws -> [StudioWidgetEntity] {
        CozyShared.repository.snapshot(reload: true).widgetConfigs.map(StudioWidgetEntity.init(config:))
    }

    func defaultResult() async -> StudioWidgetEntity? {
        try? await suggestedEntities().first
    }
}

struct SelectStudioWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Chọn mẫu từ Xưởng Widget"
    static var description = IntentDescription("Hiển thị một mẫu widget bạn đã thiết kế trong tab Xưởng Widget.")

    @Parameter(title: "Mẫu widget")
    var design: StudioWidgetEntity?

    init() {}
    init(design: StudioWidgetEntity?) { self.design = design }
}
