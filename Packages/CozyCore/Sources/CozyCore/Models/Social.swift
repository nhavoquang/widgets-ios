import Foundation

/// Loại không gian chia sẻ (mục 3.4).
public enum SpaceKind: String, Codable, CaseIterable, Sendable {
    case couple, squad

    public var displayName: String {
        switch self {
        case .couple: return "Cặp đôi"
        case .squad: return "Nhóm bạn"
        }
    }

    public var memberLimit: ClosedRange<Int> {
        switch self {
        case .couple: return 2...2
        case .squad: return 3...8
        }
    }
}

/// Trạng thái công khai của một thành viên trong không gian chia sẻ.
public struct MemberStatus: Codable, Hashable, Sendable, Identifiable {
    public var id: String          // CloudKit userRecordID.recordName (hoặc "me")
    public var displayName: String
    public var species: MascotSpecies
    public var mood: Mood?
    public var foods: [FoodSticker]
    public var socialBattery: Int?
    /// Pin thiết bị 0...1 (chia sẻ tự nguyện).
    public var deviceBattery: Double?
    public var weatherLine: String?
    public var note: String
    public var updatedAt: Date

    public init(
        id: String, displayName: String, species: MascotSpecies,
        mood: Mood? = nil, foods: [FoodSticker] = [], socialBattery: Int? = nil,
        deviceBattery: Double? = nil, weatherLine: String? = nil, note: String = "", updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.species = species
        self.mood = mood
        self.foods = foods
        self.socialBattery = socialBattery
        self.deviceBattery = deviceBattery
        self.weatherLine = weatherLine
        self.note = note
        self.updatedAt = updatedAt
    }
}

/// Quick Ping cho Couple Space.
public enum QuickPing: String, Codable, CaseIterable, Sendable, Identifiable {
    case ateYet, missYou, craveMilkTea, goodNight, goodMorning, hugs, callMe

    public var id: String { rawValue }

    public var text: String {
        switch self {
        case .ateYet: return "Ăn cơm chưa?"
        case .missYou: return "Đang nhớ nè"
        case .craveMilkTea: return "Thèm trà sữa"
        case .goodNight: return "Ngủ ngon nha"
        case .goodMorning: return "Dậy chưa đó?"
        case .hugs: return "Ôm cái nè"
        case .callMe: return "Gọi chút nha"
        }
    }

    public var emoji: String {
        switch self {
        case .ateYet: return "🍚"
        case .missYou: return "🥺"
        case .craveMilkTea: return "🧋"
        case .goodNight: return "🌙"
        case .goodMorning: return "☀️"
        case .hugs: return "🤗"
        case .callMe: return "📞"
        }
    }
}

/// Một tương tác trong ngày: ping (cặp đôi) hoặc sticker phản hồi (nhóm).
public struct Interaction: Codable, Hashable, Sendable, Identifiable {
    public enum Payload: Codable, Hashable, Sendable {
        case ping(QuickPing)
        case sticker(String)
        case text(String)
    }

    public var id: UUID
    public var fromMemberID: String
    public var toMemberID: String?
    public var payload: Payload
    public var sentAt: Date

    public init(id: UUID = UUID(), from: String, to: String? = nil, payload: Payload, sentAt: Date = Date()) {
        self.id = id
        self.fromMemberID = from
        self.toMemberID = to
        self.payload = payload
        self.sentAt = sentAt
    }

    public var displayText: String {
        switch payload {
        case .ping(let p): return "\(p.emoji) \(p.text)"
        case .sticker(let s): return s
        case .text(let t): return t
        }
    }
}

/// Không gian chia sẻ (đồng bộ qua CloudKit Shared DB + CKShare ở giai đoạn 2).
public struct SharedSpace: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var kind: SpaceKind
    public var name: String
    public var members: [MemberStatus]
    /// Ngày bắt đầu yêu (Couple) — dùng cho đếm ngày yêu.
    public var anniversary: Date?
    public var interactions: [Interaction]
    public var sharedEventIDs: [UUID]
    /// URL CKShare để mời qua iMessage/AirDrop (nil khi chưa chia sẻ).
    public var shareURL: URL?

    public init(
        id: UUID = UUID(), kind: SpaceKind, name: String, members: [MemberStatus],
        anniversary: Date? = nil, interactions: [Interaction] = [], sharedEventIDs: [UUID] = [], shareURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.members = members
        self.anniversary = anniversary
        self.interactions = interactions
        self.sharedEventIDs = sharedEventIDs
        self.shareURL = shareURL
    }

    public func partner(of meID: String) -> MemberStatus? {
        members.first { $0.id != meID }
    }

    public func interactions(on day: Date, calendar: Calendar = .cozy) -> [Interaction] {
        interactions.filter { calendar.isDate($0.sentAt, inSameDayAs: day) }.sorted { $0.sentAt > $1.sentAt }
    }

    public var canAddMember: Bool { members.count < kind.memberLimit.upperBound }
}

/// Sticker phản hồi nhanh cho Squad Board.
public enum SquadReaction {
    public static let all: [String] = ["❤️", "😂", "🔥", "🥹", "👏", "🫶", "😴", "🍻"]
}
