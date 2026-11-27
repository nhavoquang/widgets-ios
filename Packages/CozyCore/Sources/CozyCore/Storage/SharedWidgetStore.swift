import Foundation

/// Từ vựng trong ngày, dạng gọn cho widget.
public struct DailyVocabulary: Codable, Hashable, Sendable {
    public var wordID: String
    public var word: String
    public var phonetic: String
    public var meaning: String
    public var example: String
    /// Đã bấm "Đã thuộc" cho từ này trong hôm nay.
    public var isLearned: Bool
}

/// Cấu hình giao diện widget (bảng màu, font, linh vật).
public struct WidgetThemeConfig: Codable, Hashable, Sendable {
    public var theme: WidgetTheme
    public var accent: ColorToken
    public var font: WidgetFontStyle
    public var showMascot: Bool
    public var species: MascotSpecies
    public var backgroundOpacity: Double

    public init(_ config: WidgetConfig) {
        theme = config.theme
        accent = config.accent
        font = config.font
        showMascot = config.showMascot
        species = config.species
        backgroundOpacity = config.backgroundOpacity
    }

    public func applying(to config: WidgetConfig) -> WidgetConfig {
        var c = config
        c.theme = theme
        c.accent = accent
        c.font = font
        c.showMascot = showMascot
        c.species = species
        c.backgroundOpacity = backgroundOpacity
        return c
    }
}

/// Ảnh chụp nhỏ lưu trong `UserDefaults(suiteName:)`, đọc nhanh mà không cần giải mã cả file JSON.
public struct WidgetQuickState: Codable, Hashable, Sendable {
    public var vocabulary: DailyVocabulary?
    public var checkIn: CheckIn?
    public var weather: WeatherSnapshot?
    public var partner: MemberStatus?
    public var streak: Int
    public var updatedAt: Date
}

/// Cửa đọc/ghi dữ liệu dùng chung giữa App và Widget Extension:
/// file JSON trong App Group là nguồn chính (qua `CozyRepository`),
/// `UserDefaults(suiteName:)` giữ bản tóm tắt `WidgetQuickState`.
public final class SharedWidgetStore: @unchecked Sendable {
    public static let quickStateKey = "cozy.quickState.v1"

    public let repository: CozyRepository
    private let defaults: UserDefaults?

    public init(repository: CozyRepository, defaults: UserDefaults?) {
        self.repository = repository
        self.defaults = defaults
    }

    public convenience init(repository: CozyRepository) {
        self.init(repository: repository, defaults: SnapshotStore.activeAppGroupID.flatMap { UserDefaults(suiteName: $0) })
    }

    // MARK: Đọc

    public func vocabulary(now: Date = Date()) -> DailyVocabulary? {
        guard let w = repository.currentWord(now: now) else { return nil }
        let state = repository.snapshot().reviewStates[w.id]
        let learnedToday = state?.lastReviewed.map { repository.calendar.isDate($0, inSameDayAs: now) && (state?.stage ?? 0) > 0 } ?? false
        return DailyVocabulary(wordID: w.id, word: w.word, phonetic: w.phonetic, meaning: w.meaning, example: w.example, isLearned: learnedToday)
    }

    public func latestCheckIn() -> CheckIn? { repository.latestCheckIn() }

    public func weather() -> WeatherSnapshot? { repository.snapshot().weather }

    /// Trạng thái người yêu và nhóm bạn (CloudKit ghi vào đây sau khi đồng bộ).
    public func spaces() -> [SharedSpace] { repository.snapshot().spaces }

    public func themeConfig(id: UUID) -> WidgetThemeConfig? {
        repository.widgetConfig(id: id).map(WidgetThemeConfig.init)
    }

    public func quickState() -> WidgetQuickState? {
        guard let data = defaults?.data(forKey: Self.quickStateKey) else { return nil }
        return try? JSONDecoder().decode(WidgetQuickState.self, from: data)
    }

    // MARK: Ghi

    public func saveThemeConfig(_ theme: WidgetThemeConfig, id: UUID) {
        guard let config = repository.widgetConfig(id: id) else { return }
        repository.upsertWidgetConfig(theme.applying(to: config))
    }

    /// Cập nhật bản tóm tắt trong UserDefaults. Gọi sau mỗi thay đổi.
    @discardableResult
    public func publishQuickState(now: Date = Date()) -> WidgetQuickState {
        let vocab = vocabulary(now: now)
        let snap = repository.snapshot()
        let state = WidgetQuickState(
            vocabulary: vocab,
            checkIn: repository.latestCheckIn(),
            weather: snap.weather,
            partner: snap.spaces.preferred(.couple)?.partner(of: DemoData.meID),
            streak: CozyRepository.streak(log: snap.learnedLog, now: now, calendar: repository.calendar),
            updatedAt: now
        )
        if let data = try? JSONEncoder().encode(state) { defaults?.set(data, forKey: Self.quickStateKey) }
        return state
    }
}
