import Foundation

public enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case clear, partlyCloudy, cloudy, rain, thunderstorm, drizzle, fog, snow, windy, hot

    public var displayName: String {
        switch self {
        case .clear: return "Trời quang"
        case .partlyCloudy: return "Ít mây"
        case .cloudy: return "Nhiều mây"
        case .rain: return "Mưa"
        case .thunderstorm: return "Dông"
        case .drizzle: return "Mưa phùn"
        case .fog: return "Sương mù"
        case .snow: return "Tuyết"
        case .windy: return "Gió mạnh"
        case .hot: return "Nắng nóng"
        }
    }

    public var symbolName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .fog: return "cloud.fog.fill"
        case .snow: return "snowflake"
        case .windy: return "wind"
        case .hot: return "thermometer.sun.fill"
        }
    }

    public var isWet: Bool { [.rain, .thunderstorm, .drizzle].contains(self) }
}

/// Ảnh chụp thời tiết đã cache trong App Group để Widget đọc lại (không tốn thêm quota).
public struct WeatherSnapshot: Codable, Hashable, Sendable {
    public var temperatureC: Double
    public var apparentC: Double
    public var condition: WeatherCondition
    public var humidity: Double
    public var highC: Double
    public var lowC: Double
    public var placeName: String
    public var regionKey: String
    public var fetchedAt: Date

    public init(
        temperatureC: Double, apparentC: Double, condition: WeatherCondition,
        humidity: Double = 0.7, highC: Double, lowC: Double,
        placeName: String, regionKey: String, fetchedAt: Date
    ) {
        self.temperatureC = temperatureC
        self.apparentC = apparentC
        self.condition = condition
        self.humidity = humidity
        self.highC = highC
        self.lowC = lowC
        self.placeName = placeName
        self.regionKey = regionKey
        self.fetchedAt = fetchedAt
    }

    public var isCold: Bool { apparentC < 18 }
    public var isHot: Bool { apparentC >= 33 || condition == .hot }
    public var isSunny: Bool { condition == .clear || condition == .hot || condition == .partlyCloudy }

    public var temperatureText: String { "\(Int(temperatureC.rounded()))°" }
}
