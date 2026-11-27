import Foundation

/// Cài đặt người dùng.
public struct UserSettings: Codable, Hashable, Sendable {
    public var displayName: String
    public var species: MascotSpecies
    public var activeDecks: Set<VocabDeck>
    public var shareWeatherWithSpaces: Bool
    public var shareDeviceBattery: Bool
    public var syncAppleCalendar: Bool
    public var hasOnboarded: Bool

    public init(
        displayName: String = "Mình",
        species: MascotSpecies = .cat,
        activeDecks: Set<VocabDeck> = [.daily, .healing],
        shareWeatherWithSpaces: Bool = true,
        shareDeviceBattery: Bool = true,
        syncAppleCalendar: Bool = false,
        hasOnboarded: Bool = false
    ) {
        self.displayName = displayName
        self.species = species
        self.activeDecks = activeDecks
        self.shareWeatherWithSpaces = shareWeatherWithSpaces
        self.shareDeviceBattery = shareDeviceBattery
        self.syncAppleCalendar = syncAppleCalendar
        self.hasOnboarded = hasOnboarded
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
        self.spaces = spaces
        self.activeSpaceID = activeSpaceID
        self.widgetConfigs = widgetConfigs
        self.weather = weather
        self.updatedAt = updatedAt
    }

    public static let empty = CozySnapshot()
}
