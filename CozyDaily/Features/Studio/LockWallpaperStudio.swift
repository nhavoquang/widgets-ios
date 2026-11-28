import SwiftUI
import PhotosUI
import UIKit
import AppIntents
import UniformTypeIdentifiers
import CozyCore

// MARK: - Bento Multi-Column Lock Screen Blocks, Backgrounds, Styles & 16 Modern Templates

enum LockBlockKind: String, CaseIterable, Identifiable, Codable, Transferable {
    case weekStrip
    case todaySchedule
    case weather
    case vocab
    case partner
    case monthGrid
    case eventCountdown
    case yearProgress
    case habitStreak
    case lunarCard
    case stickyNote
    case batteryCard

    var id: String { rawValue }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }

    var title: String {
        CozyL10n.t("block.\(rawValue)")
    }

    var symbol: String {
        switch self {
        case .weekStrip: return "calendar.day.timeline.left"
        case .todaySchedule: return "checklist"
        case .weather: return "cloud.sun.fill"
        case .vocab: return "character.book.closed.fill"
        case .partner: return "heart.fill"
        case .monthGrid: return "calendar"
        case .eventCountdown: return "hourglass"
        case .yearProgress: return "chart.bar.fill"
        case .habitStreak: return "flame.fill"
        case .lunarCard: return "moon.stars.fill"
        case .stickyNote: return "note.text"
        case .batteryCard: return "battery.100percent.bolt"
        }
    }

    var accent: Color {
        switch self {
        case .weekStrip, .todaySchedule, .weather: return .accentSky
        case .vocab, .habitStreak, .batteryCard: return .accentSage
        case .partner, .eventCountdown: return .accentPeach
        case .monthGrid, .yearProgress, .lunarCard, .stickyNote: return .accentHoney
        }
    }

    /// Độ rộng mặc định trên lưới 12 đơn vị: 12 = 1 cột, 6 = 1/2 hàng (2 cột), 4 = 1/3 hàng (3 cột), 3 = 1/4 hàng (4 cột).
    var defaultSpanTwelfths: Int {
        switch self {
        case .weekStrip, .todaySchedule, .monthGrid:
            return 12
        case .weather, .vocab, .partner, .eventCountdown, .yearProgress, .habitStreak, .stickyNote:
            return 6
        case .lunarCard, .batteryCard:
            return 4
        }
    }
}

/// Một ô thành phần trên lưới Bento 12 đơn vị:
/// - `spanTwelfths = 12` → Full hàng (1 cột)
/// - `spanTwelfths = 6`  → Nửa hàng (chia 2 cột)
/// - `spanTwelfths = 4`  → 1/3 hàng (chia 3 cột)
/// - `spanTwelfths = 3`  → 1/4 hàng (chia 4 cột)
struct LockBlockPlacement: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var kind: LockBlockKind
    var spanTwelfths: Int

    init(id: UUID = UUID(), kind: LockBlockKind, spanTwelfths: Int? = nil) {
        self.id = id
        self.kind = kind
        let raw = spanTwelfths ?? kind.defaultSpanTwelfths
        self.spanTwelfths = [12, 6, 4, 3].contains(raw) ? raw : 12
    }

    var columnLabel: String {
        switch spanTwelfths {
        case 12: return "1 cột"
        case 6: return "1/2"
        case 4: return "1/3"
        case 3: return "1/4"
        default: return "1 cột"
        }
    }

    mutating func cycleSpan() {
        switch spanTwelfths {
        case 12: spanTwelfths = 6
        case 6: spanTwelfths = 4
        case 4: spanTwelfths = 3
        default: spanTwelfths = 12
        }
    }
}

enum LockWallpaperBg: String, CaseIterable, Identifiable, Codable {
    case pureDark
    case midnightBlue
    case obsidianNeon
    case sunsetDusk
    case forestTeal
    case amethystNight
    case cleanLight
    case crystalSlate
    case roseCharcoal
    case deepIndigo
    case warmEspresso
    case arcticMist
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pureDark: return "Đen tối giản"
        case .midnightBlue: return "Xanh đêm"
        case .obsidianNeon: return "Đen viền sáng"
        case .sunsetDusk: return "Hoàng hôn"
        case .forestTeal: return "Rừng xanh"
        case .amethystNight: return "Tím đêm"
        case .cleanLight: return "Sáng tối giản"
        case .crystalSlate: return "Xám pha lê"
        case .roseCharcoal: return "Hồng đêm"
        case .deepIndigo: return "Chàm sâu"
        case .warmEspresso: return "Nâu trầm"
        case .arcticMist: return "Xanh băng"
        case .photo: return "Ảnh của bạn"
        }
    }

    var isLight: Bool { self == .cleanLight || self == .arcticMist }

    var previewColors: [Color] {
        switch self {
        case .pureDark: return [Color(RGBA(hex: "#121316")!), Color(RGBA(hex: "#1B1D24")!)]
        case .midnightBlue: return [Color(RGBA(hex: "#0B132B")!), Color(RGBA(hex: "#1C2541")!)]
        case .obsidianNeon: return [Color(RGBA(hex: "#080A0F")!), Color(RGBA(hex: "#111827")!)]
        case .sunsetDusk: return [Color(RGBA(hex: "#1E1B2E")!), Color(RGBA(hex: "#5C3D52")!), Color(RGBA(hex: "#1E2029")!)]
        case .forestTeal: return [Color(RGBA(hex: "#0A1F1F")!), Color(RGBA(hex: "#133A36")!)]
        case .amethystNight: return [Color(RGBA(hex: "#191024")!), Color(RGBA(hex: "#311D47")!)]
        case .cleanLight: return [Color(RGBA(hex: "#F4F6FA")!), Color(RGBA(hex: "#E5EAF2")!)]
        case .crystalSlate: return [Color(RGBA(hex: "#171A21")!), Color(RGBA(hex: "#252A36")!)]
        case .roseCharcoal: return [Color(RGBA(hex: "#1C1317")!), Color(RGBA(hex: "#381E29")!)]
        case .deepIndigo: return [Color(RGBA(hex: "#0F172A")!), Color(RGBA(hex: "#1E293B")!)]
        case .warmEspresso: return [Color(RGBA(hex: "#1C1613")!), Color(RGBA(hex: "#2E231E")!)]
        case .arcticMist: return [Color(RGBA(hex: "#EAF2F8")!), Color(RGBA(hex: "#D6E6F2")!)]
        case .photo: return [Color(RGBA(hex: "#2B2D36")!), Color(RGBA(hex: "#181A20")!)]
        }
    }
}

enum LockCardStyle: String, CaseIterable, Identifiable, Codable {
    case none
    case frostedGlass
    case solidSoft
    case glowingBorder
    case hairlineOutline
    case dashedOutline

    var id: String { rawValue }

    var title: String {
        CozyL10n.t("style.\(rawValue)")
    }
}

struct LockLayoutConfig: Equatable, Codable {
    var items: [LockBlockPlacement]
    var bg: LockWallpaperBg = .pureDark
    var cardStyle: LockCardStyle = .frostedGlass
    var cornerRadius: CGFloat = 18
    var gridSpacing: CGFloat = 10
    var cardOpacity: CGFloat = 1.0
    var fontScale: CGFloat = 1.0
    var verticalOffset: CGFloat = 0
    var stickyNoteText: String = "Tập trung mục tiêu quan trọng nhất hôm nay!"
    /// Đánh dấu user đã tự chỉnh danh sách/cột để khi chọn mẫu mới không bị mất bố cục đã xếp.
    var userEditedBlocks: Bool = false
    /// Đánh dấu user đã cài đặt Shortcut tự động (chỉ hỏi cài 1 lần duy nhất).
    var shortcutInstalled: Bool = false

    private static let storageKey = "cozy.lockLayoutConfig.v3"

    enum CodingKeys: String, CodingKey {
        case items, blocks, bg, cardStyle, cornerRadius, gridSpacing, cardOpacity, fontScale, verticalOffset, stickyNoteText, userEditedBlocks, shortcutInstalled
    }

    init(
        items: [LockBlockPlacement] = [
            LockBlockPlacement(kind: .weekStrip, spanTwelfths: 12),
            LockBlockPlacement(kind: .weather, spanTwelfths: 6),
            LockBlockPlacement(kind: .vocab, spanTwelfths: 6),
            LockBlockPlacement(kind: .todaySchedule, spanTwelfths: 12),
        ],
        bg: LockWallpaperBg = .pureDark,
        cardStyle: LockCardStyle = .frostedGlass,
        cornerRadius: CGFloat = 18,
        gridSpacing: CGFloat = 10,
        cardOpacity: CGFloat = 1.0,
        fontScale: CGFloat = 1.0,
        verticalOffset: CGFloat = 0,
        stickyNoteText: String = "Tập trung mục tiêu quan trọng nhất hôm nay!",
        userEditedBlocks: Bool = false,
        shortcutInstalled: Bool = false
    ) {
        self.items = items
        self.bg = bg
        self.cardStyle = cardStyle
        self.cornerRadius = cornerRadius
        self.gridSpacing = gridSpacing
        self.cardOpacity = cardOpacity
        self.fontScale = fontScale
        self.verticalOffset = verticalOffset
        self.stickyNoteText = stickyNoteText
        self.userEditedBlocks = userEditedBlocks
        self.shortcutInstalled = shortcutInstalled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedItems = try c.decodeIfPresent([LockBlockPlacement].self, forKey: .items), !decodedItems.isEmpty {
            items = decodedItems
        } else if let legacyBlocks = try c.decodeIfPresent([LockBlockKind].self, forKey: .blocks), !legacyBlocks.isEmpty {
            items = legacyBlocks.map { LockBlockPlacement(kind: $0, spanTwelfths: 12) }
        } else {
            items = [
                LockBlockPlacement(kind: .weekStrip, spanTwelfths: 12),
                LockBlockPlacement(kind: .weather, spanTwelfths: 6),
                LockBlockPlacement(kind: .vocab, spanTwelfths: 6),
                LockBlockPlacement(kind: .todaySchedule, spanTwelfths: 12),
            ]
        }
        bg = try c.decodeIfPresent(LockWallpaperBg.self, forKey: .bg) ?? .pureDark
        cardStyle = try c.decodeIfPresent(LockCardStyle.self, forKey: .cardStyle) ?? .frostedGlass
        cornerRadius = try c.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? 18
        gridSpacing = try c.decodeIfPresent(CGFloat.self, forKey: .gridSpacing) ?? 10
        cardOpacity = try c.decodeIfPresent(CGFloat.self, forKey: .cardOpacity) ?? 1.0
        fontScale = try c.decodeIfPresent(CGFloat.self, forKey: .fontScale) ?? 1.0
        verticalOffset = try c.decodeIfPresent(CGFloat.self, forKey: .verticalOffset) ?? 0
        stickyNoteText = try c.decodeIfPresent(String.self, forKey: .stickyNoteText) ?? "Tập trung mục tiêu quan trọng nhất hôm nay!"
        userEditedBlocks = try c.decodeIfPresent(Bool.self, forKey: .userEditedBlocks) ?? false
        shortcutInstalled = try c.decodeIfPresent(Bool.self, forKey: .shortcutInstalled) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(items, forKey: .items)
        try c.encode(bg, forKey: .bg)
        try c.encode(cardStyle, forKey: .cardStyle)
        try c.encode(cornerRadius, forKey: .cornerRadius)
        try c.encode(gridSpacing, forKey: .gridSpacing)
        try c.encode(cardOpacity, forKey: .cardOpacity)
        try c.encode(fontScale, forKey: .fontScale)
        try c.encode(verticalOffset, forKey: .verticalOffset)
        try c.encode(stickyNoteText, forKey: .stickyNoteText)
        try c.encode(userEditedBlocks, forKey: .userEditedBlocks)
        try c.encode(shortcutInstalled, forKey: .shortcutInstalled)
    }

    /// Chia các khối thành từng hàng dựa trên tổng 12 đơn vị mỗi hàng (hỗ trợ 1, 2, 3, 4 cột trên cùng hàng).
    var packedRows: [[LockBlockPlacement]] {
        var rows: [[LockBlockPlacement]] = []
        var current: [LockBlockPlacement] = []
        var sum = 0
        for item in items {
            let s = min(max(item.spanTwelfths, 3), 12)
            if sum + s > 12 && !current.isEmpty {
                rows.append(current)
                current = [item]
                sum = s
            } else {
                current.append(item)
                sum += s
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    private static var sharedDefaults: UserDefaults {
        if let group = SnapshotStore.activeAppGroupID, let d = UserDefaults(suiteName: group) {
            return d
        }
        return .standard
    }

    static var customPhotoURL: URL {
        SnapshotStore.shared().fileURL.deletingLastPathComponent().appendingPathComponent("lock-custom-bg.jpg")
    }

    static func load() -> LockLayoutConfig {
        guard let data = sharedDefaults.data(forKey: storageKey),
              let cfg = try? JSONDecoder().decode(LockLayoutConfig.self, from: data) else {
            return LockLayoutConfig()
        }
        return cfg
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            Self.sharedDefaults.set(data, forKey: Self.storageKey)
        }
    }

    static func loadCustomPhoto() -> UIImage? {
        guard let data = try? Data(contentsOf: customPhotoURL) else { return nil }
        return UIImage(data: data)
    }

    static func saveCustomPhoto(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.88) {
            try? data.write(to: customPhotoURL, options: [.atomic])
        }
    }
}

/// 16 mẫu Lock Screen Bento đa cột hiện đại (1 cột, 2 cột, 3 cột, 4 cột).
struct LockTemplatePreset: Identifiable {
    let id: String
    let name: String
    let badge: String
    let accent: Color
    let config: LockLayoutConfig

    static let all: [LockTemplatePreset] = [
        LockTemplatePreset(
            id: "bento-2col", name: "Bento 2 Cột", badge: "Widgy Style", accent: .accentSky,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weekStrip, spanTwelfths: 12),
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .vocab, spanTwelfths: 6),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                ],
                bg: .midnightBlue, cardStyle: .frostedGlass, cornerRadius: 20
            )
        ),
        LockTemplatePreset(
            id: "pro-3col", name: "Dashboard 3 Cột", badge: "Hiện đại", accent: .accentSage,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weather, spanTwelfths: 4),
                    .init(kind: .lunarCard, spanTwelfths: 4),
                    .init(kind: .batteryCard, spanTwelfths: 4),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                    .init(kind: .vocab, spanTwelfths: 6),
                    .init(kind: .eventCountdown, spanTwelfths: 6),
                ],
                bg: .obsidianNeon, cardStyle: .glowingBorder, cornerRadius: 18
            )
        ),
        LockTemplatePreset(
            id: "mini-4col", name: "4 Cột Compact", badge: "4 ô ngang", accent: .accentHoney,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weather, spanTwelfths: 3),
                    .init(kind: .lunarCard, spanTwelfths: 3),
                    .init(kind: .habitStreak, spanTwelfths: 3),
                    .init(kind: .batteryCard, spanTwelfths: 3),
                    .init(kind: .monthGrid, spanTwelfths: 12),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                ],
                bg: .deepIndigo, cardStyle: .solidSoft, cornerRadius: 16
            )
        ),
        LockTemplatePreset(
            id: "minimal-dark", name: "Tối giản Locka", badge: "Không nền", accent: .accentHoney,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weekStrip, spanTwelfths: 12),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                    .init(kind: .habitStreak, spanTwelfths: 6),
                    .init(kind: .yearProgress, spanTwelfths: 6),
                ],
                bg: .pureDark, cardStyle: .none, cornerRadius: 14
            )
        ),
        LockTemplatePreset(
            id: "calendar-split", name: "Lịch + Đôi 2 Cột", badge: "Cân đối", accent: .accentPeach,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .monthGrid, spanTwelfths: 12),
                    .init(kind: .partner, spanTwelfths: 6),
                    .init(kind: .weather, spanTwelfths: 6),
                ],
                bg: .roseCharcoal, cardStyle: .frostedGlass, cornerRadius: 22
            )
        ),
        LockTemplatePreset(
            id: "study-bento", name: "Học tập 2×2", badge: "Từ vựng", accent: .accentSage,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .vocab, spanTwelfths: 12),
                    .init(kind: .habitStreak, spanTwelfths: 6),
                    .init(kind: .yearProgress, spanTwelfths: 6),
                    .init(kind: .stickyNote, spanTwelfths: 6),
                    .init(kind: .weather, spanTwelfths: 6),
                ],
                bg: .forestTeal, cardStyle: .frostedGlass, cornerRadius: 20
            )
        ),
        LockTemplatePreset(
            id: "clean-light", name: "Sáng Bento", badge: "Light Mode", accent: .accentSky,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weekStrip, spanTwelfths: 12),
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .eventCountdown, spanTwelfths: 6),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                ],
                bg: .cleanLight, cardStyle: .solidSoft, cornerRadius: 20
            )
        ),
        LockTemplatePreset(
            id: "arctic-3col", name: "Băng sáng 3 Cột", badge: "Tinh khiết", accent: .accentSky,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weather, spanTwelfths: 4),
                    .init(kind: .lunarCard, spanTwelfths: 4),
                    .init(kind: .yearProgress, spanTwelfths: 4),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                    .init(kind: .vocab, spanTwelfths: 12),
                ],
                bg: .arcticMist, cardStyle: .solidSoft, cornerRadius: 22
            )
        ),
        LockTemplatePreset(
            id: "sunset-couple", name: "Hoàng hôn Đôi", badge: "Cặp đôi", accent: .accentPeach,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .partner, spanTwelfths: 12),
                    .init(kind: .eventCountdown, spanTwelfths: 6),
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                ],
                bg: .sunsetDusk, cardStyle: .solidSoft, cornerRadius: 24
            )
        ),
        LockTemplatePreset(
            id: "amethyst-grid", name: "Tím Pha Lê", badge: "Bo 22pt", accent: Color(RGBA(hex: "#B983FF")!),
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weekStrip, spanTwelfths: 12),
                    .init(kind: .todaySchedule, spanTwelfths: 6),
                    .init(kind: .stickyNote, spanTwelfths: 6),
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .vocab, spanTwelfths: 6),
                ],
                bg: .amethystNight, cardStyle: .frostedGlass, cornerRadius: 22
            )
        ),
        LockTemplatePreset(
            id: "crystal-outline", name: "Viền mảnh 2×2", badge: "Trong suốt", accent: .white,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .lunarCard, spanTwelfths: 6),
                    .init(kind: .vocab, spanTwelfths: 6),
                    .init(kind: .eventCountdown, spanTwelfths: 6),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                ],
                bg: .crystalSlate, cardStyle: .hairlineOutline, cornerRadius: 20
            )
        ),
        LockTemplatePreset(
            id: "espresso-note", name: "Nâu Ghi chú", badge: "Sticky Note", accent: .accentHoney,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .stickyNote, spanTwelfths: 12),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                    .init(kind: .weather, spanTwelfths: 4),
                    .init(kind: .lunarCard, spanTwelfths: 4),
                    .init(kind: .batteryCard, spanTwelfths: 4),
                ],
                bg: .warmEspresso, cardStyle: .frostedGlass, cornerRadius: 18
            )
        ),
        LockTemplatePreset(
            id: "pro-dashed", name: "Nét đứt Kỹ thuật", badge: "Năng suất", accent: .accentHoney,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .yearProgress, spanTwelfths: 6),
                    .init(kind: .habitStreak, spanTwelfths: 6),
                    .init(kind: .todaySchedule, spanTwelfths: 12),
                    .init(kind: .vocab, spanTwelfths: 12),
                ],
                bg: .deepIndigo, cardStyle: .dashedOutline, cornerRadius: 16
            )
        ),
        LockTemplatePreset(
            id: "neon-month", name: "Lịch Tháng Neon", badge: "Viền sáng", accent: .accentSky,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .monthGrid, spanTwelfths: 12),
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .eventCountdown, spanTwelfths: 6),
                ],
                bg: .obsidianNeon, cardStyle: .glowingBorder, cornerRadius: 18
            )
        ),
        LockTemplatePreset(
            id: "full-stack", name: "6 Ô Đa Năng", badge: "2×3 Bento", accent: .accentSky,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weather, spanTwelfths: 6),
                    .init(kind: .lunarCard, spanTwelfths: 6),
                    .init(kind: .vocab, spanTwelfths: 6),
                    .init(kind: .habitStreak, spanTwelfths: 6),
                    .init(kind: .eventCountdown, spanTwelfths: 6),
                    .init(kind: .partner, spanTwelfths: 6),
                ],
                bg: .midnightBlue, cardStyle: .solidSoft, cornerRadius: 18
            )
        ),
        LockTemplatePreset(
            id: "ultra-minimal", name: "Siêu gọn 3 Ô", badge: "1 hàng 3 cột", accent: .accentSage,
            config: LockLayoutConfig(
                items: [
                    .init(kind: .weekStrip, spanTwelfths: 12),
                    .init(kind: .weather, spanTwelfths: 4),
                    .init(kind: .lunarCard, spanTwelfths: 4),
                    .init(kind: .yearProgress, spanTwelfths: 4),
                ],
                bg: .pureDark, cardStyle: .hairlineOutline, cornerRadius: 16
            )
        ),
    ]
}

// MARK: - Lock Studio View

struct LockWallpaperStudio: View {
    static let templateShortcutShareURL = "https://www.icloud.com/shortcuts/71703e2781b04ca2951065fd03bc56d4"
    static let shortcutName = "Update Lock Screen"

    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var config = LockLayoutConfig.load()
    @State private var selectedPresetID: String?
    @State private var editorTab: EditorTab = .templates
    @State private var dragDeltaY: CGFloat = 0
    @State private var draggingItemID: UUID?
    @State private var photoItem: PhotosPickerItem?
    @State private var bgImage: UIImage? = LockLayoutConfig.loadCustomPhoto()
    @State private var exportedImage: UIImage?
    @State private var showExportSheet = false
    @State private var showShortcutGuide = false
    @State private var showAddBlock = false

    enum EditorTab: String, CaseIterable, Identifiable {
        case templates, layout, style, background
        var id: String { rawValue }
        var title: String {
            switch self {
            case .templates: return CozyL10n.t("studio.tab.templates")
            case .layout: return CozyL10n.t("studio.tab.layout")
            case .style: return CozyL10n.t("studio.tab.style")
            case .background: return CozyL10n.t("studio.tab.bg")
            }
        }
        var symbol: String {
            switch self {
            case .templates: return "sparkles.rectangle.stack"
            case .layout: return "square.grid.3x2.fill"
            case .style: return "slider.horizontal.3"
            case .background: return "photo"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(RGBA(hex: "#0D0D0F")!).ignoresSafeArea()
            VStack(spacing: 10) {
                topBar
                lockPreviewCanvas
                editorTabBar
                editorControls
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .preferredColorScheme(.dark)
        .onChange(of: config) { _, newValue in newValue.save() }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    LockLayoutConfig.saveCustomPhoto(ui)
                    bgImage = ui
                    config.bg = .photo
                }
            }
        }
        .sheet(isPresented: $showAddBlock) { addBlockSheet }
        .sheet(isPresented: $showExportSheet) { exportSheet }
        .sheet(isPresented: $showShortcutGuide) { shortcutGuideSheet }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Text("Lock Studio")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                Haptics.tap()
                showShortcutGuide = true
            } label: {
                Image(systemName: config.shortcutInstalled ? "gearshape" : "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cài đặt Shortcut")

            Button {
                Haptics.tap()
                if config.shortcutInstalled {
                    runLockScreenShortcut()
                } else {
                    exportWallpaper()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                    Text("Update Lock Screen")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.accentSky))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: Live Lock Screen Canvas (Kéo lên/xuống để dời khối + Kéo thả trực tiếp ở tab Bố cục)

    private var lockPreviewCanvas: some View {
        GeometryReader { geo in
            let maxH = max(geo.size.height, 190)
            let w = max(min(geo.size.width * 0.58, maxH * (9.0 / 19.5)), 145)
            let h = w * (19.5 / 9.0)
            let upcoming = model.upcomingEvents(limit: 1).first
            LockWallpaperRenderView(
                canvasSize: CGSize(width: w, height: h),
                config: liveDraggedConfig,
                bgImage: bgImage,
                now: model.now,
                lunar: model.lunarToday,
                schedule: model.todaySchedule,
                weather: model.snapshot.weather,
                word: model.currentWord,
                streak: model.streak,
                learnedLog: model.snapshot.learnedLog,
                partner: model.couple?.partner(of: DemoData.meID),
                nextEvent: upcoming,
                nextEventStatus: upcoming.map { model.status(of: $0) },
                batteryPercent: currentBatteryPercent(),
                showMockClock: true
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 16, y: 6)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragDeltaY = value.translation.height * (393.0 / max(w, 1))
                    }
                    .onEnded { _ in
                        config.verticalOffset = min(max(config.verticalOffset + dragDeltaY, -75), 140)
                        dragDeltaY = 0
                        Haptics.tap()
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.18), value: config)
        }
        .frame(minHeight: 300)
    }

    private var liveDraggedConfig: LockLayoutConfig {
        var c = config
        c.verticalOffset = min(max(config.verticalOffset + dragDeltaY, -75), 140)
        return c
    }

    private func currentBatteryPercent() -> Int {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let lvl = UIDevice.current.batteryLevel
        return lvl >= 0 ? Int((lvl * 100).rounded()) : 85
    }

    // MARK: Editor Tab Bar

    private var editorTabBar: some View {
        HStack(spacing: 4) {
            ForEach(EditorTab.allCases) { tab in
                let selected = editorTab == tab
                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.16)) { editorTab = tab }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.symbol).font(.system(size: 11.5, weight: .semibold))
                        Text(tab.title).font(.system(size: 11.5, weight: .semibold)).lineLimit(1)
                    }
                    .foregroundStyle(selected ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(selected ? Color.white.opacity(0.18) : .clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    // MARK: Controls Panel

    @ViewBuilder
    private var editorControls: some View {
        ScrollView {
            VStack(spacing: 10) {
                switch editorTab {
                case .templates:
                    templatesGrid
                case .layout:
                    layoutControls
                case .style:
                    styleControls
                case .background:
                    backgroundControls
                }
            }
        }
        .frame(height: 220)
    }

    // 1. 16 Mẫu hiện đại
    private var templatesGrid: some View {
        VStack(spacing: 8) {
            if config.userEditedBlocks, let activePreset = LockTemplatePreset.all.first(where: { $0.id == selectedPresetID }) {
                Button {
                    Haptics.tap()
                    var reset = activePreset.config
                    reset.shortcutInstalled = config.shortcutInstalled
                    reset.stickyNoteText = config.stickyNoteText
                    config = reset
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Áp dụng luôn bố cục cột của mẫu “\(activePreset.name)”")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentSky)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentSky.opacity(0.14)))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(LockTemplatePreset.all) { preset in
                    let selected = selectedPresetID == preset.id
                    Button {
                        Haptics.tap()
                        selectedPresetID = preset.id
                        let keepBlocks = config.userEditedBlocks
                        let savedItems = config.items
                        let savedOffset = config.verticalOffset
                        let savedShortcut = config.shortcutInstalled
                        let savedNote = config.stickyNoteText
                        var next = preset.config
                        next.verticalOffset = savedOffset
                        next.shortcutInstalled = savedShortcut
                        next.stickyNoteText = savedNote
                        if keepBlocks {
                            next.items = savedItems
                            next.userEditedBlocks = true
                        }
                        config = next
                    } label: {
                        HStack(spacing: 9) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: preset.config.bg.previewColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 34, height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(preset.accent.opacity(0.8), lineWidth: 1.5)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(preset.badge)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(selected ? 0.16 : 0.07)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(selected ? Color.accentSky : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // 2. Bố cục đa cột (1, 2, 3, 4 cột) + Kéo thả trực tiếp (Drag & Drop Bento Canvas)
    private var layoutControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Dàn nhanh số cột cho toàn bộ khối 1 chạm
            HStack(spacing: 6) {
                Text("Chia nhanh:")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                ForEach([(12, "1 cột"), (6, "2 cột"), (4, "3 cột"), (3, "4 cột")], id: \.0) { span, label in
                    Button {
                        Haptics.tap()
                        withAnimation(.easeOut(duration: 0.18)) {
                            for idx in config.items.indices {
                                config.items[idx].spanTwelfths = span
                            }
                            config.userEditedBlocks = true
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }

            Text(CozyL10n.t("studio.dragHint"))
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.58))

            // Lưới Bento Visual Editor phản chiếu đúng các hàng 1–4 cột và hỗ trợ nhấn giữ kéo thả!
            VStack(spacing: 8) {
                ForEach(Array(config.packedRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row) { item in
                            bentoEditorTile(item)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            if config.items.contains(where: { $0.kind == .stickyNote }) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text").foregroundStyle(Color.accentHoney)
                    TextField("Nội dung ghi chú ghim…", text: $config.stickyNoteText)
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.09)))
            }

            Button {
                Haptics.tap()
                showAddBlock = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(CozyL10n.t("studio.addComponent"))
                        .lineLimit(1)
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.accentSky)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentSky.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
    }

    private func bentoEditorTile(_ item: LockBlockPlacement) -> some View {
        let compact = item.spanTwelfths <= 4
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                Image(systemName: item.kind.symbol)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(item.kind.accent)
                if !compact {
                    Text(item.kind.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.16)) {
                        config.items.removeAll { $0.id == item.id }
                        config.userEditedBlocks = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }

            if compact {
                Text(item.kind.title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                // Nút đổi kích thước cột: 1 cột -> 1/2 (2 cột) -> 1/3 (3 cột) -> 1/4 (4 cột)
                Button {
                    Haptics.tap()
                    if let idx = config.items.firstIndex(where: { $0.id == item.id }) {
                        withAnimation(.easeOut(duration: 0.16)) {
                            config.items[idx].cycleSpan()
                            config.userEditedBlocks = true
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.left.and.right.square")
                            .font(.system(size: 10))
                        Text(item.columnLabel)
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundStyle(Color.accentSky)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.accentSky.opacity(0.18)))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                if let idx = config.items.firstIndex(where: { $0.id == item.id }) {
                    if idx > 0 {
                        Button {
                            Haptics.tap()
                            withAnimation(.easeOut(duration: 0.16)) {
                                config.items.swapAt(idx, idx - 1)
                                config.userEditedBlocks = true
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.white.opacity(0.09)))
                        }
                        .buttonStyle(.plain)
                    }
                    if idx < config.items.count - 1 {
                        Button {
                            Haptics.tap()
                            withAnimation(.easeOut(duration: 0.16)) {
                                config.items.swapAt(idx, idx + 1)
                                config.userEditedBlocks = true
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.white.opacity(0.09)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(draggingItemID == item.id ? 0.22 : 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .draggable(item.id.uuidString) {
            HStack(spacing: 6) {
                Image(systemName: item.kind.symbol).foregroundStyle(item.kind.accent)
                Text(item.kind.title).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(RGBA(hex: "#1E293B")!)))
            .onAppear { draggingItemID = item.id }
        }
        .dropDestination(for: String.self) { droppedIDs, _ in
            defer { draggingItemID = nil }
            guard let first = droppedIDs.first,
                  let sourceUUID = UUID(uuidString: first),
                  sourceUUID != item.id,
                  let fromIndex = config.items.firstIndex(where: { $0.id == sourceUUID }),
                  let toIndex = config.items.firstIndex(where: { $0.id == item.id }) else {
                return false
            }
            withAnimation(.easeOut(duration: 0.18)) {
                let moved = config.items.remove(at: fromIndex)
                config.items.insert(moved, at: toIndex)
                config.userEditedBlocks = true
            }
            Haptics.tap()
            return true
        }
    }

    // 3. Viền, Bo góc, Khoảng cách, Độ đậm nền & Cỡ chữ
    private var styleControls: some View {
        VStack(spacing: 9) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(LockCardStyle.allCases) { st in
                    let selected = config.cardStyle == st
                    Button {
                        Haptics.tap()
                        config.cardStyle = st
                    } label: {
                        Text(st.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 11).fill(selected ? Color.accentSky : Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }

            sliderCard(title: CozyL10n.t("style.cornerRadius"), valueText: "\(Int(config.cornerRadius)) pt", value: $config.cornerRadius, range: 6...28, step: 2)
            sliderCard(title: CozyL10n.t("style.gridSpacing"), valueText: "\(Int(config.gridSpacing)) pt", value: $config.gridSpacing, range: 4...18, step: 2)
            sliderCard(title: CozyL10n.t("style.fontScale"), valueText: "\(Int((config.fontScale * 100).rounded()))%", value: $config.fontScale, range: 0.85...1.20, step: 0.05)
            sliderCard(title: CozyL10n.t("style.cardOpacity"), valueText: "\(Int((config.cardOpacity * 100).rounded()))%", value: $config.cardOpacity, range: 0.35...1.35, step: 0.10)
            sliderCard(title: CozyL10n.t("style.verticalOffset"), valueText: "\(Int(config.verticalOffset)) pt", value: $config.verticalOffset, range: -75...140, step: 5)
        }
    }

    private func sliderCard(title: String, valueText: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                Text(valueText).font(.caption.monospaced()).foregroundStyle(.white.opacity(0.7))
            }
            Slider(value: value, in: range, step: step).tint(Color.accentSky)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
    }

    // 4. Nền màu & Ảnh cá nhân
    private var backgroundControls: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(LockWallpaperBg.allCases.filter { $0 != .photo }) { bg in
                    let selected = config.bg == bg
                    Button {
                        Haptics.tap()
                        config.bg = bg
                    } label: {
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: bg.previewColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 34)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(selected ? Color.accentSky : Color.white.opacity(0.18), lineWidth: selected ? 2 : 1)
                                )
                            Text(bg.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(CozyL10n.t("bg.choosePhoto"), systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
            }
        }
    }

    // MARK: Sheets

    private var addBlockSheet: some View {
        NavigationStack {
            List {
                Section("Chọn thành phần & kích thước cột muốn thêm") {
                    ForEach(LockBlockKind.allCases) { kind in
                        HStack(spacing: 10) {
                            Image(systemName: kind.symbol)
                                .foregroundStyle(kind.accent)
                                .frame(width: 24)
                            Text(kind.title)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            ForEach([(12, "1 cột"), (6, "1/2"), (4, "1/3"), (3, "1/4")], id: \.0) { span, label in
                                Button {
                                    Haptics.tap()
                                    config.items.append(LockBlockPlacement(kind: kind, spanTwelfths: span))
                                    config.userEditedBlocks = true
                                    showAddBlock = false
                                } label: {
                                    Text("+\(label)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.accentSky)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.accentSky.opacity(0.15)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Thêm ô thành phần")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { showAddBlock = false } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var exportSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let ui = exportedImage {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .frame(maxHeight: 360)
                    }

                    VStack(spacing: 10) {
                        Button {
                            config.shortcutInstalled = true
                            config.save()
                            showExportSheet = false
                            runLockScreenShortcut()
                        } label: {
                            Label("Update Lock Screen", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: true))

                        if !config.shortcutInstalled,
                           let shareURL = URL(string: Self.templateShortcutShareURL),
                           !Self.templateShortcutShareURL.isEmpty {
                            Button {
                                config.shortcutInstalled = true
                                config.save()
                                openURL(shareURL)
                            } label: {
                                Label(CozyL10n.t("studio.installShortcutFirst"), systemImage: "plus.app.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                        }
                    }

                    Text("Chỉ cần cài Shortcut 1 lần duy nhất. Từ lần sau bấm “Update Lock Screen” sẽ áp dụng thẳng ra màn hình khóa.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .navigationTitle("Update Lock Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { showExportSheet = false }.bold() }
            }
        }
    }

    private var shortcutGuideSheet: some View {
        NavigationStack {
            List {
                Section("Trạng thái Shortcut") {
                    Toggle("Đã cài Shortcut “Update Lock Screen”", isOn: $config.shortcutInstalled)
                        .tint(Color.accentSky)
                }
                Section("Thao tác") {
                    if let shareURL = URL(string: Self.templateShortcutShareURL), !Self.templateShortcutShareURL.isEmpty {
                        Button {
                            config.shortcutInstalled = true
                            config.save()
                            openURL(shareURL)
                        } label: {
                            Label("Cài Shortcut mẫu (1 chạm)", systemImage: "plus.app.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.accentSky)
                        }
                    }
                    Button {
                        showShortcutGuide = false
                        exportWallpaper()
                    } label: {
                        Label("Xem trước & Lưu ảnh thủ công", systemImage: "photo")
                            .font(.system(size: 15))
                    }
                }
                Section("Mẹo tự động cập nhật dữ liệu thật") {
                    Text("• Thêm tự động hóa Thời gian (00:01, 07:00, 12:30, 18:30) hoặc Khi đóng App để hình nền tự làm mới Thời tiết, Lịch & Cảm xúc.")
                    Text("• Đặt thêm Widget “Từ vựng hôm nay” ngay dưới đồng hồ Lock Screen để bấm nút ↻ đổi từ trực tiếp không cần mở app!")
                }
            }
            .navigationTitle("Cài đặt Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { showShortcutGuide = false }.bold() }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func runLockScreenShortcut() {
        config.save()
        let encoded = Self.shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Update%20Lock%20Screen"
        if let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") {
            openURL(url)
        }
    }

    @MainActor
    private func exportWallpaper() {
        config.save()
        let renderSize = CGSize(width: 393, height: 852)
        let upcoming = model.upcomingEvents(limit: 1).first
        let view = LockWallpaperRenderView(
            canvasSize: renderSize,
            config: config,
            bgImage: bgImage,
            now: model.now,
            lunar: model.lunarToday,
            schedule: model.todaySchedule,
            weather: model.snapshot.weather,
            word: model.currentWord,
            streak: model.streak,
            learnedLog: model.snapshot.learnedLog,
            partner: model.couple?.partner(of: DemoData.meID),
            nextEvent: upcoming,
            nextEventStatus: upcoming.map { model.status(of: $0) },
            batteryPercent: currentBatteryPercent(),
            showMockClock: false
        )
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(renderSize)
        renderer.scale = 3
        exportedImage = renderer.uiImage
        showExportSheet = true
    }
}

// MARK: - Deterministic Multi-Column Bento Renderer (100% VStack/HStack tĩnh cho ImageRenderer)

struct LockWallpaperRenderView: View {
    var canvasSize: CGSize
    var config: LockLayoutConfig
    var bgImage: UIImage?
    var now: Date
    var lunar: LunarDate
    var schedule: [TodayScheduleItem]
    var weather: WeatherSnapshot?
    var word: VocabWord?
    var streak: Int
    var learnedLog: [String: Int] = [:]
    var partner: MemberStatus?
    var nextEvent: CozyEvent? = nil
    var nextEventStatus: EventStatus? = nil
    var batteryPercent: Int = 85
    var showMockClock: Bool

    private var primaryText: Color { config.bg.isLight ? Color(RGBA(hex: "#141418")!) : .white }
    private var secondaryText: Color { config.bg.isLight ? Color(RGBA(hex: "#5A5D68")!) : .white.opacity(0.68) }

    var body: some View {
        let w = canvasSize.width
        let h = canvasSize.height
        let scale = w / 393.0
        let fScale = scale * config.fontScale
        let hPad = 18.0 * scale
        let contentW = w - hPad * 2
        let gap = config.gridSpacing * scale

        ZStack(alignment: .top) {
            backgroundLayer(size: canvasSize)

            VStack(spacing: 0) {
                if showMockClock {
                    VStack(spacing: 2 * scale) {
                        Text(dateTitle)
                            .font(.system(size: 16 * scale, weight: .semibold))
                            .foregroundStyle(primaryText.opacity(0.88))
                        Text(now, style: .time)
                            .font(.system(size: 74 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryText.opacity(0.92))
                            .monospacedDigit()
                    }
                    .padding(.top, h * 0.075)
                    .frame(height: h * 0.275, alignment: .top)
                } else {
                    Color.clear.frame(height: h * 0.275)
                }

                // Lưới Bento 12 đơn vị: hỗ trợ 1 cột, 2 cột, 3 cột, 4 cột trên từng hàng với chiều rộng chính xác tuyệt đối!
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(Array(config.packedRows.enumerated()), id: \.offset) { _, row in
                        let totalUnits = max(row.reduce(0) { $0 + $1.spanTwelfths }, 1)
                        let rowGaps = CGFloat(max(row.count - 1, 0)) * gap
                        let usableRowW = max(contentW - rowGaps, 40)

                        HStack(alignment: .top, spacing: gap) {
                            ForEach(row) { item in
                                let itemW = usableRowW * (CGFloat(item.spanTwelfths) / CGFloat(totalUnits))
                                tileView(item, width: itemW, scale: scale, fScale: fScale)
                            }
                        }
                    }
                }
                .padding(.horizontal, hPad)
                .offset(y: config.verticalOffset * scale)

                Spacer(minLength: 0)

                if showMockClock {
                    HStack {
                        Image(systemName: "flashlight.off.fill")
                            .font(.system(size: 16 * scale))
                            .frame(width: 40 * scale, height: 40 * scale)
                            .background(Circle().fill(primaryText.opacity(0.12)))
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16 * scale))
                            .frame(width: 40 * scale, height: 40 * scale)
                            .background(Circle().fill(primaryText.opacity(0.12)))
                    }
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 34 * scale)
                    .padding(.bottom, 24 * scale)
                }
            }
        }
        .frame(width: w, height: h)
        .clipped()
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        if config.bg == .photo, let bgImage {
            Image(uiImage: bgImage)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .overlay(Color.black.opacity(0.28))
        } else {
            LinearGradient(colors: config.bg.previewColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private func tileView(_ item: LockBlockPlacement, width: CGFloat, scale: CGFloat, fScale: CGFloat) -> some View {
        let radius = config.cornerRadius * scale
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let compact = item.spanTwelfths <= 4
        let half = item.spanTwelfths <= 6
        let pad = config.cardStyle == .none ? (2 * scale) : ((compact ? 8 : 11) * scale)
        let op = config.cardOpacity

        Group {
            switch item.kind {
            case .weekStrip: weekStripBlock(compact: half, scale: scale, fScale: fScale)
            case .todaySchedule: todayScheduleBlock(compact: half, scale: scale, fScale: fScale)
            case .weather: weatherBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .vocab: vocabBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .partner: partnerBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .monthGrid: monthGridBlock(scale: scale, fScale: fScale)
            case .eventCountdown: eventCountdownBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .yearProgress: yearProgressBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .habitStreak: habitStreakBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .lunarCard: lunarCardBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .stickyNote: stickyNoteBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            case .batteryCard: batteryCardBlock(span: item.spanTwelfths, scale: scale, fScale: fScale)
            }
        }
        .padding(pad)
        .frame(width: width, alignment: .leading)
        .background {
            switch config.cardStyle {
            case .none:
                EmptyView()
            case .frostedGlass:
                shape.fill(config.bg.isLight ? Color.white.opacity(min(0.78 * op, 0.96)) : Color.black.opacity(min(0.38 * op, 0.85)))
                    .overlay(shape.strokeBorder(primaryText.opacity(0.15), lineWidth: 1))
            case .solidSoft:
                shape.fill(config.bg.isLight ? Color.white.opacity(min(0.92 * op, 1.0)) : Color.white.opacity(min(0.11 * op, 0.35)))
                    .overlay(shape.strokeBorder(primaryText.opacity(0.09), lineWidth: 1))
            case .glowingBorder:
                shape.fill(Color.black.opacity(min(0.34 * op, 0.8)))
                    .overlay(shape.strokeBorder(item.kind.accent.opacity(0.75), lineWidth: 1.4))
            case .hairlineOutline:
                shape.strokeBorder(primaryText.opacity(0.28), lineWidth: 1.2)
            case .dashedOutline:
                shape.fill(Color.white.opacity(0.04 * op))
                    .overlay(shape.strokeBorder(primaryText.opacity(0.34), style: StrokeStyle(lineWidth: 1.2, dash: [5 * scale, 4 * scale])))
            }
        }
    }

    // 1. Lịch tuần
    private func weekStripBlock(compact: Bool, scale: CGFloat, fScale: CGFloat) -> some View {
        let cal = Calendar.cozy
        let weekday = cal.component(.weekday, from: now)
        let offsetToMon = (weekday == 1) ? -6 : (2 - weekday)
        let monday = cal.date(byAdding: .day, value: offsetToMon, to: cal.startOfDay(for: now))!
        let labels = CozyL10n.weekdayShortLabels()

        return HStack(spacing: (compact ? 2 : 4) * scale) {
            ForEach(0..<7, id: \.self) { i in
                let d = cal.date(byAdding: .day, value: i, to: monday)!
                let isToday = cal.isDate(d, inSameDayAs: now)
                let dayNum = cal.component(.day, from: d)
                VStack(spacing: 2 * scale) {
                    Text(labels[i])
                        .font(.system(size: (compact ? 9 : 11) * fScale, weight: .semibold))
                        .foregroundStyle(isToday ? (config.bg.isLight ? .white : .black) : secondaryText)
                    Text("\(dayNum)")
                        .font(.system(size: (compact ? 12 : 15.5) * fScale, weight: .bold, design: .rounded))
                        .foregroundStyle(isToday ? (config.bg.isLight ? .white : .black) : primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, (compact ? 4 : 6.5) * scale)
                .background(
                    RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                        .fill(isToday ? (config.bg.isLight ? Color.accentSky : Color.white.opacity(0.92)) : .clear)
                )
            }
        }
    }

    // 2. Lịch trình hôm nay
    private func todayScheduleBlock(compact: Bool, scale: CGFloat, fScale: CGFloat) -> some View {
        let pending = schedule.filter { !$0.isDone }
        return VStack(alignment: .leading, spacing: 5 * scale) {
            HStack(spacing: 4 * scale) {
                Image(systemName: "checklist")
                    .font(.system(size: 11 * fScale, weight: .bold))
                    .foregroundStyle(Color.accentHoney)
                Text(CozyL10n.t("tab.today"))
                    .font(.system(size: (compact ? 13 : 15) * fScale, weight: .bold))
                    .foregroundStyle(Color.accentHoney)
            }
            if pending.isEmpty {
                let emptyMsg = CozyL10n.t("schedule.noEvents")
                Text(CozyL10n.effective.isVietnamese ? "\(emptyMsg) · \(lunar.shortText) ÂL" : emptyMsg)
                    .font(.system(size: (compact ? 11.5 : 13) * fScale, weight: .medium))
                    .foregroundStyle(secondaryText)
                    .lineLimit(2)
            } else {
                ForEach(pending.prefix(compact ? 2 : 3)) { item in
                    HStack(spacing: 6 * scale) {
                        RoundedRectangle(cornerRadius: 2 * scale)
                            .fill(item.accent.color)
                            .frame(width: 3 * scale, height: 13 * scale)
                        if !compact, let t = item.timeText {
                            Text(t)
                                .font(.system(size: 11.5 * fScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(secondaryText)
                        }
                        Text(item.title)
                            .font(.system(size: (compact ? 12 : 13.5) * fScale, weight: .semibold))
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    // 3. Thời tiết thật (tự thích ứng 1 cột / 2 cột / 3 cột / 4 cột)
    @ViewBuilder
    private func weatherBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        if let w = weather {
            if span <= 4 {
                VStack(alignment: .leading, spacing: 2 * scale) {
                    HStack(spacing: 4 * scale) {
                        Image(systemName: w.condition.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 15 * fScale))
                        Text(w.temperatureText)
                            .font(.system(size: 16 * fScale, weight: .heavy, design: .rounded))
                            .foregroundStyle(primaryText)
                    }
                    Text(span == 3 ? w.condition.displayName : w.placeName)
                        .font(.system(size: 10 * fScale, weight: .medium))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }
            } else if span == 6 {
                VStack(alignment: .leading, spacing: 3 * scale) {
                    HStack(spacing: 6 * scale) {
                        Image(systemName: w.condition.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 20 * fScale))
                        Text(w.temperatureText)
                            .font(.system(size: 20 * fScale, weight: .heavy, design: .rounded))
                            .foregroundStyle(primaryText)
                    }
                    Text("\(w.placeName) · \(w.condition.displayName)")
                        .font(.system(size: 11.5 * fScale, weight: .semibold))
                        .foregroundStyle(primaryText.opacity(0.9))
                        .lineLimit(1)
                    Text("↑\(Int(w.highC.rounded()))° ↓\(Int(w.lowC.rounded()))° · \(CozyL10n.t("weather.humidity")) \(Int((w.humidity * 100).rounded()))%")
                        .font(.system(size: 10.5 * fScale))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }
            } else {
                HStack(spacing: 10 * scale) {
                    Image(systemName: w.condition.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 24 * fScale))
                    VStack(alignment: .leading, spacing: 2 * scale) {
                        Text("\(w.temperatureText) \(w.placeName) · \(w.condition.displayName)")
                            .font(.system(size: 15 * fScale, weight: .bold))
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                        Text("↑\(Int(w.highC.rounded()))° ↓\(Int(w.lowC.rounded()))° · \(CozyL10n.t("weather.feelsLike")) \(Int(w.apparentC.rounded()))° · \(CozyL10n.t("weather.humidity")) \(Int((w.humidity * 100).rounded()))%")
                            .font(.system(size: 11.5 * fScale))
                            .foregroundStyle(secondaryText)
                            .lineLimit(1)
                    }
                }
            }
        } else {
            Text("\(CozyL10n.t("weather.title"))…")
                .font(.system(size: 12 * fScale))
                .foregroundStyle(secondaryText)
        }
    }

    // 4. Từ vựng hôm nay
    @ViewBuilder
    private func vocabBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        if let w = word {
            VStack(alignment: .leading, spacing: 3 * scale) {
                HStack(alignment: .firstTextBaseline, spacing: 5 * scale) {
                    Text(w.word)
                        .font(.system(size: (span <= 6 ? 15 : 17.5) * fScale, weight: .bold))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)
                    if span == 12, !w.phonetic.isEmpty {
                        Text(w.phonetic)
                            .font(.system(size: 11.5 * fScale, design: .monospaced))
                            .foregroundStyle(secondaryText)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if span >= 6 {
                        Text("🔥\(streak)")
                            .font(.system(size: 11 * fScale, weight: .bold))
                            .foregroundStyle(Color.accentHoney)
                    }
                }
                Text(w.meaning)
                    .font(.system(size: (span <= 4 ? 10.5 : 12.5) * fScale, weight: .medium))
                    .foregroundStyle(primaryText.opacity(0.85))
                    .lineLimit(span <= 6 ? 2 : 2)
            }
        } else {
            Text("Từ vựng")
                .font(.system(size: 12 * fScale, weight: .bold))
                .foregroundStyle(secondaryText)
        }
    }

    // 5. Người kết nối
    @ViewBuilder
    private func partnerBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        if let p = partner {
            if span <= 6 {
                VStack(alignment: .leading, spacing: 3 * scale) {
                    HStack(spacing: 5 * scale) {
                        Text(p.mood?.emoji ?? "❤️").font(.system(size: 16 * fScale))
                        Text(p.displayName)
                            .font(.system(size: 13 * fScale, weight: .bold))
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                    }
                    Text(p.note.isEmpty ? (p.mood?.displayName ?? "Đã kết nối") : p.note)
                        .font(.system(size: 11 * fScale))
                        .foregroundStyle(secondaryText)
                        .lineLimit(2)
                }
            } else {
                HStack(spacing: 10 * scale) {
                    Text(p.mood?.emoji ?? "❤️").font(.system(size: 22 * fScale))
                    VStack(alignment: .leading, spacing: 2 * scale) {
                        HStack(spacing: 6 * scale) {
                            Text(p.displayName)
                                .font(.system(size: 15 * fScale, weight: .bold))
                                .foregroundStyle(primaryText)
                            if let m = p.mood {
                                Text("· \(m.displayName)")
                                    .font(.system(size: 12.5 * fScale, weight: .semibold))
                                    .foregroundStyle(Color.accentPeach)
                            }
                        }
                        if !p.note.isEmpty {
                            Text(p.note)
                                .font(.system(size: 12.5 * fScale))
                                .foregroundStyle(primaryText.opacity(0.82))
                                .lineLimit(1)
                        }
                    }
                }
            }
        } else {
            HStack(spacing: 5 * scale) {
                Image(systemName: "heart.fill").foregroundStyle(Color.accentPeach).font(.system(size: 12 * fScale))
                Text(CozyL10n.t("partner.empty"))
                    .font(.system(size: 12 * fScale, weight: .semibold))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }
        }
    }

    // 6. Lịch tháng (VStack/HStack tĩnh 100%)
    private func monthGridBlock(scale: CGFloat, fScale: CGFloat) -> some View {
        let cal = Calendar.cozy
        let comps = cal.dateComponents([.year, .month], from: now)
        let first = cal.date(from: comps)!
        let totalDays = cal.range(of: .day, in: .month, for: first)!.count
        let firstWD = cal.component(.weekday, from: first)
        let pad = (firstWD == 1) ? 6 : (firstWD - 2)
        let todayDay = cal.component(.day, from: now)
        let totalCells = pad + totalDays
        let rowCount = (totalCells + 6) / 7
        let labels = CozyL10n.weekdayShortLabels()

        return VStack(spacing: 3.5 * scale) {
            HStack(spacing: 2 * scale) {
                ForEach(labels, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 9.5 * fScale, weight: .bold))
                        .foregroundStyle(secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<rowCount, id: \.self) { r in
                HStack(spacing: 2 * scale) {
                    ForEach(0..<7, id: \.self) { c in
                        let idx = r * 7 + c
                        if idx < pad || idx >= totalCells {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 17 * scale)
                        } else {
                            let day = idx - pad + 1
                            let isToday = day == todayDay
                            Text("\(day)")
                                .font(.system(size: 10.5 * fScale, weight: isToday ? .heavy : .medium, design: .rounded))
                                .foregroundStyle(isToday ? (config.bg.isLight ? .white : .black) : primaryText.opacity(0.88))
                                .frame(maxWidth: .infinity, minHeight: 17 * scale)
                                .background(RoundedRectangle(cornerRadius: 5 * scale).fill(isToday ? (config.bg.isLight ? Color.accentSky : Color.white) : .clear))
                        }
                    }
                }
            }
        }
    }

    // 7. Đếm ngày sự kiện sắp tới
    @ViewBuilder
    private func eventCountdownBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        if let e = nextEvent, let s = nextEventStatus {
            VStack(alignment: .leading, spacing: 3 * scale) {
                HStack(spacing: 4 * scale) {
                    Text(e.emoji).font(.system(size: 12 * fScale))
                    Text(e.title)
                        .font(.system(size: (span <= 4 ? 11 : 12.5) * fScale, weight: .bold))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)
                }
                Text(s.sentence)
                    .font(.system(size: (span <= 4 ? 12 : 14.5) * fScale, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentPeach)
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .leading, spacing: 2 * scale) {
                Label("Sự kiện", systemImage: "hourglass")
                    .font(.system(size: 11 * fScale, weight: .bold))
                    .foregroundStyle(Color.accentPeach)
                Text("Chưa có mốc đếm")
                    .font(.system(size: 11 * fScale))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }
        }
    }

    // 8. Tiến độ năm % (Year Progress)
    private func yearProgressBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        let cal = Calendar.cozy
        let year = cal.component(.year, from: now)
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        let total = cal.range(of: .day, in: .year, for: now)?.count ?? 365
        let ratio = min(max(Double(dayOfYear) / Double(total), 0), 1)
        let pct = Int((ratio * 100).rounded())

        return VStack(alignment: .leading, spacing: 5 * scale) {
            HStack {
                Text("\(year)")
                    .font(.system(size: 12 * fScale, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                Spacer(minLength: 2)
                Text("\(pct)%")
                    .font(.system(size: 12.5 * fScale, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.accentHoney)
            }
            HStack(spacing: 2 * scale) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2 * scale)
                        .fill(Double(i) < ratio * 10.0 ? Color.accentHoney : primaryText.opacity(0.16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6 * scale)
                }
            }
        }
    }

    // 9. Chuỗi học 7 ngày (Habit Streak Dots)
    private func habitStreakBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        let cal = Calendar.cozy
        return VStack(alignment: .leading, spacing: 5 * scale) {
            HStack(spacing: 4 * scale) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11 * fScale))
                    .foregroundStyle(Color.accentSage)
                Text(span <= 4 ? "\(streak)d" : "\(CozyL10n.t("block.habitStreak")) · \(streak)")
                    .font(.system(size: 12 * fScale, weight: .bold))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
            }
            HStack(spacing: 3 * scale) {
                ForEach(0..<7, id: \.self) { idx in
                    let d = cal.date(byAdding: .day, value: idx - 6, to: now)!
                    let key = cal.dayKey(for: d)
                    let active = (learnedLog[key] ?? 0) > 0 || (idx == 6 && streak > 0)
                    RoundedRectangle(cornerRadius: 3 * scale)
                        .fill(active ? Color.accentSage : primaryText.opacity(0.16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 8 * scale)
                }
            }
        }
    }

    // 10. Âm lịch hôm nay
    private func lunarCardBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2 * scale) {
            HStack(spacing: 4 * scale) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 11 * fScale))
                    .foregroundStyle(Color.accentHoney)
                Text(CozyL10n.t("block.lunarCard"))
                    .font(.system(size: 10.5 * fScale, weight: .semibold))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }
            Text("\(lunar.shortText)")
                .font(.system(size: (span <= 4 ? 14 : 16) * fScale, weight: .heavy, design: .rounded))
                .foregroundStyle(primaryText)
                .lineLimit(1)
            if span >= 6, CozyL10n.effective.isVietnamese {
                Text("Năm \(lunar.yearName)")
                    .font(.system(size: 10.5 * fScale))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }
        }
    }

    // 11. Ghi chú ghim (Sticky Note)
    private func stickyNoteBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            HStack(spacing: 4 * scale) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10 * fScale))
                    .foregroundStyle(Color.accentHoney)
                Text(CozyL10n.t("block.stickyNote"))
                    .font(.system(size: 10.5 * fScale, weight: .bold))
                    .foregroundStyle(Color.accentHoney)
            }
            Text(config.stickyNoteText)
                .font(.system(size: (span <= 4 ? 10.5 : 12.5) * fScale, weight: .medium))
                .foregroundStyle(primaryText)
                .lineLimit(span == 12 ? 2 : 3)
        }
    }

    // 12. Pin thiết bị
    private func batteryCardBlock(span: Int, scale: CGFloat, fScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            HStack(spacing: 4 * scale) {
                Image(systemName: "battery.100percent.bolt")
                    .font(.system(size: 11 * fScale))
                    .foregroundStyle(Color.accentSage)
                Text("\(batteryPercent)%")
                    .font(.system(size: (span <= 4 ? 14 : 16) * fScale, weight: .heavy, design: .rounded))
                    .foregroundStyle(primaryText)
            }
            Text(CozyL10n.t("block.batteryCard"))
                .font(.system(size: 10 * fScale, weight: .medium))
                .foregroundStyle(secondaryText)
                .lineLimit(1)
        }
    }

    private var dateTitle: String {
        CozyL10n.formatLockDate(now)
    }
}

/// AppIntent cho Apple Shortcuts: tự làm mới dữ liệu thật và render ảnh nền Lock Screen đa cột.
struct GenerateLockWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Update Lock Screen"
    static let description = IntentDescription("Tự đồng bộ dữ liệu thật và vẽ ảnh nền Màn hình khóa Bento đa cột.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let repo = CozyShared.repository

        var cfg = LockLayoutConfig.load()
        if !cfg.shortcutInstalled {
            cfg.shortcutInstalled = true
            cfg.save()
        }

        try? await CloudSync.shared.sync()
        let weatherService = CozyWeatherService(repository: repo)
        await weatherService.refreshIfNeeded()
        if repo.snapshot(reload: true).settings.syncAppleCalendar {
            let calService = CalendarImportService()
            let imported = await calService.upcomingEvents(days: 14)
            for e in imported { repo.upsertEvent(e) }
        }
        CozyShared.didChange()

        UIDevice.current.isBatteryMonitoringEnabled = true
        let lvl = UIDevice.current.batteryLevel
        let batteryPct = lvl >= 0 ? Int((lvl * 100).rounded()) : 85

        let now = Date()
        let snap = repo.snapshot(reload: true)
        CozyL10n.current = snap.settings.language
        let upcoming = repo.upcomingEvents(now: now, limit: 1).first
        let status = upcoming.map { EventCounter(calendar: repo.calendar).status(of: $0, now: now) }
        let renderSize = CGSize(width: 393, height: 852)

        let view = LockWallpaperRenderView(
            canvasSize: renderSize,
            config: cfg,
            bgImage: LockLayoutConfig.loadCustomPhoto(),
            now: now,
            lunar: VietnameseLunarCalendar.lunarDate(from: now, calendar: repo.calendar),
            schedule: repo.todaySchedule(now: now),
            weather: snap.weather,
            word: repo.currentWord(now: now),
            streak: repo.vocabStreak(now: now),
            learnedLog: snap.learnedLog,
            partner: snap.spaces.preferred(.couple)?.partner(of: DemoData.meID),
            nextEvent: upcoming,
            nextEventStatus: status,
            batteryPercent: batteryPct,
            showMockClock: false
        )

        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(renderSize)
        renderer.scale = 3
        let data = renderer.uiImage?.pngData() ?? Data()
        return .result(value: IntentFile(data: data, filename: "lockscreen.png", type: .png))
    }
}
