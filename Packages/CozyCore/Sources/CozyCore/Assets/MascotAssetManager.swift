import Foundation

/// Tên gọi thống nhất cho trạng thái cảm xúc (dùng chung App và Widget).
public typealias MascotMood = Mood

/// Bộ tài nguyên của một trạng thái, cho từng bề mặt hiển thị.
public struct CozyAsset: Hashable, Sendable {
    /// Tên file Rive (`.riv`) hoặc Lottie (`.json`), không kèm đuôi. Dùng trong Main App.
    public let animationResourceName: String
    /// PNG 3D nền trong suốt trong asset catalog. Dùng cho Home Screen Widget (full color).
    public let staticFullColorImageName: String
    /// Ảnh template (nét tách bạch) cho chế độ Tinted/Vibrant, nếu có trong asset catalog.
    public let tintedImageName: String
    /// SF Symbol dự phòng cho Lock Screen khi chưa có `tintedImageName`.
    public let monochromeSymbolName: String
    /// Emoji giữ chỗ khi chưa có minh họa.
    public let fallbackEmoji: String
    /// Mô tả cho VoiceOver.
    public let accessibilityName: String

    public init(key: String, symbol: String, emoji: String, name: String) {
        self.animationResourceName = "anim_\(key)"
        self.staticFullColorImageName = "img_\(key)"
        self.tintedImageName = "tint_\(key)"
        self.monochromeSymbolName = symbol
        self.fallbackEmoji = emoji
        self.accessibilityName = name
    }
}

/// Mọi trạng thái có hình đại diện đều tuân theo giao thức này.
public protocol CozyAssetState: Sendable {
    var asset: CozyAsset { get }
}

extension Mood {
    public var monochromeSymbolName: String {
        switch self {
        case .happy: return "face.smiling.inverse"
        case .chill: return "leaf.fill"
        case .sleepy: return "moon.zzz.fill"
        case .excited: return "sparkles"
        case .tired: return "bed.double.fill"
        case .missing: return "heart.fill"
        case .busy: return "figure.run"
        }
    }
}

extension Mood: CozyAssetState {
    /// Tài nguyên mood chưa gắn loài (dùng cho sticker cảm xúc).
    public var asset: CozyAsset {
        CozyAsset(key: "mood_\(rawValue)", symbol: monochromeSymbolName, emoji: emoji, name: displayName)
    }
}

extension FoodSticker: CozyAssetState {
    public var monochromeSymbolName: String {
        switch self {
        case .pho, .bunBo, .noodles, .hotpot: return "frying.pan.fill"
        case .comTam, .sushi, .salad: return "fork.knife"
        case .banhMi, .pizza: return "takeoutbag.and.cup.and.straw.fill"
        case .milkTea, .coffee: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        }
    }

    public var asset: CozyAsset {
        CozyAsset(key: "food_\(rawValue)", symbol: monochromeSymbolName, emoji: emoji, name: displayName)
    }
}

extension WeatherCondition: CozyAssetState {
    public var emoji: String {
        switch self {
        case .clear: return "☀️"
        case .partlyCloudy: return "⛅️"
        case .cloudy: return "☁️"
        case .rain: return "🌧️"
        case .thunderstorm: return "⛈️"
        case .drizzle: return "🌦️"
        case .fog: return "🌫️"
        case .snow: return "❄️"
        case .windy: return "💨"
        case .hot: return "🥵"
        }
    }

    public var asset: CozyAsset {
        CozyAsset(key: "weather_\(rawValue)", symbol: symbolName, emoji: emoji, name: displayName)
    }
}

extension MascotState: CozyAssetState {
    /// Linh vật theo loài + tư thế, vd. `img_mascot_cat_sleeping`.
    public var asset: CozyAsset {
        CozyAsset(
            key: "mascot_\(species.rawValue)_\(pose.rawValue)",
            symbol: pose.symbolName,
            emoji: species.emoji,
            name: caption
        )
    }
}

/// Registry duy nhất ánh xạ trạng thái → tài nguyên, dùng chung giữa App và Widget Extension.
public enum MascotAssetManager {
    public static func asset(for state: some CozyAssetState) -> CozyAsset { state.asset }

    /// Tên tài nguyên thử lần lượt: cụ thể (loài + tư thế) trước, rồi tới bản chung của loài.
    public static func candidates(for state: MascotState) -> [CozyAsset] {
        [
            state.asset,
            CozyAsset(key: "mascot_\(state.species.rawValue)", symbol: "pawprint.fill", emoji: state.species.emoji, name: state.caption),
        ]
    }

    /// Toàn bộ tài nguyên mà bộ minh họa cần cung cấp (dùng để lập danh sách cho họa sĩ).
    public static var allAssets: [CozyAsset] {
        let poses: [MascotPose] = [.bouncing, .lounging, .yawning, .jumping, .slumped, .hugging, .rushing, .sleeping]
        let mascots = MascotSpecies.allCases.flatMap { species in
            poses.map { pose in
                CozyAsset(key: "mascot_\(species.rawValue)_\(pose.rawValue)", symbol: pose.symbolName, emoji: species.emoji, name: species.displayName)
            }
        }
        return mascots + Mood.allCases.map(\.asset) + FoodSticker.allCases.map(\.asset) + WeatherCondition.allCases.map(\.asset)
    }
}
