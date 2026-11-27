import Foundation

/// Màu dạng RGBA thuần, dùng chung cho App và Widget (không phụ thuộc SwiftUI).
public struct RGBA: Codable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Khởi tạo từ chuỗi HEX dạng `#RRGGBB` hoặc `RRGGBB` (có thể kèm `AA`).
    public init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let value = UInt64(s, radix: 16) else { return nil }
        if s.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        } else {
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        }
    }

    public var hexString: String {
        func c(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", c(red), c(green), c(blue))
    }

    public func withAlpha(_ a: Double) -> RGBA { RGBA(red: red, green: green, blue: blue, alpha: a) }
}

/// Bảng màu chuẩn của CozyDaily (mục 2.1 đặc tả).
public enum ColorToken: String, Codable, CaseIterable, Sendable {
    case bgCream
    case cardIvory
    case cardBorder
    case inkCoffee
    case inkTaupe
    case accentSage
    case accentPeach
    case accentHoney
    case accentSky

    public var hex: String {
        switch self {
        case .bgCream: return "#F7F4EE"
        case .cardIvory: return "#FFFDF9"
        case .cardBorder: return "#EBE4D8"
        case .inkCoffee: return "#3D352E"
        case .inkTaupe: return "#8C8278"
        case .accentSage: return "#7FA98E"
        case .accentPeach: return "#E8927C"
        case .accentHoney: return "#E6B85C"
        case .accentSky: return "#7BA7CC"
        }
    }

    /// Bản tối (Dark/Night) dùng cho Smart Auto-Theme.
    public var darkHex: String {
        switch self {
        case .bgCream: return "#1F1B17"
        case .cardIvory: return "#2A251F"
        case .cardBorder: return "#3A332B"
        case .inkCoffee: return "#F3EDE4"
        case .inkTaupe: return "#B3A89C"
        case .accentSage: return "#93BFA2"
        case .accentPeach: return "#F0A48F"
        case .accentHoney: return "#EDC676"
        case .accentSky: return "#94BADB"
        }
    }

    public var rgba: RGBA { RGBA(hex: hex)! }
    public var darkRGBA: RGBA { RGBA(hex: darkHex)! }

    public static var accents: [ColorToken] { [.accentSage, .accentPeach, .accentHoney, .accentSky] }

    public var displayName: String {
        switch self {
        case .bgCream: return "Kem giấy"
        case .cardIvory: return "Ngà"
        case .cardBorder: return "Viền"
        case .inkCoffee: return "Cà phê"
        case .inkTaupe: return "Nâu xám"
        case .accentSage: return "Xanh xô thơm"
        case .accentPeach: return "Đào"
        case .accentHoney: return "Mật ong"
        case .accentSky: return "Bầu trời"
        }
    }
}

public enum CozyMetrics {
    public static let cardCornerRadius: Double = 24
    public static let cardBorderWidth: Double = 1
    public static let noteMaxLength = 30
}
