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
