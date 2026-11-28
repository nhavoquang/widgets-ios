import AppIntents
import CozyCore
import WidgetKit

/// Kho dùng chung cho App, Widget và Intents (cùng trỏ vào App Group).
enum CozyShared {
    static let repository = CozyRepository.shared()
    static let store = SharedWidgetStore(repository: repository)

    /// Gọi sau mỗi thay đổi: cập nhật UserDefaults dùng chung và vẽ lại widget.
    static func didChange() {
        store.publishQuickState()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Dùng trong AppIntent: cập nhật widget rồi đẩy lên iCloud (nếu bật).
    static func finishIntent() async {
        didChange()
        try? await CloudSync.shared.sync()
    }
}

// MARK: - Từ vựng (nút bấm trực tiếp trên Home Screen Widget)

struct MarkWordLearnedIntent: AppIntent {
    static let title: LocalizedStringResource = "Đã thuộc từ này"
    static let description = IntentDescription("Đánh dấu từ hôm nay là đã thuộc và chuyển sang từ kế tiếp.")
    static let isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        CozyShared.repository.markCurrentWordLearned()
        await CozyShared.finishIntent()
        return .result()
    }
}

struct NextVocabIntent: AppIntent {
    static let title: LocalizedStringResource = "Đổi từ khác"
    static let description = IntentDescription("Bỏ qua từ hiện tại, hiện một từ khác.")
    static let isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        CozyShared.repository.skipCurrentWord()
        await CozyShared.finishIntent()
        return .result()
    }
}

struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Đánh dấu hoàn thành việc"
    static let description = IntentDescription("Tích xong hoặc bỏ tích một công việc hôm nay ngay trên Widget.")
    static let isDiscoverable: Bool = false

    @Parameter(title: "ID công việc")
    var taskID: String

    init() { self.taskID = "" }
    init(taskID: UUID) { self.taskID = taskID.uuidString }

    func perform() async throws -> some IntentResult {
        if let uuid = UUID(uuidString: taskID) {
            CozyShared.repository.toggleTask(id: uuid)
            await CozyShared.finishIntent()
        }
        return .result()
    }
}

// MARK: - Mood (Shortcuts, Focus, Apple Watch automation)

enum MoodOption: String, AppEnum {
    case happy, chill, sleepy, excited, tired, missing, busy

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Cảm xúc"
    static let caseDisplayRepresentations: [MoodOption: DisplayRepresentation] = [
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

enum FoodOption: String, AppEnum {
    case pho, bunBo, comTam, banhMi, milkTea, coffee, sushi, pizza, hotpot, salad, noodles, dessert

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Món ăn"
    static let caseDisplayRepresentations: [FoodOption: DisplayRepresentation] = [
        .pho: "🍜 Phở",
        .bunBo: "🌶️ Bún bò",
        .comTam: "🍚 Cơm tấm",
        .banhMi: "🥖 Bánh mì",
        .milkTea: "🧋 Trà sữa",
        .coffee: "☕️ Cà phê",
        .sushi: "🍣 Sushi",
        .pizza: "🍕 Pizza",
        .hotpot: "🍲 Lẩu",
        .salad: "🥗 Salad",
        .noodles: "🍝 Mì",
        .dessert: "🍮 Chè/Bánh ngọt",
    ]

    var food: FoodSticker { FoodSticker(rawValue: rawValue)! }
}

enum CheckInSourceOption: String, AppEnum {
    case shortcut, focus, workout, widget

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Nguồn"
    static let caseDisplayRepresentations: [CheckInSourceOption: DisplayRepresentation] = [
        .shortcut: "Phím tắt",
        .focus: "Chế độ Tập trung",
        .workout: "Hoàn thành bài tập",
        .widget: "Widget",
    ]
}

struct QuickCheckInIntent: AppIntent {
    static let title: LocalizedStringResource = "Check-in nhanh CozyDaily"
    static let description = IntentDescription("Ghi nhanh cảm xúc và món ăn. Dùng trên widget, Phím tắt, Tập trung hoặc sau khi tập trên Apple Watch.")

    @Parameter(title: "Cảm xúc")
    var mood: MoodOption?

    @Parameter(title: "Món ăn")
    var food: FoodOption?

    @Parameter(title: "Nguồn", default: .shortcut)
    var source: CheckInSourceOption

    init() {}

    init(mood: MoodOption? = nil, food: FoodOption? = nil, source: CheckInSourceOption = .widget) {
        self.mood = mood
        self.food = food
        self.source = source
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Check-in mood \(\.$mood) món \(\.$food)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let entry = CozyShared.repository.quickCheckIn(
            mood: mood?.mood, food: food?.food,
            source: CheckIn.Source(rawValue: source.rawValue) ?? .shortcut
        )
        await CozyShared.finishIntent()
        return .result(dialog: "Đã check-in: \(entry.mood.emoji) \(entry.mood.displayName)")
    }
}

// MARK: - Quick Ping (Couple Space)

enum PingOption: String, AppEnum {
    case ateYet, missYou, craveMilkTea, goodNight, goodMorning, hugs, callMe

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Quick Ping"
    static let caseDisplayRepresentations: [PingOption: DisplayRepresentation] = [
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
    static let title: LocalizedStringResource = "Gửi Quick Ping"
    static let description = IntentDescription("Gửi lời nhắn nhanh cho người yêu.")

    @Parameter(title: "Lời nhắn", default: .missYou)
    var ping: PingOption

    init() {}
    init(ping: PingOption) { self.ping = ping }

    func perform() async throws -> some IntentResult {
        let repo = CozyShared.repository
        if let space = repo.space(kind: .couple) {
            repo.send(.ping(ping.ping), in: space.id, to: space.partner(of: DemoData.meID)?.id)
        }
        await CozyShared.finishIntent()
        return .result()
    }
}

// MARK: - Chọn cấu hình từ Xưởng Widget

struct StudioWidgetEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Mẫu widget"
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
    static let title: LocalizedStringResource = "Chọn mẫu từ Xưởng Widget"
    static let description = IntentDescription("Hiển thị một mẫu widget bạn đã thiết kế trong tab Xưởng Widget.")

    @Parameter(title: "Mẫu widget")
    var design: StudioWidgetEntity?

    init() {}
    init(design: StudioWidgetEntity?) { self.design = design }
}
