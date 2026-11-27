import Foundation

public enum MascotSpecies: String, Codable, CaseIterable, Sendable, Identifiable {
    case cat, dog, bunny, bear

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cat: return "Mèo"
        case .dog: return "Cún"
        case .bunny: return "Thỏ"
        case .bear: return "Gấu"
        }
    }

    /// Ảnh giữ chỗ trước khi có bộ minh họa màu nước.
    public var emoji: String {
        switch self {
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .bunny: return "🐰"
        case .bear: return "🐻"
        }
    }
}

/// Khung giờ trong ngày (mục 2.3).
public enum DayPart: String, Codable, CaseIterable, Sendable {
    case morning      // 05:00–10:59
    case afternoon    // 11:00–17:59
    case evening      // 18:00–22:29
    case lateNight    // 22:30–04:59

    public init(date: Date, calendar: Calendar = .cozy) {
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        let minutes = h * 60 + m
        switch minutes {
        case 300..<660: self = .morning
        case 660..<1080: self = .afternoon
        case 1080..<1350: self = .evening
        default: self = .lateNight
        }
    }

    public var greeting: String {
        switch self {
        case .morning: return "Chào buổi sáng"
        case .afternoon: return "Chào buổi chiều"
        case .evening: return "Buổi tối an yên"
        case .lateNight: return "Khuya rồi, ngủ thôi"
        }
    }
}

public enum MascotAccessory: String, Codable, CaseIterable, Sendable {
    case umbrella, rainHat, sunglasses, milkTea, scarf, coffee, riceBowl, book, blanket, heart, laptop, none

    public var emoji: String {
        switch self {
        case .umbrella: return "☂️"
        case .rainHat: return "👒"
        case .sunglasses: return "🕶️"
        case .milkTea: return "🧋"
        case .scarf: return "🧣"
        case .coffee: return "☕️"
        case .riceBowl: return "🍚"
        case .book: return "📖"
        case .blanket: return "🛌"
        case .heart: return "💗"
        case .laptop: return "💻"
        case .none: return ""
        }
    }
}

public enum MascotPose: String, Codable, Sendable {
    case bouncing, lounging, yawning, jumping, slumped, hugging, rushing, sleeping

    public var symbolName: String {
        switch self {
        case .bouncing: return "figure.dance"
        case .lounging: return "sofa.fill"
        case .yawning: return "zzz"
        case .jumping: return "sparkles"
        case .slumped: return "battery.25"
        case .hugging: return "heart.fill"
        case .rushing: return "figure.run"
        case .sleeping: return "moon.zzz.fill"
        }
    }
}

/// Trạng thái hiển thị cuối cùng của linh vật.
public struct MascotState: Hashable, Sendable {
    public var species: MascotSpecies
    public var pose: MascotPose
    /// Tối đa 2 phụ kiện: 1 từ thời tiết + 1 từ khung giờ/cảm xúc.
    public var accessories: [MascotAccessory]
    public var caption: String
    /// Tên asset gợi ý để thay ảnh minh họa thật, vd. "cat_sleeping_blanket".
    public var assetName: String

    public var emojiComposite: String {
        ([species.emoji] + accessories.filter { $0 != .none }.map(\.emoji)).joined()
    }
}

/// Máy trạng thái linh vật: Cảm xúc × Thời tiết × Khung giờ (mục 2.3).
public enum MascotEngine {
    public static func resolve(
        species: MascotSpecies,
        mood: Mood?,
        weather: WeatherSnapshot?,
        date: Date,
        calendar: Calendar = .cozy
    ) -> MascotState {
        let part = DayPart(date: date, calendar: calendar)

        // 1. Khuya sau 22:30: luôn trùm chăn ngủ (ưu tiên cao nhất).
        if part == .lateNight {
            return MascotState(
                species: species, pose: .sleeping, accessories: [.blanket],
                caption: "\(species.displayName) trùm chăn ngủ rồi… 💤",
                assetName: "\(species.rawValue)_sleeping_blanket"
            )
        }

        // 2. Phụ kiện thời tiết.
        var accessories: [MascotAccessory] = []
        var weatherNote: String?
        if let weather {
            if weather.condition.isWet {
                accessories.append(.umbrella)
                weatherNote = "cầm ô đi mưa"
            } else if weather.isCold {
                accessories.append(.scarf)
                weatherNote = "quàng khăn len"
            } else if weather.isSunny {
                accessories.append(.sunglasses)
                weatherNote = "đeo kính râm"
            }
        }

        // 3. Phụ kiện khung giờ (nếu còn chỗ và không trùng ý nghĩa).
        let timeAccessory: MascotAccessory
        let timeNote: String
        switch part {
        case .morning: timeAccessory = .coffee; timeNote = "uống cà phê"
        case .afternoon: timeAccessory = calendar.component(.hour, from: date) < 14 ? .riceBowl : .book
            timeNote = timeAccessory == .riceBowl ? "ăn cơm" : "đọc sách"
        case .evening: timeAccessory = .book; timeNote = "đọc sách"
        case .lateNight: timeAccessory = .blanket; timeNote = "ngủ"
        }

        // Nắng + chiều: đổi sang trà sữa cho đúng vibe.
        let finalTimeAccessory: MascotAccessory = (weather?.isSunny == true && part == .afternoon) ? .milkTea : timeAccessory
        accessories.append(finalTimeAccessory)

        // 4. Tư thế theo cảm xúc.
        let pose: MascotPose
        switch mood {
        case .happy?: pose = .bouncing
        case .chill?: pose = .lounging
        case .sleepy?: pose = .yawning
        case .excited?: pose = .jumping
        case .tired?: pose = .slumped
        case .missing?: pose = .hugging
            if !accessories.contains(.heart) { accessories = [accessories.first ?? .heart, .heart] }
        case .busy?: pose = .rushing
            if accessories.count > 1 { accessories[accessories.count - 1] = .laptop }
        case nil: pose = .lounging
        }

        var unique: [MascotAccessory] = []
        for a in accessories where a != .none && !unique.contains(a) && unique.count < 2 {
            unique.append(a)
        }
        let activity = [weatherNote, finalTimeAccessory == .milkTea ? "cầm trà sữa" : timeNote].compactMap { $0 }.joined(separator: ", ")
        let moodText = mood.map { " · \($0.displayName.lowercased())" } ?? ""
        return MascotState(
            species: species,
            pose: pose,
            accessories: unique,
            caption: "\(species.displayName) đang \(activity)\(moodText)",
            assetName: ([species.rawValue, pose.rawValue] + unique.map(\.rawValue)).joined(separator: "_")
        )
    }
}
