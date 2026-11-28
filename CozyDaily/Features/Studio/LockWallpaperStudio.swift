import SwiftUI
import PhotosUI
import UIKit
import AppIntents
import UniformTypeIdentifiers
import CozyCore

// MARK: - Locka-Style Block Model

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
    case sunsetDusk
    case photo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pureDark: return "Đen tối giản"
        case .midnightBlue: return "Xanh đêm"
        case .sunsetDusk: return "Hoàng hôn"
        case .photo: return "Ảnh của bạn"
        }
    }
}

struct LockLayoutConfig: Equatable, Codable {
    var blocks: [LockBlockKind] = [.weekStrip, .todaySchedule, .weather, .vocab]
    var bg: LockWallpaperBg = .pureDark
    var showCardGlass: Bool = false
    var verticalOffset: CGFloat = 0

    private static let storageKey = "cozy.lockLayoutConfig.v1"

    static func load() -> LockLayoutConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let cfg = try? JSONDecoder().decode(LockLayoutConfig.self, from: data) else {
            return LockLayoutConfig()
        }
        return cfg
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - Locka-Style Studio View

struct LockWallpaperStudio: View {
    @Environment(AppModel.self) private var model
    @State private var config = LockLayoutConfig.load()
    @State private var editorTab: EditorTab = .layout
    @State private var photoItem: PhotosPickerItem?
    @State private var bgImage: UIImage?
    @State private var exportedImage: UIImage?
    @State private var showExportSheet = false
    @State private var showShortcutGuide = false
    @State private var showAddBlock = false
    @State private var savedToast = false

    enum EditorTab: String, CaseIterable, Identifiable {
        case background, style, layout
        var id: String { rawValue }
        var title: String {
            switch self {
            case .background: return "Ảnh nền"
            case .style: return "Kiểu thẻ"
            case .layout: return "Bố cục"
            }
        }
        var symbol: String {
            switch self {
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

    // MARK: Live Lock Screen Canvas (Tỷ lệ iPhone chuẩn)

    private var lockPreviewCanvas: some View {
        GeometryReader { geo in
            let maxH = geo.size.height
            let w = min(geo.size.width * 0.62, maxH * (9.0 / 19.5))
            let h = w * (19.5 / 9.0)
            LockWallpaperRenderView(
                config: config,
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
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minHeight: 340)
    }

    // MARK: Editor Tab Bar (giống thanh công cụ Locka)

    private var editorTabBar: some View {
        HStack(spacing: 6) {
            ForEach(EditorTab.allCases) { tab in
                let selected = editorTab == tab
                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.18)) { editorTab = tab }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.symbol).font(.system(size: 13, weight: .semibold))
                        Text(tab.title).font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selected ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(selected ? Color.white.opacity(0.16) : .clear))
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
                case .layout:
                    layoutControls
                case .background:
                    backgroundControls
                case .style:
                    styleControls
                }
            }
        }
        .frame(height: 190)
    }

    private var layoutControls: some View {
        VStack(spacing: 8) {
            ForEach(Array(config.blocks.enumerated()), id: \.element.id) { idx, block in
                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        withAnimation { config.blocks.remove(at: idx) }
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
                            withAnimation { config.blocks.swapAt(idx, idx - 1) }
                        } label: {
                            Image(systemName: "chevron.up").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                                .frame(width: 28, height: 28).background(Circle().fill(Color.white.opacity(0.08)))
                        }.buttonStyle(.plain)
                    }
                    if idx < config.blocks.count - 1 {
                        Button {
                            withAnimation { config.blocks.swapAt(idx, idx + 1) }
                        } label: {
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                                .frame(width: 28, height: 28).background(Circle().fill(Color.white.opacity(0.08)))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.accentSky)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentSky.opacity(0.14)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var backgroundControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach([LockWallpaperBg.pureDark, .midnightBlue, .sunsetDusk]) { bg in
                    let selected = config.bg == bg
                    Button {
                        Haptics.tap()
                        config.bg = bg
                    } label: {
                        Text(bg.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Color.accentSky : Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Chọn ảnh nền từ Thư viện", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
            }
        }
    }

    private var styleControls: some View {
        VStack(spacing: 12) {
            Toggle("Nền kính mờ cho từng thẻ", isOn: $config.showCardGlass)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .tint(Color.accentSky)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Vị trí dọc").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(config.verticalOffset)) pt").font(.caption.monospaced()).foregroundStyle(.white.opacity(0.7))
                }
                Slider(value: $config.verticalOffset, in: -40...80, step: 5).tint(Color.accentSky)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
        }
    }

    // MARK: Sheets

    private var addBlockSheet: some View {
        NavigationStack {
            List {
                ForEach(LockBlockKind.allCases.filter { !config.blocks.contains($0) }) { block in
                    Button {
                        config.blocks.append(block)
                        showAddBlock = false
                    } label: {
                        Label(block.title, systemImage: block.symbol)
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationTitle("Thêm vào Lock Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { showAddBlock = false } }
            }
        }
        .presentationDetents([.medium])
    }

    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let ui = exportedImage {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .frame(maxHeight: 420)

                    HStack(spacing: 10) {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
                            Haptics.success()
                            savedToast = true
                        } label: {
                            Label(savedToast ? "Đã lưu vào Ảnh ✓" : "Lưu vào Ảnh", systemImage: "arrow.down.to.line")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: true))

                        ShareLink(item: Image(uiImage: ui), preview: SharePreview("Lock Screen", image: Image(uiImage: ui))) {
                            Label("Chia sẻ", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: false))
                    }

                    Text("Đặt ảnh này làm Hình nền Màn hình khóa (hoặc dùng Phím tắt “Tạo ảnh nền Lock Screen” để tự cập nhật mỗi sáng).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
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
                Section("Tự động cập nhật (giống Locka)") {
                    Text("1. Mở app Phím tắt (Shortcuts) → Tự động hóa → +")
                    Text("2. Chọn Khi đóng app (Widgets / Lịch) hoặc 00:01 mỗi ngày → Chạy ngay lập tức")
                    Text("3. Thêm hành động: Update Lock Screen (của app Widgets)")
                    Text("4. Thêm hành động: Đặt hình nền → chọn Màn hình khóa → tắt Hiện bản xem trước")
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

    @MainActor
    private func exportWallpaper() {
        let renderSize = CGSize(width: 393, height: 852)
        let view = LockWallpaperRenderView(
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
        .frame(width: renderSize.width, height: renderSize.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        exportedImage = renderer.uiImage
        savedToast = false
        showExportSheet = true
    }
}

// MARK: - Full-Screen Lock Screen Renderer (Dùng cho cả Preview & Xuất ảnh @3x)

struct LockWallpaperRenderView: View {
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

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let scale = w / 393.0

            ZStack(alignment: .top) {
                backgroundLayer(size: geo.size)

                VStack(spacing: 0) {
                    // Vùng đồng hồ iOS Lock Screen (trống khi xuất ảnh thật để không đè đồng hồ iOS)
                    if showMockClock {
                        VStack(spacing: 2 * scale) {
                            Text(dateTitle)
                                .font(.system(size: 16 * scale, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text(now, style: .time)
                                .font(.system(size: 76 * scale, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                                .monospacedDigit()
                        }
                        .padding(.top, h * 0.08)
                        .frame(height: h * 0.28, alignment: .top)
                    } else {
                        Spacer().frame(height: h * 0.28)
                    }

                    // Các khối dữ liệu thật kiểu Locka
                    VStack(alignment: .leading, spacing: 14 * scale) {
                        ForEach(config.blocks) { block in
                            blockView(block, scale: scale)
                        }
                    }
                    .padding(.horizontal, 22 * scale)
                    .offset(y: config.verticalOffset * scale)

                    Spacer(minLength: 0)

                    if showMockClock {
                        HStack {
                            Image(systemName: "flashlight.off.fill")
                                .font(.system(size: 16 * scale))
                                .frame(width: 40 * scale, height: 40 * scale)
                                .background(Circle().fill(Color.white.opacity(0.14)))
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16 * scale))
                                .frame(width: 40 * scale, height: 40 * scale)
                                .background(Circle().fill(Color.white.opacity(0.14)))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 34 * scale)
                        .padding(.bottom, 26 * scale)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        switch config.bg {
        case .pureDark:
            Color(RGBA(hex: "#141416")!)
        case .midnightBlue:
            LinearGradient(colors: [Color(RGBA(hex: "#141E30")!), Color(RGBA(hex: "#243B55")!)], startPoint: .top, endPoint: .bottom)
        case .sunsetDusk:
            LinearGradient(colors: [Color(RGBA(hex: "#1F1C2C")!), Color(RGBA(hex: "#614357")!), Color(RGBA(hex: "#232526")!)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .photo:
            if let bgImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.28))
            } else {
                Color(RGBA(hex: "#141416")!)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: LockBlockKind, scale: CGFloat) -> some View {
        Group {
            switch block {
            case .weekStrip:
                weekStripBlock(scale: scale)
            case .todaySchedule:
                todayScheduleBlock(scale: scale)
            case .weather:
                weatherBlock(scale: scale)
            case .vocab:
                vocabBlock(scale: scale)
            case .partner:
                partnerBlock(scale: scale)
            case .monthGrid:
                monthGridBlock(scale: scale)
            }
        }
        .padding(config.showCardGlass ? 12 * scale : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if config.showCardGlass {
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .fill(Color.black.opacity(0.38))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
        }
    }

    // 1. Lịch tuần 7 ngày kiểu Locka (Mon 23 ... [Sat 28] ... Sun 29)
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
                        .foregroundStyle(isToday ? .black : .white.opacity(0.65))
                    Text("\(dayNum)")
                        .font(.system(size: 16 * scale, weight: .bold, design: .rounded))
                        .foregroundStyle(isToday ? .black : .white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7 * scale)
                .background(
                    RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        .fill(isToday ? Color.white.opacity(0.88) : .clear)
                )
            }
        }
    }

    // 2. Lịch trình hôm nay (kiểu Locka: tiêu đề cam "Hôm nay" + danh sách rõ ràng)
    private func todayScheduleBlock(scale: CGFloat) -> some View {
        let pending = schedule.filter { !$0.isDone }
        return VStack(alignment: .leading, spacing: 6 * scale) {
            Text("Hôm nay")
                .font(.system(size: 16 * scale, weight: .bold))
                .foregroundStyle(Color.accentHoney)
            if pending.isEmpty {
                Text("Không có sự kiện hôm nay · \(lunar.shortText) ÂL")
                    .font(.system(size: 13.5 * scale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                ForEach(pending.prefix(4)) { item in
                    HStack(spacing: 8 * scale) {
                        RoundedRectangle(cornerRadius: 2 * scale)
                            .fill(item.accent.color)
                            .frame(width: 3 * scale, height: 15 * scale)
                        if let t = item.timeText {
                            Text(t)
                                .font(.system(size: 12.5 * scale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        Text(item.title)
                            .font(.system(size: 14 * scale, weight: .semibold))
                            .foregroundStyle(.white)
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
                        .foregroundStyle(.white)
                    Text("↑\(Int(w.highC.rounded()))° ↓\(Int(w.lowC.rounded()))° · Cảm giác \(Int(w.apparentC.rounded()))° · Ẩm \(Int((w.humidity * 100).rounded()))%")
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text("Thời tiết: Đang tải dữ liệu thật…")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.white.opacity(0.7))
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
                        .foregroundStyle(.white)
                    if !w.phonetic.isEmpty {
                        Text(w.phonetic)
                            .font(.system(size: 12 * scale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    Text("🔥 \(streak)")
                        .font(.system(size: 12 * scale, weight: .bold))
                        .foregroundStyle(Color.accentHoney)
                }
                Text(w.meaning)
                    .font(.system(size: 13.5 * scale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
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
                            .foregroundStyle(.white)
                        if let m = p.mood {
                            Text("· \(m.displayName)")
                                .font(.system(size: 13 * scale, weight: .semibold))
                                .foregroundStyle(Color.accentPeach)
                        }
                    }
                    if !p.note.isEmpty {
                        Text(p.note)
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            } else {
                Text("Chưa kết nối người thương")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    // 6. Lịch tháng gọn kiểu Locka
    private func monthGridBlock(scale: CGFloat) -> some View {
        let cal = Calendar.cozy
        let comps = cal.dateComponents([.year, .month], from: now)
        let first = cal.date(from: comps)!
        let range = cal.range(of: .day, in: .month, for: first)!
        let firstWD = cal.component(.weekday, from: first)
        let pad = (firstWD == 1) ? 6 : (firstWD - 2)
        let todayDay = cal.component(.day, from: now)
        let labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

        return VStack(spacing: 4 * scale) {
            HStack {
                ForEach(labels, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 10 * scale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2 * scale), count: 7), spacing: 3 * scale) {
                ForEach(0..<(pad + range.count), id: \.self) { idx in
                    if idx < pad {
                        Color.clear.frame(height: 18 * scale)
                    } else {
                        let day = idx - pad + 1
                        let isToday = day == todayDay
                        Text("\(day)")
                            .font(.system(size: 11 * scale, weight: isToday ? .heavy : .medium, design: .rounded))
                            .foregroundStyle(isToday ? .black : .white.opacity(0.85))
                            .frame(maxWidth: .infinity, minHeight: 18 * scale)
                            .background(RoundedRectangle(cornerRadius: 5 * scale).fill(isToday ? Color.white : .clear))
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

/// AppIntent cho Apple Shortcuts: tự render ảnh nền Lock Screen mới nhất (dùng với hành động "Đặt hình nền" khi rời app hoặc 00:01).
struct GenerateLockWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Update Lock Screen"
    static let description = IntentDescription("Tự vẽ ảnh nền Màn hình khóa gồm Lịch tuần, Lịch trình hôm nay, Thời tiết thật và Từ vựng.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let repo = CozyShared.repository
        let now = Date()
        let snap = repo.snapshot(reload: true)
        let view = LockWallpaperRenderView(
            config: LockLayoutConfig.load(),
            bgImage: nil,
            now: now,
            lunar: VietnameseLunarCalendar.lunarDate(from: now, calendar: repo.calendar),
            schedule: repo.todaySchedule(now: now),
            weather: snap.weather,
            word: repo.currentWord(now: now),
            streak: repo.vocabStreak(now: now),
            partner: snap.spaces.preferred(.couple)?.partner(of: DemoData.meID),
            showMockClock: false
        )
        .frame(width: 393, height: 852)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let data = renderer.uiImage?.pngData() ?? Data()
        return .result(value: IntentFile(data: data, filename: "lockscreen.png", type: .png))
    }
}
