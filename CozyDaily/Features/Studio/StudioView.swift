import SwiftUI
import WidgetKit
import CozyCore

/// Tab 4 — Xưởng Widget (Pro Widget Studio).
struct StudioView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedID: UUID?
    @State private var draft: WidgetConfig?
    @State private var surface: Surface = .home
    @State private var family: WidgetFamily = .systemMedium
    @State private var step: Step = .content

    enum Surface: String, CaseIterable, Identifiable {
        case home, lock
        var id: String { rawValue }
        var title: String { self == .home ? "Màn hình chính" : "Màn hình khóa" }
    }

    enum Step: Int, CaseIterable, Identifiable {
        case content, theme, palette, typography
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .content: return "Nội dung"
            case .theme: return "Theme & Linh vật"
            case .palette: return "Màu & Trong suốt"
            case .typography: return "Font & Viền"
            }
        }
        var symbol: String {
            switch self {
            case .content: return "square.grid.2x2"
            case .theme: return "pawprint"
            case .palette: return "paintpalette"
            case .typography: return "textformat"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    configStrip
                    if let binding = draftBinding {
                        LivePreview(config: binding.wrappedValue, surface: surface, family: family)
                        surfacePicker
                        stepBar
                        StepEditor(step: step, config: binding)
                            .cozyCard()
                        HStack {
                            Button { save() } label: { Label("Lưu mẫu", systemImage: "checkmark.circle.fill") }
                                .buttonStyle(CozyPillButtonStyle(tint: .inkCoffee))
                            Spacer()
                            if step != .typography {
                                Button { withAnimation { step = Step(rawValue: step.rawValue + 1)! } } label: { Label("Bước tiếp", systemImage: "arrow.right") }
                                    .buttonStyle(CozyPillButtonStyle(tint: .inkCoffee, filled: false))
                            }
                        }
                        Text("Sau khi lưu: chạm giữ màn hình chính → “+” → CozyDaily → “Xưởng Widget”, rồi chọn mẫu “\(binding.wrappedValue.name)”.")
                            .font(.caption).foregroundStyle(Color.inkTaupe)
                    }
                }
                .padding(16)
            }
            .background(Color.bgCream.ignoresSafeArea())
            .navigationTitle("Xưởng Widget")
            .onAppear { if draft == nil { select(model.snapshot.widgetConfigs.first) } }
        }
    }

    private var draftBinding: Binding<WidgetConfig>? {
        guard draft != nil else { return nil }
        return Binding(get: { draft! }, set: { draft = $0 })
    }

    private func select(_ cfg: WidgetConfig?) {
        selectedID = cfg?.id
        draft = cfg
        step = .content
    }

    private func save() {
        guard let draft else { return }
        model.save(draft)
        Haptics.success()
    }

    // MARK: Pieces

    private var configStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.snapshot.widgetConfigs) { cfg in
                    Button { select(cfg) } label: {
                        Label(cfg.name, systemImage: cfg.content.symbolName)
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: cfg.accent.color, filled: selectedID == cfg.id))
                    .contextMenu {
                        Button(role: .destructive) {
                            model.deleteConfig(cfg.id)
                            select(model.snapshot.widgetConfigs.first)
                        } label: { Label("Xóa mẫu", systemImage: "trash") }
                    }
                }
                Button {
                    let n = WidgetConfig(name: "Mẫu mới \(model.snapshot.widgetConfigs.count + 1)", content: .moodFood, species: model.settings.species)
                    model.save(n)
                    select(n)
                } label: { Label("Mẫu mới", systemImage: "plus") }
                .buttonStyle(CozyPillButtonStyle(tint: .inkTaupe, filled: false))
            }
        }
    }

    private var surfacePicker: some View {
        VStack(spacing: 8) {
            Picker("Bề mặt", selection: $surface) {
                ForEach(Surface.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: surface) { _, s in family = s == .home ? .systemMedium : .accessoryRectangular }

            Picker("Kích thước", selection: $family) {
                if surface == .home {
                    Text("Nhỏ 2×2").tag(WidgetFamily.systemSmall)
                    Text("Vừa 4×2").tag(WidgetFamily.systemMedium)
                    Text("Lớn 4×4").tag(WidgetFamily.systemLarge)
                } else {
                    Text("Chữ nhật").tag(WidgetFamily.accessoryRectangular)
                    Text("Tròn").tag(WidgetFamily.accessoryCircular)
                    Text("1 dòng").tag(WidgetFamily.accessoryInline)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var stepBar: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases) { s in
                Button { withAnimation { step = s } } label: {
                    VStack(spacing: 4) {
                        Image(systemName: s.symbol).font(.system(size: 15, weight: .semibold))
                        Text("\(s.rawValue + 1). \(s.title)").font(.system(size: 10, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(step == s ? Color.white : Color.inkCoffee)
                    .background(RoundedRectangle(cornerRadius: 14).fill(step == s ? Color.inkCoffee : Color.cardIvory))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Live Preview

private struct LivePreview: View {
    @Environment(AppModel.self) private var model
    var config: WidgetConfig
    var surface: StudioView.Surface
    var family: WidgetFamily

    var size: CGSize {
        switch family {
        case .systemSmall: return CGSize(width: 158, height: 158)
        case .systemMedium: return CGSize(width: 338, height: 158)
        case .systemLarge: return CGSize(width: 338, height: 354)
        case .accessoryRectangular: return CGSize(width: 160, height: 72)
        case .accessoryCircular: return CGSize(width: 72, height: 72)
        default: return CGSize(width: 260, height: 22)
        }
    }

    var body: some View {
        let data = model.widgetData(for: config)
        ZStack {
            // Hình nền giả lập
            LinearGradient(colors: surface == .lock ? [Color(RGBA(hex: "#3B4A63")!), Color(RGBA(hex: "#8C6E7E")!)] : [Color.accentSky.opacity(0.7), Color.accentPeach.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 10) {
                if surface == .lock {
                    if family == .accessoryInline {
                        CozyWidgetView(data: data, family: family)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: size.width, height: size.height)
                    } else {
                        Text(Date().formatted(.dateTime.weekday(.wide).day().month().locale(Locale(identifier: "vi_VN"))))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Text(Date(), style: .time)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                    if family != .accessoryInline {
                        CozyWidgetView(data: data, family: family)
                            .foregroundStyle(.white)
                            .padding(6)
                            .frame(width: size.width, height: size.height)
                            .background(RoundedRectangle(cornerRadius: family == .accessoryCircular ? 36 : 14).fill(.ultraThinMaterial))
                            .environment(\.colorScheme, .dark)
                    }
                } else {
                    CozyWidgetView(data: data, family: family)
                        .padding(16)
                        .frame(width: size.width, height: size.height)
                        .background(
                            ZStack {
                                data.theme.background.opacity(config.backgroundOpacity)
                                data.theme.wash(accent: config.accent.color)
                            }
                            .background(.ultraThinMaterial)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                }
            }
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: surface == .lock ? 280 : max(220, size.height + 60))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: config)
        .accessibilityLabel("Xem trước widget \(config.name)")
    }
}

// MARK: - Step editors

private struct StepEditor: View {
    var step: StudioView.Step
    @Binding var config: WidgetConfig
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch step {
            case .content: contentStep
            case .theme: themeStep
            case .palette: paletteStep
            case .typography: typographyStep
            }
        }
    }

    // Lớp 1
    @ViewBuilder private var contentStep: some View {
        TextField("Tên mẫu", text: $config.name)
            .font(CozyFont.title(17))
        Text("Nội dung chính").font(CozyFont.body(13, weight: .semibold)).foregroundStyle(Color.inkTaupe)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(WidgetContentKind.allCases) { k in
                Button {
                    config.content = k
                    config.accent = k.defaultAccent
                    config.font = WidgetFontStyle.recommended(for: k)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: k.symbolName).font(.system(size: 18))
                        Text(k.displayName).font(.system(size: 11, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .foregroundStyle(config.content == k ? .white : Color.inkCoffee)
                    .background(RoundedRectangle(cornerRadius: 14).fill(config.content == k ? k.defaultAccent.color : Color.bgCream))
                }
                .buttonStyle(.plain)
            }
        }
        if config.content == .event {
            Picker("Sự kiện", selection: $config.eventID) {
                Text("Gần nhất (tự động)").tag(UUID?.none)
                ForEach(model.snapshot.events) { e in Text("\(e.emoji) \(e.title)").tag(UUID?.some(e.id)) }
            }
        }
        if config.content == .vocab || config.content == .combo {
            Toggle("Ẩn nghĩa trên Lock Screen (luyện phản xạ)", isOn: $config.hideMeaningOnLockScreen)
        }
    }

    // Lớp 2
    @ViewBuilder private var themeStep: some View {
        Text("Theme").font(CozyFont.body(13, weight: .semibold)).foregroundStyle(Color.inkTaupe)
        HStack(spacing: 8) {
            ForEach(WidgetTheme.allCases) { t in
                Button { config.theme = t } label: {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 10).fill(t.background)
                            .overlay(RoundedRectangle(cornerRadius: 10).fill(t.wash(accent: config.accent.color)))
                            .frame(height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(config.theme == t ? Color.inkCoffee : Color.cardBorder, lineWidth: config.theme == t ? 2 : 1))
                        Text(t.displayName).font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        Toggle("Hiện linh vật", isOn: $config.showMascot)
        Text("Linh vật").font(CozyFont.body(13, weight: .semibold)).foregroundStyle(Color.inkTaupe)
        HStack {
            ForEach(MascotSpecies.allCases) { s in
                Button { config.species = s } label: {
                    VStack {
                        Text(s.emoji).font(.system(size: 32))
                        Text(s.displayName).font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(RoundedRectangle(cornerRadius: 14).fill(config.species == s ? Color.accentPeach.opacity(0.3) : Color.bgCream))
                }
                .buttonStyle(.plain)
            }
        }
        Picker("Smart Auto-Theme", selection: $config.autoTheme) {
            ForEach(AutoThemeMode.allCases, id: \.self) { Text($0.displayName).tag($0) }
        }
    }

    // Lớp 3
    @ViewBuilder private var paletteStep: some View {
        Text("Màu nhấn").font(CozyFont.body(13, weight: .semibold)).foregroundStyle(Color.inkTaupe)
        HStack(spacing: 12) {
            ForEach(ColorToken.accents, id: \.self) { t in
                Button { config.accent = t } label: {
                    Circle().fill(t.color)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(Color.inkCoffee, lineWidth: config.accent == t ? 3 : 0))
                }
                .accessibilityLabel(t.displayName)
            }
        }
        VStack(alignment: .leading) {
            Text("Độ đục nền: \(Int(config.backgroundOpacity * 100))%").font(CozyFont.body(13, weight: .semibold))
            Slider(value: $config.backgroundOpacity, in: 0...1, step: 0.05).tint(config.accent.color)
            Text("Giảm độ đục để widget hòa vào hình nền.").font(.caption).foregroundStyle(Color.inkTaupe)
        }
    }

    // Lớp 4
    @ViewBuilder private var typographyStep: some View {
        Text("Font chữ").font(CozyFont.body(13, weight: .semibold)).foregroundStyle(Color.inkTaupe)
        ForEach(WidgetFontStyle.allCases) { f in
            Button { config.font = f } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.displayName).font(f.font(size: 18, weight: .bold))
                        Text(f.hint).font(.caption).foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    if config.font == f { Image(systemName: "checkmark.circle.fill").foregroundStyle(config.accent.color) }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(config.font == f ? config.accent.color.opacity(0.12) : Color.bgCream))
            }
            .buttonStyle(.plain)
        }
        Picker("Khung viền", selection: $config.border) {
            ForEach(WidgetBorderStyle.allCases) { Text($0.displayName).tag($0) }
        }
        .pickerStyle(.segmented)
    }
}
