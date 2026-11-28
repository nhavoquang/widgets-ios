import Foundation

/// Chính sách cache WeatherKit để giữ dưới quota 500k calls/tháng (mục 3.3).
///
/// - Làm tròn tọa độ tới 0.01° (~1.1 km) để gom các lần fetch trong cùng vùng.
/// - Chỉ fetch lại khi đổi vùng hoặc cache quá `maxAge` (mặc định 45 phút, trong khoảng 30–60).
/// - Chỉ Main App gọi WeatherKit; Widget luôn đọc snapshot từ App Group.
public struct WeatherCachePolicy: Sendable {
    public var gridSize: Double
    public var maxAge: TimeInterval
    public var minAge: TimeInterval

    public init(gridSize: Double = 0.01, maxAge: TimeInterval = 45 * 60, minAge: TimeInterval = 30 * 60) {
        self.gridSize = gridSize
        self.maxAge = maxAge
        self.minAge = minAge
    }

    public func regionKey(latitude: Double, longitude: Double) -> String {
        let lat = (latitude / gridSize).rounded() * gridSize
        let lon = (longitude / gridSize).rounded() * gridSize
        return String(format: "%.2f,%.2f", lat, lon)
    }

    public enum Decision: Equatable, Sendable {
        case useCache
        case fetch(reason: String)
    }

    /// Quyết định có cần gọi WeatherKit không.
    /// - Parameter force: người dùng kéo để làm mới. Vẫn tôn trọng `minAge` để tránh spam.
    public func decide(cached: WeatherSnapshot?, latitude: Double, longitude: Double, now: Date, force: Bool = false) -> Decision {
        guard let cached else { return .fetch(reason: "chưa có cache") }
        let age = now.timeIntervalSince(cached.fetchedAt)
        let key = regionKey(latitude: latitude, longitude: longitude)
        if cached.regionKey != key { return .fetch(reason: "đổi khu vực") }
        if age < 0 { return .fetch(reason: "đồng hồ thay đổi") }
        if force && age >= minAge { return .fetch(reason: "làm mới thủ công") }
        if age >= maxAge { return .fetch(reason: "cache hết hạn") }
        return .useCache
    }

    /// Ước tính số call/tháng cho N người dùng hoạt động, mỗi người mở app `opensPerDay` lần.
    /// Với cache 45 phút, tối đa ~32 call/ngày/người dù mở app liên tục.
    public func estimatedMonthlyCalls(activeUsers: Int, opensPerDay: Int) -> Int {
        let maxPerDay = Int((24 * 3600) / maxAge)
        return activeUsers * min(opensPerDay, maxPerDay) * 30
    }
}

/// Gợi ý theo ngữ cảnh thời tiết: món ăn, trang phục, câu chào.
public enum WeatherSuggestion {
    public static func foods(for w: WeatherSnapshot) -> [FoodSticker] {
        if w.condition.isWet { return [.hotpot, .pho, .coffee] }
        if w.isCold { return [.hotpot, .bunBo, .pho] }
        if w.isHot { return [.milkTea, .salad, .dessert] }
        return [.comTam, .banhMi, .milkTea]
    }

    public static func outfit(for w: WeatherSnapshot) -> String {
        if w.condition.isWet { return "Nhớ mang ô và áo mưa nha ☔️" }
        if w.isCold { return "Quàng khăn len, mặc ấm vào nè 🧣" }
        if w.isHot { return "Kem chống nắng + kính râm, uống nhiều nước 🕶️" }
        return "Thời tiết dễ chịu, mặc gì cũng xinh ✨"
    }

    public static func greeting(for w: WeatherSnapshot) -> String {
        "\(w.placeName) \(w.temperatureText), \(w.condition.displayName.lowercased())"
    }

    /// Chuỗi ngắn để chia sẻ thời tiết cho người yêu/nhóm bạn.
    public static func shareLine(for w: WeatherSnapshot) -> String {
        "\(w.condition.displayName) \(w.temperatureText) ở \(w.placeName)"
    }
}

public extension WeatherCondition {
    /// Ánh xạ mã thời tiết WMO chuẩn quốc tế (dùng bởi Open-Meteo) sang `WeatherCondition`.
    static func fromWMOCode(_ code: Int, temperatureC: Double = 25) -> WeatherCondition {
        switch code {
        case 0:
            return temperatureC >= 35 ? .hot : .clear
        case 1, 2:
            return temperatureC >= 35 ? .hot : .partlyCloudy
        case 3:
            return .cloudy
        case 45, 48:
            return .fog
        case 51, 53, 55, 56, 57:
            return .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return .rain
        case 71, 73, 75, 77, 85, 86:
            return .snow
        case 95, 96, 99:
            return .thunderstorm
        default:
            return .cloudy
        }
    }
}
