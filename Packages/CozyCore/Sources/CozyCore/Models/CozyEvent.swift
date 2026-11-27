import Foundation

/// 5 chế độ đếm thời gian (mục 3.5).
public enum EventKind: Codable, Hashable, Sendable {
    /// Đếm ngược tới một ngày. `repeatsYearly` cho sinh nhật/kỷ niệm.
    case countdown(date: Date, repeatsYearly: Bool)
    /// Đếm tiến từ một ngày (vd. ngày yêu nhau).
    case countUp(since: Date)
    /// Ngày âm lịch. `month == nil` nghĩa là lặp hằng tháng (Mùng 1, Rằm).
    case lunar(day: Int, month: Int?)
    /// Lịch lặp lại hằng tuần. `weekdays` theo chuẩn Calendar: 1 = Chủ nhật ... 7 = Thứ bảy.
    case weekly(weekdays: [Int], hour: Int, minute: Int)
    /// Deadline nhắc việc (có giờ cụ thể).
    case deadline(due: Date)

    public var modeName: String {
        switch self {
        case .countdown: return "Đếm ngược"
        case .countUp: return "Đếm tiến"
        case .lunar: return "Âm lịch"
        case .weekly: return "Hằng tuần"
        case .deadline: return "Deadline"
        }
    }

    public var symbolName: String {
        switch self {
        case .countdown: return "hourglass"
        case .countUp: return "heart.circle"
        case .lunar: return "moon.stars"
        case .weekly: return "repeat"
        case .deadline: return "flag.checkered"
        }
    }
}

public struct CozyEvent: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var emoji: String
    public var kind: EventKind
    public var accent: ColorToken
    /// Sự kiện chung của Cặp đôi/Nhóm (đồng bộ lên Lock Screen mọi thành viên).
    public var isShared: Bool
    /// Nhập từ Apple Calendar (EventKit) — chỉ đọc.
    public var externalIdentifier: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        emoji: String = "📅",
        kind: EventKind,
        accent: ColorToken = .accentSky,
        isShared: Bool = false,
        externalIdentifier: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.kind = kind
        self.accent = accent
        self.isShared = isShared
        self.externalIdentifier = externalIdentifier
        self.createdAt = createdAt
    }
}
