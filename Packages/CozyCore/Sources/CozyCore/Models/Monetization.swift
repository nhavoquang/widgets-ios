import Foundation

/// Cấu hình sản phẩm In-App Purchase (StoreKit 2) & danh sách hành động mở nhanh (Quick Launcher) trên Lock Screen.
public enum ProPlanKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case yearly = "com.cozydaily.app.pro.yearly"
    case lifetime = "com.cozydaily.app.pro.lifetime"

    public var id: String { rawValue }

    /// Giá hiển thị dự phòng trước khi StoreKit tải xong giá thật từ App Store Connect từng quốc gia.
    /// Việt Nam: 69.000₫/năm & 139.000₫ Trọn đời (theo đúng chiến lược giá mục tiêu).
    /// Quốc tế: $9.99/yr & $24.99 Lifetime.
    public func fallbackDisplayPrice(for lang: AppLanguage = CozyL10n.effective) -> String {
        let isVN = (lang.resolved == .vi)
        switch self {
        case .yearly:
            return isVN ? "69.000₫" : "$9.99"
        case .lifetime:
            return isVN ? "139.000₫" : "$24.99"
        }
    }

    public func fallbackOriginalPrice(for lang: AppLanguage = CozyL10n.effective) -> String {
        let isVN = (lang.resolved == .vi)
        switch self {
        case .yearly:
            return isVN ? "149.000₫" : "$19.99"
        case .lifetime:
            return isVN ? "299.000₫" : "$49.99"
        }
    }
}

/// Một ô mở nhanh (Quick Launcher) trên dải Lock Screen dưới đồng hồ.
public enum QuickLaunchPreset: String, Codable, CaseIterable, Sendable, Identifiable {
    case addTask
    case lockStudio
    case calendarApp
    case remindersApp
    case spotify
    case chatgpt
    case googleMaps
    case customURL

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .addTask: return CozyL10n.t("launcher.addTask")
        case .lockStudio: return "Lock Studio"
        case .calendarApp: return CozyL10n.t("tab.calendar")
        case .remindersApp: return "Reminders"
        case .spotify: return "Spotify"
        case .chatgpt: return "ChatGPT"
        case .googleMaps: return "Maps"
        case .customURL: return CozyL10n.t("launcher.custom")
        }
    }

    public var symbolName: String {
        switch self {
        case .addTask: return "plus.circle.fill"
        case .lockStudio: return "iphone.gen3"
        case .calendarApp: return "calendar"
        case .remindersApp: return "checklist"
        case .spotify: return "music.note"
        case .chatgpt: return "sparkles"
        case .googleMaps: return "location.fill"
        case .customURL: return "qrcode.viewfinder"
        }
    }

    public var defaultURLString: String {
        switch self {
        case .addTask: return "cozydaily://open?tab=today"
        case .lockStudio: return "cozydaily://open?tab=studio"
        case .calendarApp: return "calshow://"
        case .remindersApp: return "x-apple-reminderkit://"
        case .spotify: return "spotify://"
        case .chatgpt: return "chatgpt://"
        case .googleMaps: return "comgooglemaps://"
        case .customURL: return "cozydaily://open?tab=today"
        }
    }
}
