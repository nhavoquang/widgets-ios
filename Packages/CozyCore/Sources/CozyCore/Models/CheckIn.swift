import Foundation

/// 7 trạng thái cảm xúc (mục 2.3).
public enum Mood: String, Codable, CaseIterable, Sendable, Identifiable {
    case happy, chill, sleepy, excited, tired, missing, busy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .happy: return "Vui vẻ"
        case .chill: return "Chill"
        case .sleepy: return "Buồn ngủ"
        case .excited: return "Háo hức"
        case .tired: return "Mệt mỏi"
        case .missing: return "Nhớ nhung"
        case .busy: return "Bận rộn"
        }
    }

    public var emoji: String {
        switch self {
        case .happy: return "😊"
        case .chill: return "😌"
        case .sleepy: return "😴"
        case .excited: return "🤩"
        case .tired: return "😮‍💨"
        case .missing: return "🥺"
        case .busy: return "🏃"
        }
    }
}

/// Sticker món ăn (mục 3.2).
public enum FoodSticker: String, Codable, CaseIterable, Sendable, Identifiable {
    case pho, bunBo, comTam, banhMi, milkTea, coffee, sushi, pizza, hotpot, salad, noodles, dessert

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pho: return "Phở"
        case .bunBo: return "Bún bò"
        case .comTam: return "Cơm tấm"
        case .banhMi: return "Bánh mì"
        case .milkTea: return "Trà sữa"
        case .coffee: return "Cà phê"
        case .sushi: return "Sushi"
        case .pizza: return "Pizza"
        case .hotpot: return "Lẩu"
        case .salad: return "Salad"
        case .noodles: return "Mì"
        case .dessert: return "Chè/Bánh ngọt"
        }
    }

    public var emoji: String {
        switch self {
        case .pho: return "🍜"
        case .bunBo: return "🌶️"
        case .comTam: return "🍚"
        case .banhMi: return "🥖"
        case .milkTea: return "🧋"
        case .coffee: return "☕️"
        case .sushi: return "🍣"
        case .pizza: return "🍕"
        case .hotpot: return "🍲"
        case .salad: return "🥗"
        case .noodles: return "🍝"
        case .dessert: return "🍮"
        }
    }
}

/// Một lần check-in 1 chạm: Mood + món ăn + pin xã hội + note ngắn.
public struct CheckIn: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var date: Date
    public var mood: Mood
    public var foods: [FoodSticker]
    /// 0...100
    public var socialBattery: Int
    /// Tối đa 30 ký tự.
    public var note: String
    /// Nguồn tạo (thủ công, Shortcut, Focus…)
    public var source: Source

    public enum Source: String, Codable, Sendable {
        case manual, shortcut, focus, workout, widget
    }

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Mood,
        foods: [FoodSticker] = [],
        socialBattery: Int = 60,
        note: String = "",
        source: Source = .manual
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.foods = foods
        self.socialBattery = Self.clampBattery(socialBattery)
        self.note = Self.clampNote(note)
        self.source = source
    }

    public static func clampBattery(_ value: Int) -> Int { min(max(value, 0), 100) }

    public static func clampNote(_ note: String) -> String {
        String(note.prefix(CozyMetrics.noteMaxLength))
    }
}
