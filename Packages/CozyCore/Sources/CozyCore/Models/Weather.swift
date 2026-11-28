import Foundation

public enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case clear, partlyCloudy, cloudy, rain, thunderstorm, drizzle, fog, snow, windy, hot

    public var displayName: String {
        CozyL10n.t("weather.\(rawValue)")
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

/// Tùy chọn khu vực lấy thời tiết thật (GPS tự động hoặc chọn nhanh thành phố).
public enum WeatherLocationPreset: String, Codable, CaseIterable, Sendable, Identifiable {
    case autoGPS
    case hanoi
    case hcmc
    case danang
    case dalat
    case hue
    case cantho
    case nhatrang
    case haiphong

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .autoGPS: return "Tự động (GPS)"
        case .hanoi: return "Hà Nội"
        case .hcmc: return "TP. Hồ Chí Minh"
        case .danang: return "Đà Nẵng"
        case .dalat: return "Đà Lạt"
        case .hue: return "Huế"
        case .cantho: return "Cần Thơ"
        case .nhatrang: return "Nha Trang"
        case .haiphong: return "Hải Phòng"
        }
    }

    public var shortName: String {
        switch self {
        case .hcmc: return "TP.HCM"
        default: return displayName
        }
    }

    /// Tọa độ chuẩn (dùng khi chọn thành phố hoặc làm điểm dự phòng khi GPS chưa bật).
    public var coordinates: (latitude: Double, longitude: Double) {
        switch self {
        case .autoGPS, .hcmc: return (10.7769, 106.7009)
        case .hanoi: return (21.0285, 105.8542)
        case .danang: return (16.0544, 108.2022)
        case .dalat: return (11.9404, 108.4583)
        case .hue: return (16.4637, 107.5909)
        case .cantho: return (10.0452, 105.7469)
        case .nhatrang: return (12.2388, 109.1967)
        case .haiphong: return (20.8449, 106.6881)
        }
    }
}
