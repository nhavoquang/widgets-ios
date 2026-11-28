import Foundation

/// 4 tùy chọn font cho widget (mục 2.2).
public enum WidgetFontStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case cozyRounded, editorialSerif, cleanModern, cuteHandwritten

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cozyRounded: return "Cozy Rounded"
        case .editorialSerif: return "Editorial Serif"
        case .cleanModern: return "Clean Modern"
        case .cuteHandwritten: return "Cute Handwritten"
        }
    }

    public var hint: String {
        switch self {
        case .cozyRounded: return "Bo tròn mềm mại — mặc định"
        case .editorialSerif: return "Thanh lịch — hợp từ vựng & trích dẫn"
        case .cleanModern: return "Gọn gàng — hợp lịch & deadline"
        case .cuteHandwritten: return "Viết tay — hợp lời nhắn đôi/nhóm"
        }
    }

    /// Font gợi ý cho từng loại nội dung.
    public static func recommended(for content: WidgetContentKind) -> WidgetFontStyle {
        switch content {
        case .vocab: return .editorialSerif
        case .event, .weather: return .cleanModern
        case .couple, .squad: return .cuteHandwritten
        default: return .cozyRounded
        }
    }
}

/// Lớp 1 — Nội dung.
public enum WidgetContentKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case schedule, vocab, weather, couple, moodFood, squad, event, streak, mascot, combo

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .schedule: return "Lịch & Việc hôm nay"
        case .vocab: return "Từ vựng"
        case .moodFood: return "Mood + Món ăn"
        case .couple: return "Người kết nối"
        case .squad: return "Nhóm bạn"
        case .event: return "Sự kiện"
        case .weather: return "Thời tiết"
        case .streak: return "Chuỗi học"
        case .mascot: return "Linh vật"
        case .combo: return "Tổng hợp"
        }
    }

    public var symbolName: String {
        switch self {
        case .schedule: return "checklist"
        case .vocab: return "character.book.closed.fill"
        case .moodFood: return "face.smiling"
        case .couple: return "heart.fill"
        case .squad: return "person.3.fill"
        case .event: return "calendar"
        case .weather: return "cloud.sun.fill"
        case .streak: return "flame.fill"
        case .mascot: return "pawprint.fill"
        case .combo: return "square.split.2x1.fill"
        }
    }

    public var defaultAccent: ColorToken {
        switch self {
        case .schedule, .event, .weather: return .accentSky
        case .vocab, .streak: return .accentSage
        case .moodFood, .couple, .squad, .mascot: return .accentPeach
        case .combo: return .accentHoney
        }
    }
}

/// Lớp 2 — Theme.
public enum WidgetTheme: String, Codable, CaseIterable, Sendable, Identifiable {
    case paper, watercolor, night, festive

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .paper: return "Giấy kem"
        case .watercolor: return "Màu nước"
        case .night: return "Đêm ấm"
        case .festive: return "Lễ hội"
        }
    }
}

public enum WidgetBorderStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    case none, hairline, dashed, stitched

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "Không viền"
        case .hairline: return "Viền mảnh"
        case .dashed: return "Nét đứt"
        case .stitched: return "Đường may"
        }
    }
}

/// Smart Auto-Theme: đổi sáng/tối theo khung giờ hoặc dịp lễ.
public enum AutoThemeMode: String, Codable, CaseIterable, Sendable {
    case off, byTimeOfDay, byHoliday, both

    public var displayName: String {
        switch self {
        case .off: return "Tắt"
        case .byTimeOfDay: return "Theo khung giờ"
        case .byHoliday: return "Theo dịp lễ"
        case .both: return "Cả hai"
        }
    }
}

/// Cấu hình tùy biến độc lập cho từng widget (Pro Widget Studio, mục 3.6).
public struct WidgetConfig: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    // Lớp 1 — Nội dung
    public var content: WidgetContentKind
    public var secondaryContent: WidgetContentKind?
    public var eventID: UUID?
    public var hideMeaningOnLockScreen: Bool
    // Lớp 2 — Theme & Linh vật
    public var theme: WidgetTheme
    public var showMascot: Bool
    public var species: MascotSpecies
    // Lớp 3 — Bảng màu & Độ trong suốt
    public var accent: ColorToken
    /// 0...1 — độ đục nền widget.
    public var backgroundOpacity: Double
    // Lớp 4 — Font & Khung viền
    public var font: WidgetFontStyle
    public var border: WidgetBorderStyle
    public var autoTheme: AutoThemeMode

    public init(
        id: UUID = UUID(),
        name: String,
        content: WidgetContentKind,
        secondaryContent: WidgetContentKind? = nil,
        eventID: UUID? = nil,
        hideMeaningOnLockScreen: Bool = true,
        theme: WidgetTheme = .paper,
        showMascot: Bool = true,
        species: MascotSpecies = .cat,
        accent: ColorToken? = nil,
        backgroundOpacity: Double = 1,
        font: WidgetFontStyle? = nil,
        border: WidgetBorderStyle = .hairline,
        autoTheme: AutoThemeMode = .byTimeOfDay
    ) {
        self.id = id
        self.name = name
        self.content = content
        self.secondaryContent = secondaryContent
        self.eventID = eventID
        self.hideMeaningOnLockScreen = hideMeaningOnLockScreen
        self.theme = theme
        self.showMascot = showMascot
        self.species = species
        self.accent = accent ?? content.defaultAccent
        self.backgroundOpacity = min(max(backgroundOpacity, 0), 1)
        self.font = font ?? WidgetFontStyle.recommended(for: content)
        self.border = border
        self.autoTheme = autoTheme
    }

    /// Theme thực tế sau khi áp dụng Smart Auto-Theme.
    public func effectiveTheme(at date: Date, calendar: Calendar = .cozy) -> WidgetTheme {
        if autoTheme == .byHoliday || autoTheme == .both, HolidayDetector.holiday(on: date, calendar: calendar) != nil {
            return .festive
        }
        if autoTheme == .byTimeOfDay || autoTheme == .both {
            let part = DayPart(date: date, calendar: calendar)
            if part == .lateNight || part == .evening { return .night }
        }
        return theme
    }
}

/// Phát hiện dịp lễ đặc biệt (dương & âm lịch) cho Auto-Theme.
public enum HolidayDetector {
    public struct Holiday: Hashable, Sendable {
        public var name: String
        public var emoji: String
    }

    public static func holiday(on date: Date, calendar: Calendar = .cozy) -> Holiday? {
        let c = calendar.dateComponents([.month, .day], from: date)
        switch (c.month ?? 0, c.day ?? 0) {
        case (1, 1): return Holiday(name: "Năm mới", emoji: "🎆")
        case (2, 14): return Holiday(name: "Valentine", emoji: "💝")
        case (3, 8): return Holiday(name: "Quốc tế Phụ nữ", emoji: "💐")
        case (10, 20): return Holiday(name: "Phụ nữ Việt Nam", emoji: "🌷")
        case (12, 24), (12, 25): return Holiday(name: "Giáng sinh", emoji: "🎄")
        default: break
        }
        let lunar = VietnameseLunarCalendar.lunarDate(from: date, calendar: calendar)
        guard !lunar.isLeapMonth else { return nil }
        switch (lunar.month, lunar.day) {
        case (1, 1), (1, 2), (1, 3): return Holiday(name: "Tết Nguyên Đán", emoji: "🧧")
        case (1, 15): return Holiday(name: "Rằm tháng Giêng", emoji: "🏮")
        case (8, 15): return Holiday(name: "Trung Thu", emoji: "🥮")
        case (7, 7): return Holiday(name: "Thất Tịch", emoji: "🌌")
        default: return nil
        }
    }
}
