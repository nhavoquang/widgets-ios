import SwiftUI
import PhotosUI
import UIKit
import AppIntents
import UniformTypeIdentifiers
import CozyCore

// MARK: - Locka-Style Block, Background, Card Style & 10 Modern Templates

enum LockBlockKind: String, CaseIterable, Identifiable, Codable {
    case weekStrip
    case todaySchedule
    case weather
    case vocab
    case partner
    case monthGrid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekStrip: return "Lịch tuần"
        case .todaySchedule: return "Lịch trình hôm nay"
        case .weather: return "Thời tiết thật"
        case .vocab: return "Từ vựng hôm nay"
        case .partner: return "Người kết nối"
        case .monthGrid: return "Lịch tháng"
        }
    }

    var symbol: String {
        switch self {
        case .weekStrip: return "calendar.day.timeline.left"
        case .todaySchedule: return "checklist"
        case .weather: return "cloud.sun.fill"
        case .vocab: return "character.book.closed.fill"
        case .partner: return "heart.fill"
        case .monthGrid: return "calendar"
        }
    }

    var accent: Color {
        switch self {
        case .weekStrip, .todaySchedule, .weather: return .accentSky
        case .vocab: return .accentSage
        case .partner: return .accentPeach
        case .monthGrid: return .accentHoney
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
        case .photo: return "Ảnh của bạn"
        }
    }

    var isLight: Bool { self == .cleanLight }

    var previewColors: [Color] {
        switch self {
        case .pureDark: return [Color(RGBA(hex: "#141416")!), Color(RGBA(hex: "#1C1C20")!)]
        case .midnightBlue: return [Color(RGBA(hex: "#0F172A")!), Color(RGBA(hex: "#1E293B")!)]
        case .obsidianNeon: return [Color(RGBA(hex: "#090B10")!), Color(RGBA(hex: "#121826")!)]
        case .sunsetDusk: return [Color(RGBA(hex: "#1F1C2C")!), Color(RGBA(hex: "#614357")!), Color(RGBA(hex: "#232526")!)]
        case .forestTeal: return [Color(RGBA(hex: "#0B2222")!), Color(RGBA(hex: "#133B38")!)]
        case .amethystNight: return [Color(RGBA(hex: "#1E122B")!), Color(RGBA(hex: "#351F4A")!)]
        case .cleanLight: return [Color(RGBA(hex: "#F3F5F8")!), Color(RGBA(hex: "#E6EAF0")!)]
        case .crystalSlate: return [Color(RGBA(hex: "#181A20")!), Color(RGBA(hex: "#242833")!)]
        case .roseCharcoal: return [Color(RGBA(hex: "#1D1418")!), Color(RGBA(hex: "#361D28")!)]
        case .deepIndigo: return [Color(RGBA(hex: "#111827")!), Color(RGBA(hex: "#1F2937")!)]
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
        switch self {
        case .none: return "Không nền"
        case .frostedGlass: return "Kính mờ"
        case .solidSoft: return "Bo mềm"
        case .glowingBorder: return "Viền sáng"
        case .hairlineOutline: return "Viền mảnh"
        case .dashedOutline: return "Nét đứt"
        }
    }
}

struct LockLayoutConfig: Equatable, Codable {
    var blocks: [LockBlockKind] = [.weekStrip, .todaySchedule, .weather, .vocab]
    var bg: LockWallpaperBg = .pureDark
    var cardStyle: LockCardStyle = .none
    var cornerRadius: CGFloat = 18
    var verticalOffset: CGFloat = 0
    /// Đánh dấu user đã tự chỉnh danh sách khối để khi chọn mẫu mới không bị mất các khối đã xếp.
    var userEditedBlocks: Bool = false

    private static let storageKey = "cozy.lockLayoutConfig.v3"

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

/// 10 mẫu Lock Screen hiện đại để chọn 1 chạm.
struct LockTemplatePreset: Identifiable {
    let id: String
    let name: String
    let badge: String
    let accent: Color
    let config: LockLayoutConfig

    static let all: [LockTemplatePreset] = [
        LockTemplatePreset(
            id: "minimal-dark", name: "Tối giản", badge: "Không nền", accent: .accentHoney,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .weather, .vocab], bg: .pureDark, cardStyle: .none, cornerRadius: 14)
        ),
        LockTemplatePreset(
            id: "midnight-glass", name: "Kính mờ", badge: "Bo 20pt", accent: .accentSky,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .weather, .vocab], bg: .midnightBlue, cardStyle: .frostedGlass, cornerRadius: 20)
        ),
        LockTemplatePreset(
            id: "neon-rim", name: "Viền sáng", badge: "Hiện đại", accent: .accentSky,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .monthGrid], bg: .obsidianNeon, cardStyle: .glowingBorder, cornerRadius: 18)
        ),
        LockTemplatePreset(
            id: "sunset-pill", name: "Hoàng hôn", badge: "Bo 24pt", accent: .accentPeach,
            config: LockLayoutConfig(blocks: [.todaySchedule, .weather, .partner, .vocab], bg: .sunsetDusk, cardStyle: .solidSoft, cornerRadius: 24)
        ),
        LockTemplatePreset(
            id: "forest-locka", name: "Rừng xanh", badge: "Lịch tháng", accent: .accentSage,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .vocab, .monthGrid], bg: .forestTeal, cardStyle: .frostedGlass, cornerRadius: 18)
        ),
        LockTemplatePreset(
            id: "amethyst-night", name: "Tím đêm", badge: "Bo 22pt", accent: Color(RGBA(hex: "#B983FF")!),
            config: LockLayoutConfig(blocks: [.monthGrid, .todaySchedule, .partner], bg: .amethystNight, cardStyle: .solidSoft, cornerRadius: 22)
        ),
        LockTemplatePreset(
            id: "clean-light", name: "Sáng sạch", badge: "Light Mode", accent: .accentSky,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .weather, .vocab], bg: .cleanLight, cardStyle: .solidSoft, cornerRadius: 20)
        ),
        LockTemplatePreset(
            id: "crystal-outline", name: "Viền mảnh", badge: "Trong suốt", accent: .white,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .weather, .vocab], bg: .crystalSlate, cardStyle: .hairlineOutline, cornerRadius: 22)
        ),
        LockTemplatePreset(
            id: "modern-couple", name: "Kết nối", badge: "Cặp đôi", accent: .accentPeach,
            config: LockLayoutConfig(blocks: [.partner, .todaySchedule, .weather, .weekStrip], bg: .roseCharcoal, cardStyle: .glowingBorder, cornerRadius: 24)
        ),
        LockTemplatePreset(
            id: "pro-dashed", name: "Nét đứt", badge: "Năng suất", accent: .accentHoney,
            config: LockLayoutConfig(blocks: [.weekStrip, .todaySchedule, .monthGrid, .vocab], bg: .deepIndigo, cardStyle: .dashedOutline, cornerRadius: 16)
        ),
    ]
}

// MARK: - Locka-Style Studio View

struct LockWallpaperStudio: View {
    static let templateShortcutShareURL = "https://www.icloud.com/shortcuts/71703e2781b04ca2951065fd03bc56d4"
    static let shortcutName = "Update Lock Screen"

    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var config = LockLayoutConfig.load()
    @State private var selectedPresetID: String?
    @State private var editorTab: EditorTab = .templates
    @State private var dragDeltaY: CGFloat = 0
    @State private var photoItem: PhotosPickerItem?
    @State private var bgImage: UIImage? = LockLayoutConfig.loadCustomPhoto()
    @State private var exportedImage: UIImage?
    @State private var showExportSheet = false
    @State private var showShortcutGuide = false
    @State private var showAddBlock = false
    @State private var savedToast = false

    enum EditorTab: String, CaseIterable, Identifiable {
        case templates, background, style, layout
        var id: String { rawValue }
        var title: String {
            switch self {
            case .templates: return "10 Mẫu"
            case .background: return "Nền"
            case .style: return "Viền & Bo"
            case .layout: return "Bố cục"
            }
        }
        var symbol: String {
            switch self {
            case .templates: return "sparkles.rectangle.stack"
            case .background: return "photo"
            case .style: return "paintbrush"
            case .layout: return "square.grid.2x2"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(RGBA(hex: "#0D0D0F")!).ignoresSafeArea()
            VStack(spacing: 12) {
                topBar
                lockPreviewCanvas
                editorTabBar
                editorControls
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
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
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tự động cập nhật Shortcut")

            Button {
                exportWallpaper()
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
        .padding(.top, 6)
    }

    // MARK: Live Lock Screen Canvas

    private var lockPreviewCanvas: some View {
        GeometryReader { geo in
            let maxH = max(geo.size.height, 200)
            let w = max(min(geo.size.width * 0.60, maxH * (9.0 / 19.5)), 150)
            let h = w * (19.5 / 9.0)
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
                partner: model.couple?.partner(of: DemoData.meID),
                showMockClock: true
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragDeltaY = value.translation.height * (393.0 / max(w, 1))
                    }
                    .onEnded { _ in
                        config.verticalOffset = min(max(config.verticalOffset + dragDeltaY, -60), 120)
                        dragDeltaY = 0
                        Haptics.tap()
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.18), value: config)
        }
        .frame(minHeight: 330)
    }

    private var liveDraggedConfig: LockLayoutConfig {
        var c = config
        c.verticalOffset = min(max(config.verticalOffset + dragDeltaY, -60), 120)
        return c
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
                        Image(systemName: tab.symbol).font(.system(size: 12, weight: .semibold))
                        Text(tab.title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
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
                case .background:
                    backgroundControls
                case .style:
                    styleControls
                case .layout:
                    layoutControls
                }
            }
        }
        .frame(height: 196)
    }

    private var templatesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(LockTemplatePreset.all) { preset in
                let selected = selectedPresetID == preset.id
                Button {
                    Haptics.tap()
                    selectedPresetID = preset.id
                    // Giữ nguyên các khối & vị trí dọc nếu user đã tự sắp xếp ở tab Bố cục!
                    let keepBlocks = config.userEditedBlocks
                    let savedBlocks = config.blocks
                    let savedOffset = config.verticalOffset
                    var next = preset.config
                    next.verticalOffset = savedOffset
                    if keepBlocks {
                        next.blocks = savedBlocks
                        next.userEditedBlocks = true
                    }
                    config = next
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: preset.config.bg.previewColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(preset.accent.opacity(0.75), lineWidth: 1.5)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(preset.badge)
                                .font(.system(size: 11, weight: .medium))
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

    private var backgroundControls: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(LockWallpaperBg.allCases.filter { $0 != .photo }) { bg in
                    let selected = config.bg == bg
                    Button {
                        Haptics.tap()
                        config.bg = bg
                    } label: {
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: bg.previewColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(selected ? Color.accentSky : Color.white.opacity(0.18), lineWidth: selected ? 2 : 1)
                                )
                            Text(bg.title)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Chọn ảnh nền từ Thư viện", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
            }
        }
    }

    private var styleControls: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(LockCardStyle.allCases) { st in
                    let selected = config.cardStyle == st
                    Button {
                        Haptics.tap()
                        config.cardStyle = st
                    } label: {
                        Text(st.title)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Color.accentSky : Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Độ bo góc").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(config.cornerRadius)) pt").font(.caption.monospaced()).foregroundStyle(.white.opacity(0.7))
                }
                Slider(value: $config.cornerRadius, in: 8...28, step: 2).tint(Color.accentSky)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Vị trí dọc").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(config.verticalOffset)) pt").font(.caption.monospaced()).foregroundStyle(.white.opacity(0.7))
                }
                Slider(value: $config.verticalOffset, in: -60...120, step: 5).tint(Color.accentSky)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
        }
    }

    private var layoutControls: some View {
        VStack(spacing: 8) {
            ForEach(Array(config.blocks.enumerated()), id: \.element.id) { idx, block in
                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        withAnimation {
                            config.blocks.remove(at: idx)
                            config.userEditedBlocks = true
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.accentPeach)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: block.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(block.accent)
                        .frame(width: 24)
                    Text(block.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()

                    if idx > 0 {
                        Button {
                            withAnimation {
                                config.blocks.swapAt(idx, idx - 1)
                                config.userEditedBlocks = true
                            }
                        } label: {
                            Image(systemName: "chevron.up").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                                .frame(width: 28, height: 28).background(Circle().fill(Color.white.opacity(0.08)))
                        }.buttonStyle(.plain)
                    }
                    if idx < config.blocks.count - 1 {
                        Button {
                            withAnimation {
                                config.blocks.swapAt(idx, idx + 1)
                                config.userEditedBlocks = true
                            }
                        } label: {
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                                .frame(width: 28, height: 28).background(Circle().fill(Color.white.opacity(0.08)))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
            }

            let available = LockBlockKind.allCases.filter { !config.blocks.contains($0) }
            if !available.isEmpty {
                Button {
                    Haptics.tap()
                    showAddBlock = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm thành phần")
                    }
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Color.accentSky)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentSky.opacity(0.14)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Sheets

    private var addBlockSheet: some View {
        NavigationStack {
            List {
                ForEach(LockBlockKind.allCases.filter { !config.blocks.contains($0) }) { block in
                    Button {
                        config.blocks.append(block)
                        config.userEditedBlocks = true
                        showAddBlock = false
                    } label: {
                        Label(block.title, systemImage: block.symbol)
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationTitle("Thêm thành phần")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { showAddBlock = false } }
            }
        }
        .presentationDetents([.medium])
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
                            runLockScreenShortcut()
                        } label: {
                            Label("Áp dụng ngay bằng Shortcut ⚡", systemImage: "bolt.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: true))

                        if let shareURL = URL(string: Self.templateShortcutShareURL), !Self.templateShortcutShareURL.isEmpty {
                            Button {
                                openURL(shareURL)
                            } label: {
                                Label("Cài Shortcut tự động (1 chạm)", systemImage: "plus.app.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                        }

                        if let ui = exportedImage {
                            HStack(spacing: 10) {
                                Button {
                                    UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
                                    Haptics.success()
                                    savedToast = true
                                } label: {
                                    Label(savedToast ? "Đã lưu ✓" : "Lưu vào Ảnh", systemImage: "arrow.down.to.line")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(CozyPillButtonStyle(tint: .inkTaupe, filled: false))

                                ShareLink(item: Image(uiImage: ui), preview: SharePreview("Lock Screen", image: Image(uiImage: ui))) {
                                    Label("Chia sẻ", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(CozyPillButtonStyle(tint: .inkTaupe, filled: false))
                            }
                        }
                    }

                    Text("Lưu ý: Nếu máy đang bật chế độ Tập trung (Focus) của Locka ở dưới màn hình khóa, hãy tắt Focus Locka hoặc chọn đúng Wallpaper đang hiển thị trong Shortcut.")
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
                Section {
                    if let shareURL = URL(string: Self.templateShortcutShareURL), !Self.templateShortcutShareURL.isEmpty {
                        Button {
                            openURL(shareURL)
                        } label: {
                            Label("Cài Shortcut tự động (1 chạm)", systemImage: "plus.app.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.accentSky)
                        }
                    }
                    Button {
                        runLockScreenShortcut()
                    } label: {
                        Label("Chạy Update Lock Screen ngay ⚡", systemImage: "bolt.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                Section("Để áp dụng đúng ra Lock Screen") {
                    Text("1. Tắt chế độ Tập trung (Focus) của Locka ở dưới màn hình khóa (nếu đang bật).")
                    Text("2. Trong Shortcut “Update Lock Screen”, chọn đúng số Wallpaper mà màn hình khóa hiện tại của bạn đang dùng.")
                }
            }
            .navigationTitle("Tự động cập nhật")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { showShortcutGuide = false }.bold() }
            }
        }
        .presentationDetents([.medium])
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
            partner: model.couple?.partner(of: DemoData.meID),
            showMockClock: false
        )
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(renderSize)
        renderer.scale = 3
        exportedImage = renderer.uiImage
        savedToast = false
        showExportSheet = true
    }
}

// MARK: - Full-Screen Lock Screen Renderer (Không dùng GeometryReader / LazyVGrid để ImageRenderer luôn render chuẩn 100%)

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
    var partner: MemberStatus?
    var showMockClock: Bool

    private var primaryText: Color { config.bg.isLight ? Color(RGBA(hex: "#141418")!) : .white }
    private var secondaryText: Color { config.bg.isLight ? Color(RGBA(hex: "#63636A")!) : .white.opacity(0.68) }

    var body: some View {
        let w = canvasSize.width
        let h = canvasSize.height
        let scale = w / 393.0

        ZStack(alignment: .top) {
            backgroundLayer(size: canvasSize)

            VStack(spacing: 0) {
                if showMockClock {
                    VStack(spacing: 2 * scale) {
                        Text(dateTitle)
                            .font(.system(size: 16 * scale, weight: .semibold))
                            .foregroundStyle(primaryText.opacity(0.88))
                        Text(now, style: .time)
                            .font(.system(size: 76 * scale, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryText.opacity(0.92))
                            .monospacedDigit()
                    }
                    .padding(.top, h * 0.08)
                    .frame(height: h * 0.28, alignment: .top)
                } else {
                    Color.clear.frame(height: h * 0.28)
                }

                VStack(alignment: .leading, spacing: 12 * scale) {
                    ForEach(config.blocks) { block in
                        blockView(block, scale: scale)
                    }
                }
                .padding(.horizontal, 20 * scale)
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
                    .padding(.bottom, 26 * scale)
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
    private func blockView(_ block: LockBlockKind, scale: CGFloat) -> some View {
        let radius = config.cornerRadius * scale
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let pad = config.cardStyle == .none ? 0 : 12 * scale

        Group {
            switch block {
            case .weekStrip: weekStripBlock(scale: scale)
            case .todaySchedule: todayScheduleBlock(scale: scale)
            case .weather: weatherBlock(scale: scale)
            case .vocab: vocabBlock(scale: scale)
            case .partner: partnerBlock(scale: scale)
            case .monthGrid: monthGridBlock(scale: scale)
            }
        }
        .padding(pad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            switch config.cardStyle {
            case .none:
                EmptyView()
            case .frostedGlass:
                shape.fill(config.bg.isLight ? Color.white.opacity(0.75) : Color.black.opacity(0.36))
                    .overlay(shape.strokeBorder(primaryText.opacity(0.14), lineWidth: 1))
            case .solidSoft:
                shape.fill(config.bg.isLight ? Color.white : Color.white.opacity(0.10))
                    .overlay(shape.strokeBorder(primaryText.opacity(0.08), lineWidth: 1))
            case .glowingBorder:
                shape.fill(Color.black.opacity(0.32))
                    .overlay(shape.strokeBorder(block.accent.opacity(0.7), lineWidth: 1.4))
            case .hairlineOutline:
                shape.strokeBorder(primaryText.opacity(0.28), lineWidth: 1.2)
            case .dashedOutline:
                shape.fill(Color.white.opacity(0.04))
                    .overlay(shape.strokeBorder(primaryText.opacity(0.32), style: StrokeStyle(lineWidth: 1.2, dash: [5 * scale, 4 * scale])))
            }
        }
    }

    // 1. Lịch tuần 7 ngày
    private func weekStripBlock(scale: CGFloat) -> some View {
        let cal = Calendar.cozy
        let weekday = cal.component(.weekday, from: now)
        let offsetToMon = (weekday == 1) ? -6 : (2 - weekday)
        let monday = cal.date(byAdding: .day, value: offsetToMon, to: cal.startOfDay(for: now))!
        let labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

        return HStack(spacing: 4 * scale) {
            ForEach(0..<7, id: \.self) { i in
                let d = cal.date(byAdding: .day, value: i, to: monday)!
                let isToday = cal.isDate(d, inSameDayAs: now)
                let dayNum = cal.component(.day, from: d)
                VStack(spacing: 3 * scale) {
                    Text(labels[i])
                        .font(.system(size: 11 * scale, weight: .semibold))
                        .foregroundStyle(isToday ? (config.bg.isLight ? .white : .black) : secondaryText)
                    Text("\(dayNum)")
                        .font(.system(size: 16 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(isToday ? (config.bg.isLight ? .white : .black) : primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        .fill(isToday ? (config.bg.isLight ? Color.accentSky : Color.white.opacity(0.90)) : .clear)
                )
            }
        }
    }

    // 2. Lịch trình hôm nay
    private func todayScheduleBlock(scale: CGFloat) -> some View {
        let pending = schedule.filter { !$0.isDone }
        return VStack(alignment: .leading, spacing: 6 * scale) {
            Text("Hôm nay")
                .font(.system(size: 16 * scale, weight: .bold))
                .foregroundStyle(Color.accentHoney)
            if pending.isEmpty {
                Text("Không có sự kiện hôm nay · \(lunar.shortText) ÂL")
                    .font(.system(size: 13.5 * scale, weight: .medium))
                    .foregroundStyle(secondaryText)
            } else {
                ForEach(pending.prefix(4)) { item in
                    HStack(spacing: 8 * scale) {
                        RoundedRectangle(cornerRadius: 2 * scale)
                            .fill(item.accent.color)
                            .frame(width: 3 * scale, height: 15 * scale)
                        if let t = item.timeText {
                            Text(t)
                                .font(.system(size: 12.5 * scale, weight: .bold, design: .monospaced))
                                .foregroundStyle(secondaryText)
                        }
                        Text(item.title)
                            .font(.system(size: 14 * scale, weight: .semibold))
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    // 3. Thời tiết thật
    private func weatherBlock(scale: CGFloat) -> some View {
        HStack(spacing: 10 * scale) {
            if let w = weather {
                Image(systemName: w.condition.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 24 * scale))
                VStack(alignment: .leading, spacing: 2 * scale) {
                    Text("\(w.temperatureText) \(w.placeName) · \(w.condition.displayName)")
                        .font(.system(size: 15 * scale, weight: .bold))
                        .foregroundStyle(primaryText)
                    Text("↑\(Int(w.highC.rounded()))° ↓\(Int(w.lowC.rounded()))° · Cảm giác \(Int(w.apparentC.rounded()))° · Ẩm \(Int((w.humidity * 100).rounded()))%")
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(secondaryText)
                }
            } else {
                Text("Thời tiết: Đang tải dữ liệu thật…")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    // 4. Từ vựng hôm nay
    private func vocabBlock(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * scale) {
            if let w = word {
                HStack(alignment: .firstTextBaseline, spacing: 8 * scale) {
                    Text(w.word)
                        .font(.system(size: 18 * scale, weight: .bold))
                        .foregroundStyle(primaryText)
                    if !w.phonetic.isEmpty {
                        Text(w.phonetic)
                            .font(.system(size: 12 * scale, design: .monospaced))
                            .foregroundStyle(secondaryText)
                    }
                    Spacer()
                    Text("🔥 \(streak)")
                        .font(.system(size: 12 * scale, weight: .bold))
                        .foregroundStyle(Color.accentHoney)
                }
                Text(w.meaning)
                    .font(.system(size: 13.5 * scale, weight: .medium))
                    .foregroundStyle(primaryText.opacity(0.85))
                    .lineLimit(2)
            }
        }
    }

    // 5. Cảm xúc người kết nối
    private func partnerBlock(scale: CGFloat) -> some View {
        HStack(spacing: 10 * scale) {
            if let p = partner {
                Text(p.mood?.emoji ?? "❤️")
                    .font(.system(size: 22 * scale))
                VStack(alignment: .leading, spacing: 2 * scale) {
                    HStack(spacing: 6 * scale) {
                        Text(p.displayName)
                            .font(.system(size: 15 * scale, weight: .bold))
                            .foregroundStyle(primaryText)
                        if let m = p.mood {
                            Text("· \(m.displayName)")
                                .font(.system(size: 13 * scale, weight: .semibold))
                                .foregroundStyle(Color.accentPeach)
                        }
                    }
                    if !p.note.isEmpty {
                        Text(p.note)
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(primaryText.opacity(0.82))
                            .lineLimit(1)
                    }
                }
            } else {
                Text("Chưa kết nối người thương")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    // 6. Lịch tháng (Dùng VStack + HStack tĩnh thay vì LazyVGrid để ImageRenderer không bao giờ bị lỗi trống!)
    private func monthGridBlock(scale: CGFloat) -> some View {
        let cal = Calendar.cozy
        let comps = cal.dateComponents([.year, .month], from: now)
        let first = cal.date(from: comps)!
        let totalDays = cal.range(of: .day, in: .month, for: first)!.count
        let firstWD = cal.component(.weekday, from: first)
        let pad = (firstWD == 1) ? 6 : (firstWD - 2)
        let todayDay = cal.component(.day, from: now)
        let totalCells = pad + totalDays
        let rowCount = (totalCells + 6) / 7
        let labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

        return VStack(spacing: 4 * scale) {
            HStack(spacing: 2 * scale) {
                ForEach(labels, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 10 * scale, weight: .bold))
                        .foregroundStyle(secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<rowCount, id: \.self) { r in
                HStack(spacing: 2 * scale) {
                    ForEach(0..<7, id: \.self) { c in
                        let idx = r * 7 + c
                        if idx < pad || idx >= totalCells {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 18 * scale)
                        } else {
                            let day = idx - pad + 1
                            let isToday = day == todayDay
                            Text("\(day)")
                                .font(.system(size: 11 * scale, weight: isToday ? .heavy : .medium, design: .rounded))
                                .foregroundStyle(isToday ? (config.bg.isLight ? .white : .black) : primaryText.opacity(0.88))
                                .frame(maxWidth: .infinity, minHeight: 18 * scale)
                                .background(RoundedRectangle(cornerRadius: 5 * scale).fill(isToday ? (config.bg.isLight ? Color.accentSky : Color.white) : .clear))
                        }
                    }
                }
            }
        }
    }

    private var dateTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, d 'tháng' M"
        return f.string(from: now).capitalized
    }
}

/// AppIntent cho Apple Shortcuts: tự render ảnh nền Lock Screen mới nhất.
struct GenerateLockWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Update Lock Screen"
    static let description = IntentDescription("Tự vẽ ảnh nền Màn hình khóa gồm Lịch tuần, Lịch trình hôm nay, Thời tiết thật và Từ vựng.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let repo = CozyShared.repository
        let now = Date()
        let snap = repo.snapshot(reload: true)
        let renderSize = CGSize(width: 393, height: 852)
        let view = LockWallpaperRenderView(
            canvasSize: renderSize,
            config: LockLayoutConfig.load(),
            bgImage: LockLayoutConfig.loadCustomPhoto(),
            now: now,
            lunar: VietnameseLunarCalendar.lunarDate(from: now, calendar: repo.calendar),
            schedule: repo.todaySchedule(now: now),
            weather: snap.weather,
            word: repo.currentWord(now: now),
            streak: repo.vocabStreak(now: now),
            partner: snap.spaces.preferred(.couple)?.partner(of: DemoData.meID),
            showMockClock: false
        )

        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(renderSize)
        renderer.scale = 3
        let data = renderer.uiImage?.pngData() ?? Data()
        return .result(value: IntentFile(data: data, filename: "lockscreen.png", type: .png))
    }
}
