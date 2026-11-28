import Foundation

/// Chế độ giao diện hiển thị của app.
public enum AppAppearance: String, Codable, CaseIterable, Sendable, Identifiable {
    case system, light, dark

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return "Theo máy"
        case .light: return "Sáng ấm"
        case .dark: return "Tối dịu"
        }
    }

    public var symbolName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
}

/// Cài đặt người dùng.
public struct UserSettings: Codable, Hashable, Sendable {
    public var displayName: String
    public var species: MascotSpecies
    public var activeDecks: Set<VocabDeck>
    public var shareWeatherWithSpaces: Bool
    public var shareDeviceBattery: Bool
    public var syncAppleCalendar: Bool
    public var hasOnboarded: Bool
    public var appearance: AppAppearance
    public var hapticsEnabled: Bool
    public var weatherLocation: WeatherLocationPreset

    public init(
        displayName: String = "Mình",
        species: MascotSpecies = .cat,
        activeDecks: Set<VocabDeck> = [.daily, .healing],
        shareWeatherWithSpaces: Bool = true,
        shareDeviceBattery: Bool = true,
        syncAppleCalendar: Bool = false,
        hasOnboarded: Bool = false,
        appearance: AppAppearance = .system,
        hapticsEnabled: Bool = true,
        weatherLocation: WeatherLocationPreset = .autoGPS
    ) {
        self.displayName = displayName
        self.species = species
        self.activeDecks = activeDecks
        self.shareWeatherWithSpaces = shareWeatherWithSpaces
        self.shareDeviceBattery = shareDeviceBattery
        self.syncAppleCalendar = syncAppleCalendar
        self.hasOnboarded = hasOnboarded
        self.appearance = appearance
        self.hapticsEnabled = hapticsEnabled
        self.weatherLocation = weatherLocation
    }

    private enum CodingKeys: String, CodingKey {
        case displayName, species, activeDecks, shareWeatherWithSpaces, shareDeviceBattery, syncAppleCalendar, hasOnboarded, appearance, hapticsEnabled, weatherLocation
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? "Mình"
        self.species = try c.decodeIfPresent(MascotSpecies.self, forKey: .species) ?? .cat
        self.activeDecks = try c.decodeIfPresent(Set<VocabDeck>.self, forKey: .activeDecks) ?? [.daily, .healing]
        self.shareWeatherWithSpaces = try c.decodeIfPresent(Bool.self, forKey: .shareWeatherWithSpaces) ?? true
        self.shareDeviceBattery = try c.decodeIfPresent(Bool.self, forKey: .shareDeviceBattery) ?? true
        self.syncAppleCalendar = try c.decodeIfPresent(Bool.self, forKey: .syncAppleCalendar) ?? false
        self.hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? false
        self.appearance = try c.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        self.hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        self.weatherLocation = try c.decodeIfPresent(WeatherLocationPreset.self, forKey: .weatherLocation) ?? .autoGPS
    }
}

/// Từ đang hiển thị hôm nay (để App và Widget nhìn cùng một từ).
public struct TodayWordPointer: Codable, Hashable, Sendable {
    public var wordID: String
    public var dayKey: String
    public var skipped: [String]

    public init(wordID: String, dayKey: String, skipped: [String] = []) {
        self.wordID = wordID
        self.dayKey = dayKey
        self.skipped = skipped
    }
}

/// Toàn bộ dữ liệu local-first, lưu thành 1 file JSON trong App Group.
public struct CozySnapshot: Codable, Hashable, Sendable {
    public static let currentSchema = 1

    public var schemaVersion: Int
    public var settings: UserSettings
    public var checkIns: [CheckIn]
    public var customWords: [VocabWord]
    public var reviewStates: [String: ReviewState]
    /// Số từ đã thuộc theo ngày (`yyyy-MM-dd` → số lượng) cho streak & lưới vocab.
    public var learnedLog: [String: Int]
    public var todayWord: TodayWordPointer?
    public var events: [CozyEvent]
    public var tasks: [CozyTask]
    public var spaces: [SharedSpace]
    public var activeSpaceID: UUID?
    public var widgetConfigs: [WidgetConfig]
    public var weather: WeatherSnapshot?
    public var updatedAt: Date
    /// ID (sự kiện, mẫu widget) đã xóa, để đồng bộ không làm chúng sống lại.
    public var deletedIDs: [String: Date]?

    public init(
        settings: UserSettings = UserSettings(),
        checkIns: [CheckIn] = [],
        customWords: [VocabWord] = [],
        reviewStates: [String: ReviewState] = [:],
        learnedLog: [String: Int] = [:],
        todayWord: TodayWordPointer? = nil,
        events: [CozyEvent] = [],
        tasks: [CozyTask] = [],
        spaces: [SharedSpace] = [],
        activeSpaceID: UUID? = nil,
        widgetConfigs: [WidgetConfig] = [],
        weather: WeatherSnapshot? = nil,
        updatedAt: Date = Date()
    ) {
        self.schemaVersion = Self.currentSchema
        self.settings = settings
        self.checkIns = checkIns
        self.customWords = customWords
        self.reviewStates = reviewStates
        self.learnedLog = learnedLog
        self.todayWord = todayWord
        self.events = events
        self.tasks = tasks
        self.spaces = spaces
        self.activeSpaceID = activeSpaceID
        self.widgetConfigs = widgetConfigs
        self.weather = weather
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, settings, checkIns, customWords, reviewStates, learnedLog, todayWord, events, tasks, spaces, activeSpaceID, widgetConfigs, weather, updatedAt, deletedIDs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchema
        self.settings = try c.decodeIfPresent(UserSettings.self, forKey: .settings) ?? UserSettings()
        self.checkIns = try c.decodeIfPresent([CheckIn].self, forKey: .checkIns) ?? []
        self.customWords = try c.decodeIfPresent([VocabWord].self, forKey: .customWords) ?? []
        self.reviewStates = try c.decodeIfPresent([String: ReviewState].self, forKey: .reviewStates) ?? [:]
        self.learnedLog = try c.decodeIfPresent([String: Int].self, forKey: .learnedLog) ?? [:]
        self.todayWord = try c.decodeIfPresent(TodayWordPointer.self, forKey: .todayWord)
        self.events = try c.decodeIfPresent([CozyEvent].self, forKey: .events) ?? []
        self.tasks = try c.decodeIfPresent([CozyTask].self, forKey: .tasks) ?? []
        self.spaces = try c.decodeIfPresent([SharedSpace].self, forKey: .spaces) ?? []
        self.activeSpaceID = try c.decodeIfPresent(UUID.self, forKey: .activeSpaceID)
        self.widgetConfigs = try c.decodeIfPresent([WidgetConfig].self, forKey: .widgetConfigs) ?? []
        self.weather = try c.decodeIfPresent(WeatherSnapshot.self, forKey: .weather)
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.deletedIDs = try c.decodeIfPresent([String: Date].self, forKey: .deletedIDs)
    }

    public static let empty = CozySnapshot()

    /// Khởi tạo sạch hoàn toàn bằng dữ liệu thật (không tạo người yêu/sự kiện/thời tiết giả).
    public static func freshReal(now: Date = Date()) -> CozySnapshot {
        let configs: [WidgetConfig] = [
            WidgetConfig(name: "Lịch & Việc hôm nay", content: .schedule, accent: .accentSky, font: .cleanModern),
            WidgetConfig(name: "Từ vựng hôm nay", content: .vocab, accent: .accentSage, font: .cozyRounded),
            WidgetConfig(name: "Thời tiết thật", content: .weather, accent: .accentSky, font: .cozyRounded),
            WidgetConfig(name: "Người kết nối", content: .couple, accent: .accentPeach, font: .cozyRounded),
        ]
        return CozySnapshot(settings: UserSettings(), widgetConfigs: configs, weather: nil, updatedAt: now)
    }

    /// Kiểm tra còn sót dữ liệu mẫu từ các bản cũ không (vd. Gấu, Đi Đà Lạt, TP.HCM 27° mẫu).
    public var hasDemoData: Bool {
        let hasDemoEvents = events.contains { DemoData.isDemo($0.id) }
        let hasDemoCheckIns = checkIns.contains { DemoData.isDemo($0.id) }
        let hasDemoSpaces = spaces.contains { $0.cloud == nil && ($0.name == "Mình & Gấu" || $0.name == "Hội Bánh Tráng") }
        return hasDemoEvents || hasDemoCheckIns || hasDemoSpaces
    }
}
